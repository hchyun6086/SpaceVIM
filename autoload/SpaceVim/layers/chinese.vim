"=============================================================================
" chinese.vim --- SpaceVim chinese layer
" Copyright (c) 2016-2021 Wang Shidong & Contributors
" Author: Wang Shidong < wsdjeg at 163.com >
" URL: https://spacevim.org
" License: GPLv3
"=============================================================================

""
" @section Chinese, layers-chinese
" @parentsection layers
" `chinese` layer provides Chinese specific function for SpaceVim.
" This layer is not loaded by default, to use this layer, add following
" snippet into your SpaceVim configuration file.
" >
"   [[layers]]
"     name = 'chinese'
" <
"
" @subsection key bindings
" >
"   Key binding     Description
"   SPC l c         check with ChineseLinter
"   SPC x g t       translate current word
"   SPC n c d       convert chinese number to digit 
" <
" 


function! SpaceVim#layers#chinese#plugins() abort
  let plugins = [
        \ ['yianwillis/vimcdoc'          , {'merged' : 0}],
        \ ['voldikss/vim-translator' , {'merged' : 0, 'on_cmd' : ['Translate', 'TranslateW', 'TranslateR', 'TranslateX']}],
        \ ['wsdjeg/ChineseLinter.vim'    , {'merged' : 0, 'on_cmd' : 'CheckChinese', 'on_ft' : ['markdown', 'text']}],
        \ ]
  if SpaceVim#layers#isLoaded('ctrlp')
    call add(plugins, ['vimcn/ctrlp.cnx', {'merged' : 0}])
  endif
  return plugins
endfunction

function! SpaceVim#layers#chinese#config() abort
  let g:_spacevim_mappings_space.x.g = {'name' : '+translate'}
  call SpaceVim#mapping#space#def('nnoremap', ['x', 'g', 't'], 'Translate'         , 'translate current word'  , 1)
  call SpaceVim#mapping#space#def('nnoremap', ['l', 'c']     , 'CheckChinese', 'Check with ChineseLinter', 1)
  let g:_spacevim_mappings_space.n.c = {'name' : '+Convert'}
  call SpaceVim#mapping#space#def('nnoremap', ['n', 'c', 'd'], 'silent call call('
        \ . string(s:_function('s:ConvertChineseNumberUnderCursorToDigit')) . ', [])',
        \ 'Convert Chinese Number to Digit', 1)
  " do not load vimcdoc plugin 
  let g:loaded_vimcdoc = 1
endfunction

function! SpaceVim#layers#chinese#health() abort
  call SpaceVim#layers#chinese#plugins()
  call SpaceVim#layers#chinese#config()
  return 1
endfunction

function! s:ConvertChineseNumberUnderCursorToDigit() abort
  let cword = expand('<cword>')
  let ChineseNumberPattern = "[?????????????????????????????????????????????????????????????????????]\+"
  while cword =~ ChineseNumberPattern
    let matchword = matchstr(cword, ChineseNumberPattern)
    let cword = substitute(cword, matchword, s:Chinese2Digit(matchword))
  endwhile
  if !empty(cword)
    let save_register = @k
    let save_cursor = getcurpos()
    let @k = cword
    normal! viw"kp
    call setpos('.', save_cursor)
    let @k = save_register
  endif
endfunction

let s:list = SpaceVim#api#import('data#list')
function! s:Chinese2Digit(cnDigitString) abort
  let CN_NUM = {
        \ '???': 0, '???': 1, '???': 2, '???': 3, '???': 4, '???': 5, '???': 6, '???': 7, '???': 8, '???': 9,
        \ '???': 0, '???': 1, '???': 2, '???': 3, '???': 4, '???': 5, '???': 6, '???': 7, '???': 8, '???': 9,
        \ '???': 2, '???': 2
        \ }
  let CN_UNIT = {
        \ '???': 10, '???': 10, '???': 100, '???': 100, '???': 1000, '???': 1000, '???': 10000, '???': 10000,
        \ '???': 100000000, '???': 100000000, '???': 1000000000000
        \ }

  let cnList = split(a:cnDigitString, "???")
  let integer = cnList[0]  " ????????????
  let decimal = len(cnList) == 2 ? cnList[1] : [] " ????????????
  let unit = 0  " ????????????
  let parse = []  " ????????????
  let i = len(integer)
  while i >= 0
    let i -= 1
    let x = integer[i]
    if has_key(CN_UNIT, x)
      " ?????????????????????
      let unit = CN_UNIT[x]
      if unit == 10000 " ??????
        s:list.push(parse, "w")
        let unit = 1
      elseif unit == 100000000 " ??????
        s:list.push(parse, "y")
        let unit = 1
      elseif unit == 1000000000000  " ??????
        s:list.push(parse, "z")
        let unit = 1
        continue
      endif
    else
      " ?????????????????????
      let dig = CN_NUM[x]
      if unit
        let dig = dig * unit
        let unit = 0
      endif
      s:list.push(parse, dig)
    endif
  endwhile

  if unit == 10  " ??????10-19?????????
    s:list.push(parse, 10)
  endif
  let result = 0
  let tmp = 0
  while parse
    let x = s:list.pop(parse)
    if x == 'w'
        let tmp *= 10000
        let result += tmp
        let tmp = 0
    elseif x == 'y'
        let tmp *= 100000000
        let result += tmp
        let tmp = 0
    elseif x == 'z'
        let tmp *= 1000000000000
        let result += tmp
        let tmp = 0
    else
        let tmp += x
    endif
    let result += tmp
  endwhile

  if !empth(decimal)
    for [k, v] in items(CN_NUM)
      let decimal = substitute(decimal, k, v, 'g')
    endfor
    let decimal = "0." + decimal
    let result += eval(decimal)
  endif
  return result
endfunction

" function() wrapper
if v:version > 703 || v:version == 703 && has('patch1170')
  function! s:_function(fstr) abort
    return function(a:fstr)
  endfunction
else
  function! s:_SID() abort
    return matchstr(expand('<sfile>'), '<SNR>\zs\d\+\ze__SID$')
  endfunction
  let s:_s = '<SNR>' . s:_SID() . '_'
  function! s:_function(fstr) abort
    return function(substitute(a:fstr, 's:', s:_s, 'g'))
  endfunction
endif

" vim:set et nowrap sw=2 cc=80:
