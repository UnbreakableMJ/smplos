function n --description 'Open nvim (current dir if no args)'
    if test (count $argv) -eq 0
        nvim .
    else
        nvim $argv
    end
end
