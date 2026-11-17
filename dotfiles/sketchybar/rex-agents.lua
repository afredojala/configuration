-- Shows how many programs in Rex need you, in the SketchyBar item "rex".
-- Programs such as Claude Code report their state with OSC 7501.
-- Run with: rex do --all rex-agents.lua sketchybar=/path/to/sketchybar
local sketchybar = assert(rex.args.sketchybar, "pass sketchybar=PATH")

local RED, GREEN, SKY = "0xffed8796", "0xffa6da95", "0xff91d7e3"
-- Most urgent first; a terminal counts once, under its most urgent record.
local RANK = { blocked = 1, error = 2, done = 3, working = 4 }
local LABEL = { blocked = "waiting", error = "failed", done = "done", working = "working" }
local ORDER = { "blocked", "error", "done", "working" }

local function terminals()
  local sessions = rex.call("session.list")
  local out = {}
  for _, s in ipairs((sessions and sessions.sessions) or {}) do
    local list = rex.call("session.list_blocks", { session_id = s.session_id })
    for _, b in ipairs((list and list.blocks) or {}) do
      if b.creator_name == "com.superlogical.terminal" then
        out[#out + 1] = { session_id = s.session_id, block_id = b.block_id }
      end
    end
  end
  return out
end

local last
local function refresh()
  local counts = {}
  for _, t in ipairs(terminals()) do
    local status = rex.block.call("com.superlogical.terminal", "program_status", t)
    local best
    for _, r in ipairs((status and status.records) or {}) do
      if RANK[r.state] and (not best or RANK[r.state] < RANK[best]) then best = r.state end
    end
    if best then counts[best] = (counts[best] or 0) + 1 end
  end

  local parts, top = {}, nil
  for _, state in ipairs(ORDER) do
    if counts[state] then
      top = top or state
      parts[#parts + 1] = counts[state] .. " " .. LABEL[state]
    end
  end
  local args
  if top then
    local color = (top == "blocked" or top == "error") and RED or top == "done" and GREEN or SKY
    args = { sketchybar, "--set", "rex", "drawing=on", "label=" .. table.concat(parts, " · "),
      "icon.color=" .. color }
  else
    args = { sketchybar, "--set", "rex", "drawing=off" }
  end
  -- Status events come often while an agent works; only redraw on a change.
  local key = table.concat(args, "\0")
  if key ~= last then
    rex.exec(args)
    last = key
  end
end

-- Status events arrive in bursts while an agent works, so coalesce them.
local pending
local function soon()
  if pending then pending:cancel() end
  pending = rex.after(0.3, refresh)
end

for _, event in ipairs({ "terminal.program_status_changed", "terminal.program_status_removed",
  "block_closed", "session_destroyed" }) do
  rex.on(event, soon)
end
-- Catches anything the events miss, and redraws after SketchyBar reloads.
rex.every(15, function()
  last = nil
  refresh()
end)
refresh()
