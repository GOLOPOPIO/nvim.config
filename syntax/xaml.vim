" Vim syntax file: XAML (MAUI, WPF, WinUI) — XML + разметочные расширения.
if exists('b:current_syntax')
  finish
endif

let s:cpo_save = &cpo
set cpo&vim

let main_syntax = 'xaml'

runtime! syntax/xml.vim
unlet! b:current_syntax

syn case match

" {Binding ...}, {StaticResource ...}, {x:Static ...}, {AppThemeBinding ...}
syn region xamlMarkup contained matchgroup=xamlMarkupDelim
      \ start=/{/
      \ end=/}/
      \ contains=xamlMarkupName,xmlString
syn match xamlMarkupName contained /\%({\s*\)\@<=\h\w*\%(:\h\w*\)\?/

" x:Class, x:Name, x:Key, x:DataType и другие x:-атрибуты
syn match xamlDirective contained /\<x:\h\w*/
syn cluster xmlStartTagHook add=xamlDirective

" переопределяем строки, чтобы внутри кавычек работали разметочные расширения
syn region xmlString contained start=+"+ end=+"+ contains=xmlEntity,@Spell,xamlMarkup display
syn region xmlString contained start=+'+ end=+'+ contains=xmlEntity,@Spell,xamlMarkup display

hi def link xamlMarkupDelim Delimiter
hi def link xamlMarkupName Function
hi def link xamlDirective Special

let b:current_syntax = 'xaml'

let &cpo = s:cpo_save
unlet s:cpo_save

" vim: sw=2 sts=2 ts=4 noet
