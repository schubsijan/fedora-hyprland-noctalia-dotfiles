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
