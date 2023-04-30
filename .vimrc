scriptencoding utf-8

set directory^=$HOME/.vim/swap//
set nocompatible
set belloff=all
filetype off

call plug#begin()
Plug 'junegunn/fzf', { 'do': { -> fzf#install() } }
Plug 'junegunn/fzf.vim'
Plug 'sheerun/vim-polyglot'
Plug 'elixir-editors/vim-elixir'
Plug 'mattn/emmet-vim'
Plug 'honza/vim-snippets'
Plug 'tpope/vim-fugitive'
Plug 'mhinz/vim-mix-format'
call plug#end()

set mouse-=a
set encoding=utf-8
set ai cindent
set ts=2 sw=2
set expandtab
set number
set foldcolumn=1
set hlsearch
set ruler
set t_Co=256
set background=dark
set ic
set list
set listchars=trail:·,precedes:«,extends:»,eol:¬,tab:\ \
set fo+=r
set exrc
set colorcolumn=80
set backspace=2
set nofoldenable
set clipboard=unnamed
set noimd
set laststatus=2
set cursorline
set tags=tags;/

syntax on
hi CursorLine term=bold cterm=bold ctermbg=8
hi CursorLineNr term=bold cterm=bold ctermfg=8 gui=bold
hi NonText ctermfg=240
hi Pmenu ctermbg=238
hi FoldColumn ctermbg=NONE
hi Search ctermfg=240

"fzf.vim
nmap <C-P> :FZF<CR>
nmap <space>s :Buffers<CR>
nmap <space>t :Windows<CR>
nmap <space>m :Marks<CR>
nmap <space>h :History<CR>
nmap <space>c :Commits<CR>
nmap <space>b :BCommits<CR>
nmap <space>f :Rg <C-R><C-W><CR>

"edit .vimrc
nmap <space>e :e ~/.vimrc<CR>
nmap <space>r :source ~/.vimrc<CR>

let g:loaded_python_provider = 0
let g:mix_format_on_save = 1

au BufNewFile,BufRead,BufReadPost *.gitcommit set syntax=gitcommit
