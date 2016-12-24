function fish_title
  set -l home_escaped (echo -n $HOME | sed 's/\//\\\\\//g')
  echo -n $PWD | sed "s/^$home_escaped/~/" | sed 's/ /%20/g'
end
