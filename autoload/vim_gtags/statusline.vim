function! vim_gtags#statusline#set(msg) abort
  if ! get(g:, 'vim_gtags#statusline', 0)
    return
  endif

  if !exists('w:statusline')
    let w:statusline = &statusline
  endif

  if get(w:, 'airline_active', 0)
    let w:airline_disabled = 1
  endif

  let b:msg = a:msg

  setlocal statusline=%#ModeMsg#vim_gtags%*%#Normal#\ %{b:msg}
endfunction

function! vim_gtags#statusline#clear() abort
  if ! get(g:, 'vim_gtags#statusline', 0)
    return
  endif

  if get(w:, 'airline_active', 0)
    let w:airline_disabled = 0
  endif

  if exists('w:statusline')
    let &statusline = w:statusline
    unlet w:statusline
  endif
endfunction
