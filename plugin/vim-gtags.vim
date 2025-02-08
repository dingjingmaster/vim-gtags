" File: vim-gtags.vim
" Author: DingJing
" Version: 0.1
" Last Modified: 2014-06-12
"
" 用于自动生成 gtags


if !exists('g:vim_gtags#gtags_bin')
  let g:vim_gtags#gtags_bin = 'gtags'
endif

if !exists('g:vim_gtags#global_bin')
  let g:vim_gtags#global_bin = 'global'
endif

"Initial gtags support
if !get(g:, 'loaded_gentags#gtags', 0)
  if has('gtags-cscope') && executable(g:vim_gtags#gtags_bin)
    call vim_gtags#gtags#init()
  elseif !executable(g:vim_gtags#gtags_bin)
    echomsg 'GNU Global not found'
    echomsg 'vim-gtags.vim need GNU Global'
  endif
endif
