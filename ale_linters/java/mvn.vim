" Author: bb010g <bb010g@gmail.com>
" Description: Lints java files using mvn

let g:ale_java_mvn_options = get(g:, 'ale_java_mvn_options', '')

function! ale_linters#java#mvn#GetMvnExecutable(buffer) abort
    if ale#path#FindNearestFile(a:buffer, 'pom.xml') isnot# ''
        return 'mvn'
    else
        return ''
    endif
endfunction

function! ale_linters#java#mvn#GetCommand(buffer) abort
    return 'mvn compile -Dmaven.compiler.showWarnings=true -Dmaven.compiler.showDeprecation=true '
    \ . ale#Var(a:buffer, 'java_mvn_options')
endfunction

function! ale_linters#java#mvn#HandleForFile(buffer, full_filename, lines) abort
    " Look for lines like the following:
    "
    " [WARNING] /home/w0rp/Main.java:[20,37] found raw type: java.util.Map
    " [ERROR] /home/w0rp/Main.java:[23,24] ';' expected

    let l:pattern = '\v^\[(\w+)\] (.*):\[(\d+),(\d+)\] (.+)$'
    let l:symbol_pattern = '\v^ +symbol: *(class|method) +([^ ]+)'
    let l:output = []

    for l:match in ale#util#GetMatches(a:lines, [l:pattern, l:symbol_pattern])
        if empty(l:match[3])
            " Add symbols to 'cannot find symbol' errors.
            if l:output[-1].text is# 'cannot find symbol'
                let l:output[-1].text .= ': ' . l:match[2]
            endif
        else
            call add(l:output, {
            \   'text': l:match[5],
            \   'lnum': l:match[3] + 0,
            \   'col': l:match[4],
            \   'filename': l:match[2],
            \   'type': l:match[1] is# 'ERROR' ? 'E' : 'W',
            \})
        endif
    endfor

    return l:output
endfunction

function! ale_linters#java#mvn#Handle(buffer, lines) abort
    return ale_linters#java#mvn#HandleForFile(a:buffer, bufname(a:buffer), a:lines)
endfunction

call ale#linter#Define('java', {
\   'name': 'mvn',
\   'executable_callback': 'ale_linters#java#mvn#GetMvnExecutable',
\   'command_callback': 'ale_linters#java#mvn#GetCommand',
\   'callback': 'ale_linters#java#mvn#Handle',
\   'output_stream': 'stdout',
\   'lint_file': 1,
\})
