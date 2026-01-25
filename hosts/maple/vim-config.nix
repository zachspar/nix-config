{ pkgs, ... }:
{
  programs.vim = {
    enable = true;
    extraConfig = ''
      filetype plugin indent on
      syntax on
      set autoindent
      set smartindent
      set cindent
      set number
      set tabstop=4
      set shiftwidth=4
      set expandtab
      set hlsearch
      set smartcase
      set incsearch
      set colorcolumn=80
      set background=dark
    '';
  };
}
