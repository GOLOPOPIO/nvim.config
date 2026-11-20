" ftplugin: Razor использует HTML-поведение (matchit по тегам, omni-дополнение тегов)
if exists('b:did_ftplugin')
  finish
endif

runtime! ftplugin/html.vim

" комментарии Razor, а не HTML
setlocal commentstring=@*\ %s\ *@
let b:undo_ftplugin = (exists('b:undo_ftplugin') ? b:undo_ftplugin . '|' : '') . 'setlocal commentstring<'
