" Vim plugin for coding
" Version : 0.1
" Maintainer : MCshenwu (@MCshenwu)
" Last Change : 2022.1.21
" URL : https://gitee.com/mcsw/MCshenwu.github.io/resource/vim/plugin/CodeBox.vim
" More information in CodeBox.txt

" 自定义的脚本参数
" 默认的sh头部 按行分隔
let s:default_sh_head = ["#/bin/sh",]

" 不可修改的参数
" 标识符格式
let g:IDENTIFIER = '[a-zA-Z_\$][a-zA-Z0-9_\$]*'

"添加文件头
au BufNewFile *.java,*.sh call AddHead()

function! AddHead()
	let number = 0
	"Java
	if &filetype ==# "java"
		call AddJavaHead()
	elseif &filetype ==# "sh"
		if empty(s:default_sh_head)
			return
		endif
		for line in s:default_sh_head
			call append(number,line)
			let number += 1
		endfor
	else
		echo "Unknown Format"
	endif
endfunction

command! -nargs=* Compile call Compile(<f-args>)
function Compile(...)
	let C_option = ""
	for Option in a:000
		let C_option .= ' ' . Option
	endfor
	if &filetype ==# "java"
		return JavaCompile(C_option)
	else
		echo "*不需要编译的代码"
		return test_null_string()
	endif
endfunction

command! -nargs=* Run call Run(<f-args>)
function Run(...)
	" 文件已修改>写入
	if getbufinfo(bufname('#'))[0].changed
		write
	endif
	let R_option = ""
	if &filetype ==# "sh"
		" 连接参数
		for Option in a:000
			let R_option .= " " . option
		endfor
		" 添加可执行权限
		if !executable(expand('%:p'))
			call setfperm(expand('%:p'),"rwx" . strpart(getfperm(expand('%:p')),3))
		endif
		execute "! sh " . expand('%:p') . R_option
	elseif &filetype ==# "java"
		let C_option = ""
		let J_option = ""
		" "#C"开头参数作为javac参数 "#J"开头作为java启动参数
		for Option in a:000
			if Option =~ '^#C.\+'
				let C_option .= Option . ' '
			elseif Option =~ '^#J.\+'
				let J_option .= Option . ' '
			else
				let R_option .= Option . ' '
			endif
		endfor
		call RunJava(C_option,J_option,R_option)
	else
		echo "*未知文件格式"
	endif
endfunction
