" File: vim-gtags.vim
" Author: Ding Jing

"Global variables
if !exists('g:vim_gtags#verbose')
  let g:vim_gtags#verbose = 0
endif

"Initial blacklist
if !exists('g:vim_gtags#blacklist')
  let g:vim_gtags#blacklist = []
endif

"Initial glob blacklist
if !exists('g:vim_gtags#blacklist_re')
  let g:vim_gtags#blacklist_re = []
endif

"Use cache dir by default
if !exists('g:vim_gtags#use_cache_dir')
  let g:vim_gtags#use_cache_dir = 1
endif

" Specify cache dir
if !exists('g:vim_gtags#cache_dir')
    let g:vim_gtags#cache_dir = '$HOME/.cache/gtags/'
endif

" Specify default root marker
if !exists('g:vim_gtags#root_marker')
  let g:vim_gtags#root_marker = '.root'
endif

" Assign root path
if !exists('g:vim_gtags#root_path')
  let g:vim_gtags#root_path = ''
endif

"Get scm repo info
function! vim_gtags#get_scm_info() abort
  let l:scm = {'type': '', 'root': ''}

  "Supported scm repo
  let l:scm_list = [g:vim_gtags#root_marker, '.git', '.hg', '.svn']

  "Detect scm type
  for l:item in l:scm_list
    let l:dir = finddir(l:item, '.;')
    if !empty(l:dir)
      let l:scm['type'] = l:item
      let l:scm['root'] = l:dir
      break
    endif
  endfor

  "Not a scm repo, return
  if empty(l:scm['type'])
    return l:scm
  endif

  "Get scm root
  let l:scm['root'] = vim_gtags#fix_path(fnamemodify(l:scm['root'], ':p:h'))
  let l:scm['root'] = substitute(l:scm['root'], '/' . l:scm['type'], '', 'g')

  return l:scm
endfunction

"Find the root of the project
"if the project managed by git/hg/svn, return the repo root.
"else return the current work directory.
function! vim_gtags#find_project_root() abort
  " Check assign root_path
  if !empty(glob(g:vim_gtags#root_path))
    return g:vim_gtags#root_path
  endif

  "If it is scm repo, use scm folder as project root
  let l:scm = vim_gtags#get_scm_info()
  if !empty(l:scm['type'])
    return l:scm['root']
  endif

  return vim_gtags#fix_path(getcwd())
endfunction

"Fix shellslash for windows
function! vim_gtags#fix_path(path) abort
  let l:path = expand(a:path, 1)
  if has('win32')
    let l:path = substitute(l:path, '\\', '/', 'g')
  endif
  return l:path
endfunction

"Get db name, remove / : with , beacause they are not valid filename
function! vim_gtags#get_db_name(path) abort
  let l:fold = substitute(a:path, '/\|\\\|\ \|:\|\.', '', 'g')
  return l:fold
endfunction

function! vim_gtags#echo(str) abort
  if g:vim_gtags#verbose
    echomsg a:str
  endif
endfunction

"Check if current path is in blacklist
function! vim_gtags#isblacklist(path) abort
  if (!exists('g:vim_gtags#blacklist') || g:vim_gtags#blacklist == []) &&
        \ (!exists('g:vim_gtags#blacklist_re') || g:vim_gtags#blacklist_re == [])
    call vim_gtags#echo('blacklist not set or blacklist is null')
    return 0
  endif

  for l:dir in g:vim_gtags#blacklist
    let l:dir = fnamemodify(vim_gtags#fix_path(l:dir), ':p:h')
    if a:path ==# l:dir
      call vim_gtags#echo('Found path ' . a:path . ' in the blacklist')
      return 1
    endif
  endfor

  let l:abs_path = fnamemodify(a:path, ':p')
  for l:re in g:vim_gtags#blacklist_re
    if a:path =~ l:re
      call vim_gtags#echo('Found path ' . a:path . ' to be a blacklisted pattern')
      return 1
    endif

    if l:abs_path =~ l:re
      call vim_gtags#echo('Found path ' . l:abs_path . ' to be a blacklisted pattern')
      return 1
    endif
  endfor

  call vim_gtags#echo('Did NOT find path ' . a:path . ' in the blacklist')
  return 0
endfunction

"Get db dir according to project type and g:vim_gtags#use_cache_dir
function! vim_gtags#get_db_dir() abort
  let l:scm = vim_gtags#get_scm_info()

  if g:vim_gtags#use_cache_dir == 0 && !empty(l:scm['type'])
    let l:tagdir = l:scm['root'] . '/' . l:scm['type'] . '/tags_dir'
  else
    let l:root = vim_gtags#find_project_root()
    " If g:vim_gtags#cache_dir doesn't have '/', then insert '/' when concatenating
    let l:tagdir = g:vim_gtags#cache_dir . 
        \ (g:vim_gtags#cache_dir[-1:] == '/' ? '' : '/') .
        \ vim_gtags#get_db_name(l:root)
  endif

  return vim_gtags#fix_path(l:tagdir)
endfunction

"Create db root dir and cwd db dir.
function! vim_gtags#mkdir(dir) abort
  if !isdirectory(a:dir)
    call mkdir(a:dir, 'p')
  endif
endfunction

function! vim_gtags#opt_converter(opt) abort
  if type(a:opt) == 1 "string
    let l:cmd = split(a:opt, '\ ')
  elseif type(a:opt) == 3 "list
    let l:cmd = a:opt
  endif

  return l:cmd
endfunction

"Check file belonging
"return:
"  1: file belongs to project
"  0: file don't belong to project
function! vim_gtags#is_file_belongs(file) abort
  let l:root = vim_gtags#find_project_root()
  let l:srcpath = vim_gtags#fix_path(fnamemodify(a:file, ':p:h'))

  if l:srcpath =~ l:root
    call vim_gtags#echo('file ' . a:file . ' belongs to ' . l:root)
    return 1
  endif

  call vim_gtags#echo('file ' . a:file . ' does not belong to ' . l:root)
  return 0
endfunction
