function fish_prompt
  set -l last_status $status
  set -l home_escaped (echo -n $HOME | sed 's/\//\\\\\//g')
  set -l pwd (echo -n $PWD | sed "s/^$home_escaped/~/" | sed 's/ /%20/g')

  set -l prompt_symbol ''
  set -l prompt_color ''
  set -l prompt_status ''

  if [ $last_status -ne  0 ]
    set prompt_status "($last_status)"
  end

  switch $USER
    case root; set prompt_symbol '#'; set prompt_color $fish_color_cwd_root
    case '*'; set prompt_symbol '$'; set prompt_color $fish_color_cwd
  end

  printf "[%s%s%s]%s%s " (set_color $prompt_color) $pwd (set_color normal) $prompt_status $prompt_symbol
end
