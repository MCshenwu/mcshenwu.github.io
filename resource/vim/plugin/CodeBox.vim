" Vim plugin for coding
" Version : 0.1
" Maintainer : MCshenwu (@MCshenwu)
" Last Change : 2022.1.21
" URL : https://gitee.com/mcsw/MCshenwu.github.io/resource/vim/plugin/CodeBox.vim
" More information in CodeBox.txt

" 自定义的脚本参数
" 默认的编译参数 可修改
let s:default_javac_args = ""
let s:default_java_args = ""
" 默认的java文档注释 按行分隔
let s:default_javadoc = ["@author MCSW","@version 1.0",]
" 默认的sh头部 按行分隔
let s:default_sh_head = ["#/bin/sh",]

" 不可修改的参数
" 标识符格式
let s:IDENTIFIER = '[a-zA-Z_\$][a-zA-Z0-9_\$]*'
au Filetype java,c,cpp inoremap <expr> <CR> NextIndent(&filetype)

if !exists("*NextIndent")
function NextIndent(type)
	if a:type ==# "java"
		return "\r"
	else
		return "\r"
	endif
endfunction
endif

if !exists("*GetPackage")
function GetPackage()
	if &filetype ==# "java"
		" 每行搜索package语句
		let statu = 0
		let temp = ""
		let number = nextnonblank(1)
		while number <= prevnonblank("$")
			if !empty(temp)
				let line = temp
				let temp = ""
			else
				let line = getline(number)
				let number = nextnonblank(number+1)
			endif
			if statu == 0
				if line =~ '^\s*/\*\{1,2}'
					let statu =	1
					let number = prevnonblank(number-1)
				elseif line =~ '^\s*package\s*' . s:IDENTIFIER .'\(\.' . s:IDENTIFIER . '\)*;'
					return line[matchend(line,'package\s*'):match(line,';')-1]
				elseif line !~ '^\s*//'
					return test_null_string()
				endif
			elseif statu == 1
				if line =~ '\*/'
					let statu = 0
					let temp = line[matchend(line,'\*/'):]
				endif
			endif
		endwhile
	endif
	return test_null_string()
endfunction
endif

if !exists("*GetQualified")
function GetQualified()
	if empty(GetPackage())
		return expand('%:r')
	else
		return GetPackage() . '.' . expand('%:r')
	endif
endfunction
endif

au FileType java call JavaInit()

if !exists("*JavaInit")
function JavaInit()
	let b:qualified=GetQualified()
endfunction
endif

if !exists("*JavaSyntax")
function JavaSyntax()
	let statu = 0
	
	
endfunction
endif

"添加文件头
au BufNewFile *.java,*.sh call AddHead()

if !exists("*AddHead")
function AddHead()
	let number = 0
	"Java
	if &filetype ==# "java"
		if !empty(s:default_javadoc)
			call append(0,'/**')
			let number = 1
			for line in s:default_javadoc
				call append(number,'* ' . line)
				let number += 1
			endfor
			call append(number,'*/')
		endif
		call append(number+2,"public class " . expand('%:t:r') . '{')
		call append(number+3,"\t")
		call append(number+4,"}")
		call cursor(number+3,1)
	elseif &filetype ==# "sh"
		if empty(s:default_sh_head)
			return
		endif
		for line in s;default_sh_head
			call append(number,line)
			let number += 1
		endfor
	else
		echo "Unknown Format"
	endif
endfunction
endif

command! -nargs=* Run call Run(<f-args>)
if !exists("*Run")
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
		! sh expand('%:p')
	elseif &filetype ==# "java"
		let C_option = ""
		let J_option = ""
		" "#C"开头参数作为javac参数 "#J"开头作为java启动参数
		for Option in a:000
			if Option =~ '^#C.\+'
				let C_option .= " " . Option[2:]
			elseif Option =~ '^#J.\+'
				let J_option .= " " . Option[2:]
			else
				let R_option .= " " . Option
			endif
		endfor
		" 寻找字节码文件
		let result = findfile(substitute(GetQualified(),'\.','/','g') . '.class',expand('%:p:h') . "/**10;/")
		" 编译
		if !empty(C_option) || empty(result) || getftime(expand('%:p')) > getftime(result)
			let result = Compile(C_option)
			if result == test_null_string()
				return
			endif
		else
		" 未编译
			if result =~ '^/'
				let result = result[:-len(GetQualified())-7]
			else
				let result = (getcwd().result)[:-len(GetQualified())-7]
			endif
		endif
		" 执行
		execute "! echom \"*JVM 启动\" ; java -cp " . result . ' ' . s:default_java_args . J_option . GetQualified() . R_option . " ; sleep 1"
		
	else
		echo "*未知文件格式"
	endif
endfunction
endif

command! -nargs=* Compile call Compile(<f-args>)
if !exists("*Compile")
function Compile(...)
	if &filetype ==# "java"
		echo "*Java编译器"
		let C_option = ' -d '
		let classpath = ''
		" 根据包确定编译目录和类路径
		if !empty(GetPackage())
			if expand('%:p') =~ '/.*/' . substitute(GetQualified(),'\.','/','g') . '.java'
				let classpath = expand('%:p:h')[:len(expand('%:p:h'))-len(GetPackage())-2]
			else
				echo "*您的package值 [". GetPackage() ."] 与实际目录 [" .expand('%:p:h'). "] 不符！输入回车在本目录下编译"
				if getchar() != 13
					echom "*取消编译"
					return test_null_string()
				endif
				let classpath = expand('%:p:h')
			endif
		else
			let classpath .= expand('%:p:h')
		endif
		let C_option .= classpath . ' -cp ' . classpath
		for Option in a:000
			let C_option .= ' ' . Option
		endfor
		" 编译并输出
		let result = system('javac'. s:default_javac_args . C_option . ' ' . expand('%:p') . ' ; echo $?')
		echom result[0:-3]
		" 编译正常则返回类路径
		if result[-2:-2] == 0
			echom "*编译完成"
			return classpath
		endif
		echom "*编译错误"
		return test_null_string()
	else
		echo "*不需要编译的代码"
		return test_null_string()
	endif
endfunction
endif
