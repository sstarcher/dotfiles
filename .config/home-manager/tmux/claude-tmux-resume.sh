# Usage: claude-tmux-resume save <resurrect-file>   (@resurrect-hook-post-save-layout)
#        claude-tmux-resume resume <session-id> <dir> [--dangerously-skip-permissions]
# Lets tmux-resurrect reopen the Claude conversation that was running in each pane.
# Adapted from Corey Hinkle's dotfiles (personal-c0/Corey.Hinkle/dotfiles, claude/tmux-resume.sh).
config_dir="${CLAUDE_CONFIG_DIR:-$HOME/.claude}"
uuid='^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$'

# Live interactive sessions as "<parent pid>\t<session id>\t<dir>", from the
# registry Claude keeps for peer messaging (<config>/sessions/<pid>.json). This is
# Claude's internal state: if its format changes, panes restore as plain `claude`.
sessions() {
  local f pid start id dir
  for f in "$config_dir"/sessions/*.json; do
    pid=$(basename "$f" .json)
    [ -r "/proc/$pid/stat" ] || continue
    IFS=$'\t' read -r start id dir < <(jq -r 'select(.kind == "interactive") | [.procStart, .sessionId, .cwd] | @tsv' "$f" 2>/dev/null) || continue
    # procStart rules out an unrelated process that reused a dead session's pid.
    [ "$(awk '{ print $22 }' "/proc/$pid/stat")" = "$start" ] || continue
    printf '%s\t%s\t%s\n' "$(awk '/^PPid:/ { print $2 }' "/proc/$pid/status")" "$id" "$dir"
  done
}

# Pane lines are: pane, session, window, window_active, :flags, pane, title, :dir, active, command, :full_command.
# A Claude pane's shell is the pane process, so Claude's parent pid is the pane pid.
save() {
  local file=$1 tmp
  tmp=$(mktemp "$file.XXXXXX")
  awk -F'\t' -v OFS='\t' -v uuid="$uuid" '
    FILENAME == ARGV[1] { id[$1] = $2; dir[$1] = $3; next }
    FILENAME == ARGV[2] { shell[$1, $2, $3] = $4; next }
    $1 == "pane" && $10 ~ /^(claude|\.claude-unwrapped)$/ && (($2, $3, $6) in shell) {
      p = shell[$2, $3, $6]
      if (!(p in id) || id[p] !~ uuid) { print; next }
      d = dir[p]
      gsub(/\047/, "\047\\\047\047", d)
      cmd = ":claude-tmux-resume resume " id[p] " \047" d "\047"
      if ($11 ~ / --dangerously-skip-permissions( |$)/) cmd = cmd " --dangerously-skip-permissions"
      $11 = cmd
    }
    { print }
  ' <(sessions) <(tmux list-panes -a -F $'#{session_name}\t#{window_index}\t#{pane_index}\t#{pane_pid}') "$file" >"$tmp"
  mv "$tmp" "$file"
}

resume() {
  local id=$1 dir=$2 transcript
  shift 2
  for arg in "$@"; do
    [ "$arg" = --dangerously-skip-permissions ] || { echo "claude-tmux-resume: unsupported option $arg" >&2; return 2; }
  done
  [[ $id =~ $uuid ]] || { echo "claude-tmux-resume: not a session id: $id" >&2; return 2; }
  for transcript in "$config_dir"/projects/*/"$id.jsonl"; do [ -e "$transcript" ] && break; done
  if [ ! -e "$transcript" ]; then
    echo "claude-tmux-resume: session $id has no transcript in $config_dir; staying in the shell" >&2
    return 1
  fi
  cd "$dir" || { echo "claude-tmux-resume: $dir no longer exists; staying in the shell" >&2; return 1; }
  exec claude --resume "$id" "$@"
}

case "${1:-}" in
  save) save "$2" ;;
  resume) shift; resume "$@" ;;
  *) echo "usage: claude-tmux-resume save <file> | resume <session-id> <dir> [--dangerously-skip-permissions]" >&2; exit 2 ;;
esac
