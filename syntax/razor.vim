" Vim syntax file: Razor (.cshtml, .razor, Blazor)
" HTML/XML разметка + C# внутри @{ }, @code { }, @(...) и @выражений.

if exists('b:current_syntax')
  finish
endif

let s:cpo_save = &cpo
set cpo&vim

let main_syntax = 'razor'

runtime! syntax/html.vim
unlet! b:current_syntax

syn include @razorCs syntax/cs.vim
unlet! b:current_syntax

syn case match

" --- комментарии Razor: @* ... *@
syn region razorComment start=/@\*/ end=/\*@/ contains=@Spell

" --- экранированный @
syn match razorEscape /@@/

" --- C# внутри разметки -----------------------------------------------------
" общее выражение: @Model.Name, @item.Title, @Url.Action
" объявлено раньше блоков, чтобы @{ } и @code { } перекрывали его
syn match razorExprIdent /@\h\w*\%(\.\h\w*\)*/

" многострочный блок: @{ ... } или @code { ... }
syn region razorBlock matchgroup=razorDelim
      \ start=/@\%(code\|functions\)\?[ \t]*{[ \t]*$/
      \ end=/^[ \t]*}/
      \ contains=@razorCs
      \ keepend

" однострочный блок: @{ var x = 1; } / @code { return 1; }
syn region razorBlockInline matchgroup=razorDelim
      \ start=/@\%(code\|functions\)\?[ \t]*{[ \t]*\ze\S/
      \ end=/}/
      \ contains=@razorCs
      \ oneline

" @(...) — явное выражение
syn region razorExpr matchgroup=razorDelim start=/@(/ end=/)/ contains=@razorCs

" @if, @foreach, @await и т.п. — управляющие конструкции
syn match razorControl /@\%(if\|else\|foreach\|for\|while\|switch\|case\|default\|try\|catch\|finally\|lock\|using\|do\|await\|yield\|return\|break\|continue\|throw\)\>/

" @: текст как литерал
syn match razorLineLiteral /@:.*$/

" --- директивы --------------------------------------------------------------
syn match razorDirective /^[ \t]*@\%(page\|model\|using\|inject\|namespace\|inherits\|implements\|layout\|attribute\|typeparam\|rendermode\|preservewhitespace\|tagHelperPrefix\|section\)\>/
syn match razorDirectiveArg /^[ \t]*@\%(page\|model\|using\|inject\|namespace\|inherits\|implements\|layout\|attribute\|typeparam\|rendermode\|preservewhitespace\|tagHelperPrefix\|section\)[ \t]\+\zs[^@]*$/

" --- атрибуты HTML со значениями C# (@Url.Action, @Model.Name внутри кавычек)
" match вместо region: region с end-паттерном на кавычке ломает htmlString/htmlTag
syn match razorAttrExpr contained /@\h\w*\%(\.\h\w*\)*/

" Blazor: @bind, @onclick, @ref, @key, @attributes
" объявлены после razorAttrExpr, чтобы выигрывать у общего выражения
syn match razorBlazorAttr contained /@\%(bind\|on\)\a*/
syn match razorBlazorAttr contained /@\%(ref\|key\|attributes\|formname\)\>/

syn cluster htmlPreproc add=razorAttrExpr,razorBlazorAttr

" --- подсветка ---------------------------------------------------------------
hi def link razorComment Comment
hi def link razorTransition Statement
hi def link razorDelim Delimiter
hi def link razorEscape SpecialChar
hi def link razorDirective PreProc
hi def link razorDirectiveArg Type
hi def link razorControl Statement
hi def link razorExprIdent Identifier
hi def link razorLineLiteral String
hi def link razorBlazorAttr Special

let b:current_syntax = 'razor'

let &cpo = s:cpo_save
unlet s:cpo_save

" vim: sw=2 sts=2 ts=4 noet
