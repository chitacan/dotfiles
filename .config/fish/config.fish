if status is-interactive
  if not set -q _fisher_plugins
    curl -sL git.io/fisher | source && fisher update
  end
end

alias cat bat
alias ls exa
alias ll "exa -alh"
alias tree "exa --tree -L 2 -alh"

# git prompt
set __fish_git_prompt_showdirtystate 'yes'
set __fish_git_prompt_showstashstate 'yes'
set __fish_git_prompt_showuntrackedfiles 'yes'
set __fish_git_prompt_showupstream 'yes'
set __fish_git_prompt_shorten_branch_len 10

set -x ERL_AFLAGS "-kernel shell_history enabled"
