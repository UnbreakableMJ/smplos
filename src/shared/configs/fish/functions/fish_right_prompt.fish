function fish_right_prompt
    set -l git_branch (__fish_git_prompt "%s")
    if test -n "$git_branch"
        set_color yellow
        echo -n "$git_branch"
        set_color normal
    end
end
