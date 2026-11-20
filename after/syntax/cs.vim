" Современный C# (11+) поверх стандартного syntax/cs.vim
if !exists('b:current_syntax') || b:current_syntax !=# 'cs'
  finish
endif

" модификаторы: public required string Name { get; set; }
syn keyword csModernModifier required scoped

" file-локализованные типы: file class Foo { }
syn match csModernModifier /\<file\ze\_s\+\%(class\|struct\|interface\|enum\|record\|delegate\)/

" with-выражения: order with { Status = ... }
syn match csModernKeyword /\<with\ze\_s*{/

" ограничения generic: where T : notnull
syn keyword csModernType notnull

hi def link csModernModifier StorageClass
hi def link csModernKeyword Keyword
hi def link csModernType Type

" vim: sw=2 sts=2 ts=4 noet
