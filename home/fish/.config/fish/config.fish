set fish_greeting
function starship_transient_prompt_func
  starship module character
end
function starship_transient_rprompt_func
  starship module custom.transient_time
end
starship init fish | source

# mise: Tools aus ~/.config/mise/config.toml in den PATH holen
# (Guard, weil mise nicht über packages.txt kommt und auf frischen Systemen fehlen kann)
if command -q mise
    mise activate fish | source
end

# zoxide: cd springt per Teilname in oft besuchte Verzeichnisse ("cd dotf").
# Existiert das Ziel als Pfad, verhält sich cd normal (inkl. "cd" → ~ und "cd -").
# Nur bei einem zoxide-Sprung wird das Ziel ausgegeben.
if command -q zoxide
    zoxide init fish | source

    function cd --wraps=__zoxide_z --description 'cd mit zoxide-Fallback'
        if test (count $argv) -eq 0; or test "$argv" = -; or test -d "$argv[1]"
            __zoxide_z $argv
        else
            if not __zoxide_z $argv
                echo "Error: Directory not found" >&2
                return 1
            end
            printf '\U000F17A9 '
            pwd
        end
    end
end

# eza statt ls: Langformat, Verzeichnisse zuerst, Icons nur im Terminal
if command -q eza
    alias ls='eza -lh --group-directories-first --icons=auto'
    # Verzeichnisbaum ohne .gitignore-Inhalte
    alias lt='eza --tree --icons --git-ignore --group-directories-first'
end
