inoremap <expr> <CR> NextIndent(&filetype)

if !exists("*NextIndent()")
function NextIndent(type)
	if type ==# "java"
		return <CR>
	endif
endfunction
endif

let s:src='/src/'

if !exists("*GetPackage")
function GetPackage()
	if &filetype ==# "java"
		for line in range(nextnonblank(1),prevnonblank("$"))
			let index = match(getline(line),"package")
			if index != -1 && synID(line,index+1,0)==91 && match(getline(line),';') != -1
				return strcharpart(getline(line),index+8,match(getline(line),';')-index-8)
			endif
		endfor
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
"Java Head
	if &filetype ==# "java"
		call append(0,"/**")
		call append(1,"* @author MCSW")
        call append(2,"* @version 1.0")
		call append(3,"*/")
		if expand('%:p:h') =~ s:src
			let b:package = Package()
			call append(4,"package " . b:package . ";")
		endif
		call append(5,"public class " . expand('%:t:r') . '{')
		call append(6,"\t")
		call append(7,"}")
		call cursor(7,1)
	elseif &filetype ==# "sh"
		call append(0,"#!/bin/sh")
	else
		echo "Unknown Format"
	endif
endfunction
endif

"一键编译运行命令
command -nargs=* Run call Run(<f-args>)
if !exists("*Run")
function Run(...)
	write
	let R_option = ""
	if &filetype ==# "sh"
		for Option in a:000
			let R_option .= " " . Option
		endfor
		if strpart(getfperm(expand('%:p')),2,1) ==# "-"
			call setfperm(expand('%:p'),"rwx" . strpart(getfperm(expand('%:p')),3))
		endif
		echo system(expand('%:p') . R_option)
	elseif &filetype ==# "java"
		for Option in a:000
			if strpart(Option,0,2) ==# "@C"
				let C_option .= " " . Option
			else
				let R_option .= " " . Option
			endif
		endfor
		
		if strpart(result,len(result)-2,1) != 0
			echo '*编译出错'
		else
			echo "*JVM启动中"
			let result = system('java ' . GetQualified() .  R_option )
			echo result
		endif
	else
		echo "Unknown Format"
	endif
endfunction
endif
command -nargs=* Compile call Compile(<f-args>)
if !exists("*Compile")
function Compile(...)
	if &filetype ==# "sh"
		echo "*不需要编译的代码类型"
		return 0
	endif
	let C_option = " -g"
	for Option in a:000
		let C_option .= ' ' . Option
	endfor
	if &filetype ==# "java"
		let result = system('javac ' . expand('%:p') . ' -d ' . )
	endif
endif
