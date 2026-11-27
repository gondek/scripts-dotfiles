# Remember when each command finished, for the title below. fish autoloads this file the
# first time it shows a title, before any command runs, so this handler is in place in time.
function __fish_title_record_finish --on-event fish_postexec
    set -g __fish_title_finished (date '+%T')
end

function fish_title
    set -l last_status $status
    # replace a leading $HOME with ~, but only at a path boundary
    set -l home_re (string escape --style=regex -- $HOME)
    set -l dir (string replace -r -- "^$home_re(?=/|\$)" '~' $PWD)
    if set -q argv[1]
        # a command is running; fish passes it in $argv
        echo -n "$dir: $argv[1]"
    else if set -q __fish_title_finished
        echo -n "$dir (exit $last_status @ $__fish_title_finished)"
    else
        echo -n $dir  # no command has run yet in this shell
    end
end
