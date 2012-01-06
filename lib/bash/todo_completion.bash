# move to /etc/bash_completion.d/todo

_todo()
  { 
    local cur words 
    COMPREPLY=()
    words="${COMP_WORDS[@]:1}"
    cur="${COMP_WORDS[COMP_CWORD]}"
    todo="~/.todo"
 
    local nexts=$( cat "${todo}" | grep -F "${words}" | grep '^\+' | cut -b34- | while read LINE; do elems=( ${LINE} ); echo "${elems[COMP_CWORD-1]}" ; done )
    COMPREPLY=( $(compgen -W "${nexts}" -- "${cur}" ) )
    return 0
  }
  
complete -F _todo ++
complete -F _todo xx

