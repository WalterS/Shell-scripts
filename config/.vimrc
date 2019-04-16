syntax on
filetype on
filetype plugin on
colorscheme default
set encoding=utf-8
set nocompatible
set formatoptions-=cro
set hlsearch
set incsearch
set ai
set ignorecase
set smartcase
set ruler
set ts=2 sts=2 sw=2 expandtab
set listchars+=trail:·
if has("patch-7.4.710")
  set listchars+=space:·
endif
autocmd Filetype python setlocal ts=4 sw=4 sts=4 expandtab
