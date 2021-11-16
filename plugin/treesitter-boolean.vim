if exists('g:loaded_treesitter_boolean') | finish | endif " prevent loading file twice
let s:save_cpo = &cpo " save user coptions
set cpo&vim           " reset them to defaults

let &cpo = s:save_cpo " and restore after
unlet s:save_cpo
let g:loaded_treesitter_boolean = 1
