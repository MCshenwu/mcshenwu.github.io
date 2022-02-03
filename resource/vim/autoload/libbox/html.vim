" Vim library for coding(With CodeBox)
" Version : 0.1
" Maintainer : MCshenwu
" Last Change : 2022.1.21
" URL : https://gitee.com/mcsw/MCshenwu.github.io/resource/vim/autoload/libbox/html.vim

let s:default_html_head = ["<!DOCTYPE html>", "<html>", "<head>", "\t<meta charset=\"UTF-8\"/>", "</head>", "<body>", "\t", "</body>","</html>"]

function libbox#html#AddHead()
	if &filetype ==# "html"
		if empty(s:default_html_head)
			return
		endif
		let number = 0
		for line in s:default_html_head
			call append(number, line)
			let number += 1
		endfor
	endif
endfunction
