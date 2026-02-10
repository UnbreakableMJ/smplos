function ff --description 'Fuzzy find files with bat preview'
    fzf --preview 'bat --style=numbers --color=always {}' $argv
end
