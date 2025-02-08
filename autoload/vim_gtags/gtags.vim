" File: gen_gtags.vim
" Arthur: Ding Jing
" Usage:
"   1. Generate GTAGS
"   :GenGTAGS
"   2. Clear GTAGS
"   :ClearGTAGS

function! s:gtags_add(file) abort
  if filereadable(a:file)
    let l:cmd = 'silent! cs add ' . a:file . ' ' . vim_gtags#find_project_root() . ' -Cai'
    exec l:cmd
    silent! doautocmd User GenTags#GtagsLoaded
  endif
endfunction

function! s:gtags_auto_load() abort
  let l:file = $GTAGSDBPATH . '/' . s:file
  call s:gtags_add(l:file)
endfunction

"Generate GTAGS
function! s:gtags_db_gen() abort
  let l:src_dir = $GTAGSROOT
  let l:db_dir = $GTAGSDBPATH

  let b:file = l:db_dir . '/' . s:file

  "Check if project root in the blacklist
  if vim_gtags#isblacklist(l:src_dir)
    return
  endif

  "If gtags file exist, run update procedure.
  if filereadable(b:file)
    call s:gtags_update(1)
    return
  endif

  "Backup the current working directory and temporarily switch into the root
  "directory for running gtags command.
  let l:cwd = vim_gtags#fix_path(getcwd())
  lcd $GTAGSROOT

  let l:cmd = [g:vim_gtags#gtags_bin, l:db_dir]

  "Add gtags options
  if exists('g:vim_gtags#gtags_opts')
    let l:cmd += vim_gtags#opt_converter(g:vim_gtags#gtags_opts)
  endif

  function! s:gtags_db_gen_done(...) abort
    call vim_gtags#statusline#clear()

    if !exists('b:file')
      return
    endif
    call s:gtags_add(b:file)
    unlet b:file
  endfunction

  call vim_gtags#mkdir(l:db_dir)

  call vim_gtags#echo('Generating GTAGS in background')
  call vim_gtags#job#system_async(l:cmd, function('s:gtags_db_gen_done'))

  "Switch back to the original working directory.
  execute 'lcd' fnameescape(l:cwd)
endfunction

function! s:gtags_clear(bang) abort
  let l:db_dir = $GTAGSDBPATH
  let l:list = ['GTAGS', 'GPATH', 'GRTAGS', 'GSYMS']

  execute 'gtags-cscope kill -1'

  if empty(a:bang)
    for l:item in l:list
      let l:file = l:db_dir . '/' . l:item
      if filereadable(l:file)
        call delete(l:file)
      endif
    endfor
  else
    "Remove all files include tag folder
    let l:dir = vim_gtags#get_db_dir()
    call delete(l:dir, 'rf')
  endif
endfunction

function! s:gtags_update(full) abort
  let l:dbfile = $GTAGSDBPATH . '/' . s:file

  if !filereadable(l:dbfile)
    return
  endif

  "check file size
  if getfsize(vim_gtags#fix_path(l:dbfile)) == 0
    call delete(l:dbfile)
  endif

  call vim_gtags#echo('Update GTAGS in background')

  if a:full
    let l:cmd = [g:vim_gtags#global_bin, '-u']
  else
    let l:srcfile = fnamemodify(vim_gtags#fix_path('<afile>'), ':p')

    if !vim_gtags#is_file_belongs(l:srcfile)
      return
    endif

    let l:cmd = [g:vim_gtags#global_bin, '--single-update', l:srcfile]
  endif

  "Add global options
  if exists('g:vim_gtags#global_opts')
    let l:cmd += vim_gtags#opt_converter(g:vim_gtags#global_opts)
  endif

  call vim_gtags#job#system_async(l:cmd)
endfunction

function! s:gtags_auto_gen() abort
  " If not in scm, return
  let l:scm = vim_gtags#get_scm_info()
  if empty(l:scm['type'])
    return
  endif

  " If tags exist update it, otherwise generate new one.
  let l:file = $GTAGSDBPATH . '/' . s:file
  if filereadable(l:file)
    call s:gtags_update(1)
  else
    call s:gtags_db_gen()
  endif
endfunction

function! s:gtags_set_env() abort
  let $GTAGSROOT = vim_gtags#find_project_root()
  let $GTAGSDBPATH = vim_gtags#get_db_dir()
endfunction

function! vim_gtags#gtags#init() abort
  if exists('g:loaded_vim_gtags#gtags') && g:loaded_vim_gtags#gtags == 1
    return
  endif

  let s:file = 'GTAGS'

  "Options
  if !exists('g:vim_gtags#gtags_auto_gen')
    let g:vim_gtags#gtags_auto_gen = 0
  endif

  if !exists('g:vim_gtags#gtags_auto_update')
    let g:vim_gtags#gtags_auto_update = 1
  endif

  if !exists('g:vim_gtags#gtags_default_map')
    let g:vim_gtags#gtags_default_map = 1
  endif

  call s:gtags_set_env()

  set cscopetag
  set cscopeprg=gtags-cscope

  set nocscoperelative

  "Hotkey for gtags-cscope
  if g:vim_gtags#gtags_default_map == 1
    nmap <C-\>c :cs find c <C-R>=expand('<cword>')<CR><CR>
    nmap <C-\>d :cs find d <C-R>=expand('<cword>')<CR><CR>
    nmap <C-\>e :cs find e <C-R>=expand('<cword>')<CR><CR>
    nmap <C-\>f :cs find f <C-R>=expand('<cfile>')<CR><CR>
    nmap <C-\>g :cs find g <C-R>=expand('<cword>')<CR><CR>
    nmap <C-\>i :cs find i <C-R>=expand('<cfile>')<CR><CR>
    nmap <C-\>s :cs find s <C-R>=expand('<cword>')<CR><CR>
    nmap <C-\>t :cs find t <C-R>=expand('<cword>')<CR><CR>
  endif

  "Command list
  command! -nargs=0 GenGTAGS call s:gtags_db_gen()
  command! -nargs=0 -bang ClearGTAGS call s:gtags_clear('<bang>')

  augroup gen_gtags
    autocmd!
    if g:vim_gtags#gtags_auto_update
      autocmd BufWritePost * call s:gtags_update(0)
    endif

    autocmd BufWinEnter * call s:gtags_auto_load()

    autocmd BufEnter * call s:gtags_set_env()

    if g:vim_gtags#gtags_auto_gen
      autocmd BufReadPost * call s:gtags_auto_gen()
    endif
  augroup END

  let g:loaded_vim_gtags#gtags = 1
endfunction
