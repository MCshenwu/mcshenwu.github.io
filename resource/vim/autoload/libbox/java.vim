" Vim library for java [with CodeBox plugin]
" Version : 0.1
" Maintainer : MCshenwu (@MCshenwu)
" Last Change : 2022.1.21
" URL : https://gitee.com/mcsw/MCshenwu.github.io/resource/vim/autoload/libbox/java.vim
"

" 自定义的脚本参数
" 默认的编译参数 可修改
let s:default_javac_args = ""
let s:default_java_args = ""
" 默认的java文档注释 按行分隔
let s:default_javadoc = ["@author MCSW","@version 1.0",]

" 不可修改的常量
" Java关键字
let s:JAVA_KEYWORD = ["if","else","for","while","do","switch","case","default","try","catch","finally","break","continue","return","class","public","protected","private","static","enum","interface","extends","implements","int","short","byte","long","char","boolean","new","package","import","void","instanceof","throws","throws","abstract","float","double","native","this","super","synchronized","transient","assert","final","strictfp","goto","const","volatile"]

function libbox#java#GetPackage()
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
				elseif line =~ '^\s*package\s*' . g:IDENTIFIER .'\(\.' . g:IDENTIFIER . '\)*;'
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

function libbox#java#GetQualified()
	if empty(libbox#java#GetPackage())
		return expand('%:r')
	else
		return libbox#java#GetPackage() . '.' . expand('%:r')
	endif
endfunction

function libbox#java#Flush()
	let b:package = libbox#java#GetPackage()
	let b:qualified = b:package . '.' . expand('%:r')
endfunction

function libbox#java#AddHead()
	if &filetype !=# 'java'
		return
	endif
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
endfunction

function libbox#java#Compile(...)
	if &filetype !=# "java"
		return test_null_string()
	endif
	call libbox#java#Flush()
	echo "*Java编译器"
	let C_option = ' -d '
	let classpath = ''
	" 根据包确定编译目录和类路径
	if !empty(b:package)
		if expand('%:p') =~ '/.*/' . substitute(b:qualified,'\.','/','g') . '.java'
			let classpath = expand('%:p:h')[:len(expand('%:p:h'))-len(b:package)-2]
		else
			echo "*您的package值 [". b:package ."] 与实际目录 [" .expand('%:p:h'). "] 不符！输入回车在本目录下编译"
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
	let result = system('javac '. s:default_javac_args . C_option . ' ' . expand('%:p') . ' ; echo $?')
	echom result[0:-3]
	" 编译正常则返回类路径
	if result[-2:-2] == 0
		echom "*编译完成"
		return classpath
	endif
	echom "*编译错误"
	return test_null_string()
endfunction

function libbox#java#Run(...)
	if &filetype !=# 'java'
		return
	endif
	let C_option = ""
	let R_option = ""
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
	let result = findfile(substitute(libbox#java#GetQualified(),'\.','/','g') . '.class',expand('%:p:h') . "/**4;../../../../")
	" 编译
	if !empty(C_option) || empty(result) || getftime(expand('%:p')) > getftime(result)
		call system('rm ' . result)
		let result = libbox#java#Compile(C_option)
		sleep 3
		if result == test_null_string()
			return
		endif
	else
	" 未编译
		if result =~ '^/'
			let result = result[:-len(libbox#java#GetQualified())-7]
		else
			let result = (getcwd().result)[:-len(libbox#java#GetQualified())-7]
		endif
	endif
	" 执行
	execute "! echom \"*JVM 启动\" ; java -cp " . result . ' ' . s:default_java_args . J_option . libbox#java#GetQualified() . R_option . " ; sleep 1"
endfunction
