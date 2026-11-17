"""Shows how many agents in Herdr need you, in the SketchyBar item "herdr".

Follows `hc events` and recounts after each change. Herdr marks a finished
turn as seen by setting the label herdr.seen to the turn number, so "done"
counts only turns nobody has looked at yet.
Run with: python3 herdr-agents.py /path/to/hc /path/to/sketchybar
"""

import json
import queue
import subprocess
import sys
import threading

hc, sketchybar = sys.argv[1], sys.argv[2]

RED, GREEN, SKY = "0xffee7189", "0xff55dfa2", "0xff47d3d6"
# Most urgent first.
ORDER = ["blocked", "done", "working"]
LABEL = {"blocked": "waiting", "done": "done", "working": "working"}
# Size, output and heartbeat lines arrive constantly and never change a status.
NOISE = {"size", "output", "title"}


def hc_json(*args):
    return json.loads(subprocess.run([hc, *args, "--json"], capture_output=True,
                                     text=True, check=True).stdout)


def counts():
    out = {}
    for t in hc_json("ls")["terminals"]:
        state = t.get("status")
        if state == "done":
            # A helper's finished turn goes to its parent agent, not to you.
            if t.get("parent"):
                continue
            labels = hc_json("get", t["address"]).get("labels") or {}
            if labels.get("herdr.seen") == str(t.get("turn")):
                continue
        if state in LABEL:
            out[state] = out.get(state, 0) + 1
    return out


last = None


def refresh():
    global last
    c = counts()
    parts = [f"{c[s]} {LABEL[s]}" for s in ORDER if s in c]
    top = next((s for s in ORDER if s in c), None)
    if top:
        color = RED if top == "blocked" else GREEN if top == "done" else SKY
        args = [sketchybar, "--set", "herdr", "drawing=on",
                "label=" + " · ".join(parts), "icon.color=" + color]
    else:
        args = [sketchybar, "--set", "herdr", "drawing=off"]
    # Only redraw on a change.
    if args != last:
        subprocess.run(args, check=False)
        last = args


events = subprocess.Popen([hc, "events", "--json"], stdout=subprocess.PIPE, text=True)
lines = queue.Queue()


def read():
    for line in events.stdout:
        lines.put(line)
    lines.put(None)


threading.Thread(target=read, daemon=True).start()
refresh()
pending = False
while True:
    # Events come in bursts while an agent works, so coalesce them; the
    # timeout also catches anything missed and redraws after SketchyBar reloads.
    try:
        line = lines.get(timeout=0.3 if pending else 15)
    except queue.Empty:
        if not pending:
            last = None
        refresh()
        pending = False
        continue
    if line is None:
        sys.exit(events.wait() or 1)
    msg = json.loads(line)
    params = msg.get("params") or {}
    if msg.get("method") == "event" and params.get("type") not in NOISE:
        pending = True
