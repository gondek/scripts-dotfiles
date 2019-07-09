function fish_title
  set -l last_status $status
  set -l home_escaped (echo -n $HOME | sed 's/\//\\\\\//g')
  set -l date_finished (date '+%T')
  echo -n "$PWD (exit $last_status @ $date_finished)" | sed "s/^$home_escaped/~/"
end
