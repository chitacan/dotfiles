#!/bin/bash

echo "install dotfiles..."

cp .gitconfig ~/
cp .gitignore ~/
cp .tigrc ~/
cp .iex.exs ~/
cp .vimrc ~/

# setup vim-plug
if [[ ! -d "${XDG_DATA_HOME:-$HOME/.local/share}"/nvim/site/autoload/plug.vim ]]; then
  sh -c 'curl -fLo "${XDG_DATA_HOME:-$HOME/.local/share}"/nvim/site/autoload/plug.vim --create-dirs \
       https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim'
fi

# setup fish config
if [[ ! -d ~/.config/fish ]]; then
  mkdir -p ~/.config/fish
fi

cp .config/fish/config.fish ~/.config/fish/
cp .config/fish/fish_plugins ~/.config/fish/

# setup default_files
if [[ -n "$CODESPACES" && -n "$GITHUB_REPOSITORY" && -d ".default_files/$GITHUB_REPOSITORY" ]]; then
  if [[ ! -d /workspaces/.default_files ]]; then
    mkdir /workspaces/.default_files
  fi

  cp -an .default_files/$GITHUB_REPOSITORY/. /workspaces/.default_files/
  cp -an .default_files/$GITHUB_REPOSITORY/. /workspaces/$RepositoryName
fi
