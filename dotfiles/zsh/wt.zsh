# wt <branch> [claude|codex|pi] [task]: a git worktree in its own herdr space,
# with an agent started in it. Same layout as herdr's New worktree dialog.
wt() {
  if (( $# < 1 )); then
    echo "usage: wt <branch> [claude|codex|pi] [task]" >&2
    return 1
  fi
  local branch=$1 agent=${2:-claude} task=${3:-}
  case $agent in
    claude|codex|pi) ;;
    *) echo "wt: agent must be claude, codex or pi" >&2; return 1 ;;
  esac

  # The main checkout names the repo, also when run from inside another worktree.
  local common main dir
  common=$(git rev-parse --path-format=absolute --git-common-dir) || return 1
  main=${common:h}
  dir=$HOME/.herdr/worktrees/${main:t}/${branch//\//-}

  if [[ -d $dir ]]; then
    # `a/b` and `a-b` share a folder: only reuse it if it holds this repo and branch.
    local have_common have_branch
    have_common=$(git -C "$dir" rev-parse --path-format=absolute --git-common-dir 2>/dev/null)
    have_branch=$(git -C "$dir" symbolic-ref --quiet --short HEAD 2>/dev/null)
    if [[ $have_common != "$common" || $have_branch != "$branch" ]]; then
      echo "wt: $dir holds ${have_branch:-something else}, not $branch" >&2
      return 1
    fi
  else
    if git show-ref --verify --quiet "refs/heads/$branch"; then
      git worktree add "$dir" "$branch" || return 1
    else
      git worktree add -b "$branch" "$dir" HEAD || return 1
    fi
  fi

  # herdr runs argv in a login shell and leaves that shell when the agent quits.
  herdr-app do space.new --name "$branch" --folder "$dir" \
    --argv "$(jq -nc --arg a "$agent" --arg t "$task" '[$a] + (if $t == "" then [] else [$t] end)')" >/dev/null
}
