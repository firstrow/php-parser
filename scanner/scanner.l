%{
// Copyright (c) 2011 CZ.NIC z.s.p.o. All rights reserved.
// Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.

// blame: jnml, labs.nic.cz

package scanner

import (
    "fmt"
    "bytes"
	"github.com/cznic/golex/lex"
    "github.com/z7zmey/php-parser/comment"
)

const (
	INITIAL = iota
	PHP
	STRING
	STRING_VAR
	STRING_VAR_INDEX
	STRING_VAR_NAME
	PROPERTY
	HEREDOC_END
	NOWDOC
	HEREDOC
	BACKQUOTE
)

var heredocLabel []lex.Char

func (l *Lexer) Lex(lval Lval) int {
    l.Comments = nil
    c := l.Enter()

%}

%s PHP STRING STRING_VAR STRING_VAR_INDEX STRING_VAR_NAME PROPERTY HEREDOC_END NOWDOC HEREDOC BACKQUOTE

%yyb last == '\n' || last = '\0'
%yyt l.getCurrentState()
%yyc c
%yyn c = l.Next()
%yym l.Mark()
%optioncase-insensitive

LNUM            [0-9]+
DNUM            ([0-9]*"."[0-9]+)|([0-9]+"."[0-9]*)
HNUM            0x[0-9a-fA-F]+
BNUM            0b[01]+
EXPONENT_DNUM   (({LNUM}|{DNUM})[eE][+-]?{LNUM})
VAR_NAME        [a-zA-Z_\x7f-\xff^0-9/][a-zA-Z0-9_\x7f-\xff]*
OPERATORS       [;:,.\[\]()|\/\^&\+-*=%!~$<>?@]
NEW_LINE        (\r|\n|\r\n)

%%
    c = l.Rule0()

<INITIAL>[ \t\n\r]+                             lval.Token(l.newToken(l.Token()));
<INITIAL>.
    tb := []lex.Char{}

    for {
        if c == -1 {
            tb = l.Token();
            break;
        }

        if '?' == rune(c) {
            tb = l.Token();
            if (len(tb) < 2 || tb[len(tb)-1].Rune != '<') {
                c = l.Next()
                continue;
            }

            tb = l.ungetChars(1)
            break;
        }

        c = l.Next()
    }

    lval.Token(l.newToken(tb))
    return T_INLINE_HTML

<INITIAL>\<\?php([ \t]|{NEW_LINE})              l.begin(PHP);lval.Token(l.newToken(l.Token()));// return T_OPEN_TAG;
<INITIAL>\<\?                                   l.begin(PHP);lval.Token(l.newToken(l.Token()));// return T_OPEN_TAG;
<INITIAL>\<\?=                                  l.begin(PHP);lval.Token(l.newToken(l.Token())); return T_ECHO;

<PHP>[ \t\n\r]+                                 lval.Token(l.newToken(l.Token()));// return T_WHITESPACE
<PHP>\?\>{NEW_LINE}?                            l.begin(INITIAL);lval.Token(l.newToken(l.Token())); return Rune2Class(';');

<PHP>{DNUM}|{EXPONENT_DNUM}                     lval.Token(l.newToken(l.Token())); return T_DNUMBER
<PHP>{BNUM}
    tb := l.Token()
    i:=2
    BNUMFOR:for {
        if i > len(tb)-1 {
            break BNUMFOR;
        }
        switch tb[i].Rune {
            case '0': i++;
            default: break BNUMFOR;
        }
    }
    if len(tb) - i < 64 {
        lval.Token(l.newToken(l.Token())); return T_LNUMBER
    } else {
        lval.Token(l.newToken(l.Token())); return T_DNUMBER
    }
<PHP>{LNUM}
    if len(l.Token()) < 20 {
        lval.Token(l.newToken(l.Token())); return T_LNUMBER
    } else {
        lval.Token(l.newToken(l.Token())); return T_DNUMBER
    }
<PHP>{HNUM}
    tb := l.Token()
    i:=2
    HNUMFOR:for {
        if i > len(tb)-1 {
            break HNUMFOR;
        }
        switch tb[i].Rune {
            case '0': i++;
            default: break HNUMFOR;
        }
    }
    length := len(tb) - i
    if length < 16 || (length == 16 && tb[i].Rune <= '7') {
        lval.Token(l.newToken(l.Token())); return T_LNUMBER
    } else {
        lval.Token(l.newToken(l.Token())); return T_DNUMBER
    }

<PHP>abstract                                   lval.Token(l.newToken(l.Token())); return T_ABSTRACT
<PHP>array                                      lval.Token(l.newToken(l.Token())); return T_ARRAY
<PHP>as                                         lval.Token(l.newToken(l.Token())); return T_AS
<PHP>break                                      lval.Token(l.newToken(l.Token())); return T_BREAK
<PHP>callable                                   lval.Token(l.newToken(l.Token())); return T_CALLABLE
<PHP>case                                       lval.Token(l.newToken(l.Token())); return T_CASE
<PHP>catch                                      lval.Token(l.newToken(l.Token())); return T_CATCH
<PHP>class                                      lval.Token(l.newToken(l.Token())); return T_CLASS
<PHP>clone                                      lval.Token(l.newToken(l.Token())); return T_CLONE
<PHP>const                                      lval.Token(l.newToken(l.Token())); return T_CONST
<PHP>continue                                   lval.Token(l.newToken(l.Token())); return T_CONTINUE
<PHP>declare                                    lval.Token(l.newToken(l.Token())); return T_DECLARE
<PHP>default                                    lval.Token(l.newToken(l.Token())); return T_DEFAULT
<PHP>do                                         lval.Token(l.newToken(l.Token())); return T_DO
<PHP>echo                                       lval.Token(l.newToken(l.Token())); return T_ECHO
<PHP>else                                       lval.Token(l.newToken(l.Token())); return T_ELSE
<PHP>elseif                                     lval.Token(l.newToken(l.Token())); return T_ELSEIF
<PHP>empty                                      lval.Token(l.newToken(l.Token())); return T_EMPTY
<PHP>enddeclare                                 lval.Token(l.newToken(l.Token())); return T_ENDDECLARE
<PHP>endfor                                     lval.Token(l.newToken(l.Token())); return T_ENDFOR
<PHP>endforeach                                 lval.Token(l.newToken(l.Token())); return T_ENDFOREACH
<PHP>endif                                      lval.Token(l.newToken(l.Token())); return T_ENDIF
<PHP>endswitch                                  lval.Token(l.newToken(l.Token())); return T_ENDSWITCH
<PHP>endwhile                                   lval.Token(l.newToken(l.Token())); return T_ENDWHILE
<PHP>eval                                       lval.Token(l.newToken(l.Token())); return T_EVAL
<PHP>exit|die                                   lval.Token(l.newToken(l.Token())); return T_EXIT
<PHP>extends                                    lval.Token(l.newToken(l.Token())); return T_EXTENDS
<PHP>final                                      lval.Token(l.newToken(l.Token())); return T_FINAL
<PHP>finally                                    lval.Token(l.newToken(l.Token())); return T_FINALLY
<PHP>for                                        lval.Token(l.newToken(l.Token())); return T_FOR
<PHP>foreach                                    lval.Token(l.newToken(l.Token())); return T_FOREACH
<PHP>function|cfunction                         lval.Token(l.newToken(l.Token())); return T_FUNCTION
<PHP>global                                     lval.Token(l.newToken(l.Token())); return T_GLOBAL
<PHP>goto                                       lval.Token(l.newToken(l.Token())); return T_GOTO
<PHP>if                                         lval.Token(l.newToken(l.Token())); return T_IF
<PHP>isset                                      lval.Token(l.newToken(l.Token())); return T_ISSET
<PHP>implements                                 lval.Token(l.newToken(l.Token())); return T_IMPLEMENTS
<PHP>instanceof                                 lval.Token(l.newToken(l.Token())); return T_INSTANCEOF
<PHP>insteadof                                  lval.Token(l.newToken(l.Token())); return T_INSTEADOF
<PHP>interface                                  lval.Token(l.newToken(l.Token())); return T_INTERFACE
<PHP>list                                       lval.Token(l.newToken(l.Token())); return T_LIST
<PHP>namespace                                  lval.Token(l.newToken(l.Token())); return T_NAMESPACE
<PHP>private                                    lval.Token(l.newToken(l.Token())); return T_PRIVATE
<PHP>public                                     lval.Token(l.newToken(l.Token())); return T_PUBLIC
<PHP>print                                      lval.Token(l.newToken(l.Token())); return T_PRINT
<PHP>protected                                  lval.Token(l.newToken(l.Token())); return T_PROTECTED
<PHP>return                                     lval.Token(l.newToken(l.Token())); return T_RETURN
<PHP>static                                     lval.Token(l.newToken(l.Token())); return T_STATIC
<PHP>switch                                     lval.Token(l.newToken(l.Token())); return T_SWITCH
<PHP>throw                                      lval.Token(l.newToken(l.Token())); return T_THROW
<PHP>trait                                      lval.Token(l.newToken(l.Token())); return T_TRAIT
<PHP>try                                        lval.Token(l.newToken(l.Token())); return T_TRY
<PHP>unset                                      lval.Token(l.newToken(l.Token())); return T_UNSET
<PHP>use                                        lval.Token(l.newToken(l.Token())); return T_USE
<PHP>var                                        lval.Token(l.newToken(l.Token())); return T_VAR
<PHP>while                                      lval.Token(l.newToken(l.Token())); return T_WHILE
<PHP>yield[ \t\n\r]+from[^a-zA-Z0-9_\x80-\xff]  lval.Token(l.newToken(l.Token())); return T_YIELD_FROM
<PHP>yield                                      lval.Token(l.newToken(l.Token())); return T_YIELD
<PHP>include                                    lval.Token(l.newToken(l.Token())); return T_INCLUDE
<PHP>include_once                               lval.Token(l.newToken(l.Token())); return T_INCLUDE_ONCE
<PHP>require                                    lval.Token(l.newToken(l.Token())); return T_REQUIRE
<PHP>require_once                               lval.Token(l.newToken(l.Token())); return T_REQUIRE_ONCE
<PHP>__CLASS__                                  lval.Token(l.newToken(l.Token())); return T_CLASS_C
<PHP>__DIR__                                    lval.Token(l.newToken(l.Token())); return T_DIR
<PHP>__FILE__                                   lval.Token(l.newToken(l.Token())); return T_FILE
<PHP>__FUNCTION__                               lval.Token(l.newToken(l.Token())); return T_FUNC_C
<PHP>__LINE__                                   lval.Token(l.newToken(l.Token())); return T_LINE
<PHP>__NAMESPACE__                              lval.Token(l.newToken(l.Token())); return T_NS_C
<PHP>__METHOD__                                 lval.Token(l.newToken(l.Token())); return T_METHOD_C
<PHP>__TRAIT__                                  lval.Token(l.newToken(l.Token())); return T_TRAIT_C
<PHP>__halt_compiler                            lval.Token(l.newToken(l.Token())); return T_HALT_COMPILER
<PHP>\([ \t]*array[ \t]*\)                      lval.Token(l.newToken(l.Token())); return T_ARRAY_CAST
<PHP>\([ \t]*(bool|boolean)[ \t]*\)             lval.Token(l.newToken(l.Token())); return T_BOOL_CAST
<PHP>\([ \t]*(real|double|float)[ \t]*\)        lval.Token(l.newToken(l.Token())); return T_DOUBLE_CAST
<PHP>\([ \t]*(int|integer)[ \t]*\)              lval.Token(l.newToken(l.Token())); return T_INT_CAST
<PHP>\([ \t]*object[ \t]*\)                     lval.Token(l.newToken(l.Token())); return T_OBJECT_CAST
<PHP>\([ \t]*string[ \t]*\)                     lval.Token(l.newToken(l.Token())); return T_STRING_CAST
<PHP>\([ \t]*unset[ \t]*\)                      lval.Token(l.newToken(l.Token())); return T_UNSET_CAST
<PHP>new                                        lval.Token(l.newToken(l.Token())); return T_NEW
<PHP>and                                        lval.Token(l.newToken(l.Token())); return T_LOGICAL_AND
<PHP>or                                         lval.Token(l.newToken(l.Token())); return T_LOGICAL_OR
<PHP>xor                                        lval.Token(l.newToken(l.Token())); return T_LOGICAL_XOR
<PHP>\\                                         lval.Token(l.newToken(l.Token())); return T_NS_SEPARATOR
<PHP>\.\.\.                                     lval.Token(l.newToken(l.Token())); return T_ELLIPSIS
<PHP>::                                         lval.Token(l.newToken(l.Token())); return T_PAAMAYIM_NEKUDOTAYIM // T_DOUBLE_COLON
<PHP>&&                                         lval.Token(l.newToken(l.Token())); return T_BOOLEAN_AND
<PHP>\|\|                                       lval.Token(l.newToken(l.Token())); return T_BOOLEAN_OR
<PHP>&=                                         lval.Token(l.newToken(l.Token())); return T_AND_EQUAL
<PHP>\|=                                        lval.Token(l.newToken(l.Token())); return T_OR_EQUAL
<PHP>\.=                                        lval.Token(l.newToken(l.Token())); return T_CONCAT_EQUAL
<PHP>\*=                                        lval.Token(l.newToken(l.Token())); return T_MUL_EQUAL
<PHP>\*\*=                                      lval.Token(l.newToken(l.Token())); return T_POW_EQUAL
<PHP>[/]=                                       lval.Token(l.newToken(l.Token())); return T_DIV_EQUAL
<PHP>\+=                                        lval.Token(l.newToken(l.Token())); return T_PLUS_EQUAL
<PHP>-=                                         lval.Token(l.newToken(l.Token())); return T_MINUS_EQUAL
<PHP>\^=                                        lval.Token(l.newToken(l.Token())); return T_XOR_EQUAL
<PHP>%=                                         lval.Token(l.newToken(l.Token())); return T_MOD_EQUAL
<PHP>--                                         lval.Token(l.newToken(l.Token())); return T_DEC
<PHP>\+\+                                       lval.Token(l.newToken(l.Token())); return T_INC
<PHP>=>                                         lval.Token(l.newToken(l.Token())); return T_DOUBLE_ARROW
<PHP>\<=\>                                      lval.Token(l.newToken(l.Token())); return T_SPACESHIP
<PHP>\!=|\<\>                                   lval.Token(l.newToken(l.Token())); return T_IS_NOT_EQUAL
<PHP>\!==                                       lval.Token(l.newToken(l.Token())); return T_IS_NOT_IDENTICAL
<PHP>==                                         lval.Token(l.newToken(l.Token())); return T_IS_EQUAL
<PHP>===                                        lval.Token(l.newToken(l.Token())); return T_IS_IDENTICAL
<PHP>\<\<=                                      lval.Token(l.newToken(l.Token())); return T_SL_EQUAL
<PHP>\>\>=                                      lval.Token(l.newToken(l.Token())); return T_SR_EQUAL
<PHP>\>=                                        lval.Token(l.newToken(l.Token())); return T_IS_GREATER_OR_EQUAL
<PHP>\<=                                        lval.Token(l.newToken(l.Token())); return T_IS_SMALLER_OR_EQUAL
<PHP>\*\*                                       lval.Token(l.newToken(l.Token())); return T_POW
<PHP>\<\<                                       lval.Token(l.newToken(l.Token())); return T_SL
<PHP>\>\>                                       lval.Token(l.newToken(l.Token())); return T_SR
<PHP>\?\?                                       lval.Token(l.newToken(l.Token())); return T_COALESCE
<PHP>(#|[/][/]).*{NEW_LINE}                     lval.Token(l.newToken(l.Token()));// return T_COMMENT; // TODO: handle ?>
<PHP>([/][*])|([/][*][*])
    tb := l.Token()
    is_doc_comment := false
    if len(tb) > 2 {
        is_doc_comment = true
        l.PhpDocComment = ""
    }

    for {
        if c == -1 {
            break; // TODO: Unterminated comment starting line %d
        }

        p := c
        c = l.Next()

        if rune(p) == '*' && rune(c) == '/' {
            c = l.Next()
            break;
        }
    }

    lval.Token(l.newToken(l.Token()))
    if is_doc_comment {
        l.PhpDocComment = string(l.TokenBytes(nil))
        l.addComment(comment.NewDocComment(string(l.TokenBytes(nil))))
        // return T_DOC_COMMENT
    } else {
        l.addComment(comment.NewPlainComment(string(l.TokenBytes(nil))))
        // return T_COMMENT
    }

<PHP>{OPERATORS}                                lval.Token(l.newToken(l.Token())); return Rune2Class(rune(l.TokenBytes(nil)[0]))

<PHP>\{                                         l.pushState(PHP); lval.Token(l.newToken(l.Token())); return Rune2Class(rune(l.TokenBytes(nil)[0]))
<PHP>\}                                         l.popState();     lval.Token(l.newToken(l.Token())); return Rune2Class(rune(l.TokenBytes(nil)[0])); l.PhpDocComment = ""
<PHP>\${VAR_NAME}                               lval.Token(l.newToken(l.Token())); return T_VARIABLE
<PHP>{VAR_NAME}                                 lval.Token(l.newToken(l.Token())); return T_STRING

<PHP>->                                         l.begin(PROPERTY);lval.Token(l.newToken(l.Token())); return T_OBJECT_OPERATOR;
<PROPERTY>[ \t\n\r]+                            lval.Token(l.newToken(l.Token())); // return T_WHITESPACE;
<PROPERTY>->                                    lval.Token(l.newToken(l.Token())); return T_OBJECT_OPERATOR;
<PROPERTY>{VAR_NAME}                            l.begin(PHP);lval.Token(l.newToken(l.Token())); return T_STRING;
<PROPERTY>.                                     l.ungetChars(1);l.begin(PHP)

<PHP>[\']([^\\\']*([\\].)*)*[\']                lval.Token(l.newToken(l.Token())); return T_CONSTANT_ENCAPSED_STRING;

<PHP>`                                          l.begin(BACKQUOTE); lval.Token(l.newToken(l.Token())); return Rune2Class(rune(l.TokenBytes(nil)[0]))
<BACKQUOTE>`                                    l.begin(PHP); lval.Token(l.newToken(l.Token())); return Rune2Class(rune(l.TokenBytes(nil)[0]))

<PHP>[b]?\<\<\<[ \t]*({VAR_NAME}|([']{VAR_NAME}['])|(["]{VAR_NAME}["])){NEW_LINE}
    tb := l.Token()
    binPrefix := 0
    if tb[0].Rune == 'b' {
        binPrefix = 1
    }
    
    lblFirst := 3 + binPrefix
    lblLast := len(tb)-2
    if tb[lblLast].Rune == '\r' {
        lblLast--
    }

    for {
        if tb[lblFirst].Rune == ' ' || tb[lblFirst].Rune == '\t' {
            lblFirst++
            continue
        }

        break
    }

    switch tb[lblFirst].Rune {
        case '\'' : 
            lblFirst++
            lblLast--
            l.begin(NOWDOC)
        case '"' : 
            lblFirst++
            lblLast--
            l.begin(HEREDOC)
        default:
            l.begin(HEREDOC)
    }

    heredocLabel = make([]lex.Char, lblLast - lblFirst + 1)
    copy(heredocLabel, tb[lblFirst:lblLast+1])
    
    ungetCnt := len(heredocLabel)
    searchLabelAhead := []lex.Char{}
    for i := 0; i < len(heredocLabel); i++ {
        if c == -1 {
            break;
        }
        searchLabelAhead = append(searchLabelAhead, l.Lookahead())
        c = l.Next()
    }

    if bytes.Equal(l.charsToBytes(heredocLabel), l.charsToBytes(searchLabelAhead)) && ';' == rune(c) {
        ungetCnt++
        c = l.Next()
        if '\n' == rune(c) || '\r' == rune(c) {
            l.begin(HEREDOC_END)
        }
    }

    l.ungetChars(ungetCnt)

    lval.Token(l.newToken(tb)); 
    return T_START_HEREDOC

<NOWDOC>.|[ \t\n\r]
    searchLabel := []byte{}
    tb := []lex.Char{}
    
    for {
        if c == -1 {
            break;
        }

        if '\n' == rune(c) || '\r' == rune(c) {
            if bytes.Equal(append(l.charsToBytes(heredocLabel), ';'), searchLabel) {
                l.begin(HEREDOC_END)
                tb = l.ungetChars(len(heredocLabel)+1)
                break;
            }

            if bytes.Equal(l.charsToBytes(heredocLabel), searchLabel) {
                l.begin(HEREDOC_END)
                tb = l.ungetChars(len(heredocLabel))
                break;
            }
            
            searchLabel = []byte{}
        } else {
            searchLabel = append(searchLabel, byte(rune(c)))
        }

        c = l.Next()
    }

    lval.Token(l.newToken(tb) )
    return T_ENCAPSED_AND_WHITESPACE

<HEREDOC_END>{VAR_NAME}\;                       l.begin(PHP);lval.Token(l.newToken(l.ungetChars(1))); return T_END_HEREDOC
<HEREDOC_END>{VAR_NAME}                         l.begin(PHP);lval.Token(l.newToken(l.Token())); return T_END_HEREDOC

<PHP>[b]?[\"]
    binPrefix := l.Token()[0].Rune == 'b'

    beginString := func() int {
        cnt := 1; if (binPrefix) {cnt = 2}
        
        l.ungetChars(len(l.Token())-cnt)
        chars := l.Token()[:cnt]
        l.pushState(STRING)

        lval.Token(l.newToken(chars)); return Rune2Class('"')
    }

    F:for {
        if c == -1 {
            break;
        }

        switch c {
            case '"' : 
                c = l.Next();
                lval.Token(l.newToken(l.Token())); return T_CONSTANT_ENCAPSED_STRING
                break F;
            
            case '$':
                c = l.Next();
                if rune(c) == '{' || c >= 'A' && c <= 'Z' || c == '_' || c >= 'a' && c <= 'z' || c >= '\u007f' && c <= 'ÿ' {
                    return beginString()
                    break F;
                } 
                l.ungetChars(0)
            
            case '{':
                c = l.Next();
                if rune(c) == '$' {
                    return beginString()
                    break F;
                } 
                l.ungetChars(0)

            case '\\':
                c = l.Next();
        }

        c = l.Next()
    }

<STRING>\"                                  l.popState(); lval.Token(l.newToken(l.Token())); return Rune2Class(l.Token()[0].Rune)
<STRING,HEREDOC,BACKQUOTE>\{\$              lval.Token(l.newToken(l.ungetChars(1))); l.pushState(PHP); return T_CURLY_OPEN
<STRING,HEREDOC,BACKQUOTE>\$\{              l.pushState(STRING_VAR_NAME); lval.Token(l.newToken(l.Token())); return T_DOLLAR_OPEN_CURLY_BRACES
<STRING,HEREDOC,BACKQUOTE>\$                l.ungetChars(1);l.pushState(STRING_VAR)
<STRING>.|[ \t\n\r]
    F1:for {
        if c == -1 {
            break;
        }

        switch c {
            case '"' : 
                lval.Token(l.newToken(l.Token()));
                return T_ENCAPSED_AND_WHITESPACE
                break F1;
            
            case '$':
                c = l.Next();
                if rune(c) == '{' || c >= 'A' && c <= 'Z' || c == '_' || c >= 'a' && c <= 'z' || c >= '\u007f' && c <= 'ÿ' {
                    l.ungetChars(1)
                    tb := l.Token()
                    lval.Token(l.newToken(tb[:len(tb)-1]));
                    return T_ENCAPSED_AND_WHITESPACE
                    break F1;
                } 
                l.ungetChars(0)
            
            case '{':
                c = l.Next();
                if rune(c) == '$' {
                    l.ungetChars(1)
                    tb := l.Token()
                    lval.Token(l.newToken(tb[:len(tb)-1])); 
                    return T_ENCAPSED_AND_WHITESPACE
                    break F1;
                } 
                l.ungetChars(0)

            case '\\':
                c = l.Next();
        }

        c = l.Next()
    }

<BACKQUOTE>.|[ \t\n\r]
    F2:for {
        if c == -1 {
            break;
        }

        switch c {
            case '`' :
                lval.Token(l.newToken(l.Token())); 
                return T_ENCAPSED_AND_WHITESPACE
                break F2;
            
            case '$':
                c = l.Next();
                if rune(c) == '{' || c >= 'A' && c <= 'Z' || c == '_' || c >= 'a' && c <= 'z' || c >= '\u007f' && c <= 'ÿ' {
                    l.ungetChars(1)
                    tb := l.Token()
                    lval.Token(l.newToken(tb[:len(tb)-1])); 
                    return T_ENCAPSED_AND_WHITESPACE
                    break F2;
                } 
                l.ungetChars(0)
            
            case '{':
                c = l.Next();
                if rune(c) == '$' {
                    l.ungetChars(1)
                    tb := l.Token()
                    lval.Token(l.newToken(tb[:len(tb)-1])); 
                    return T_ENCAPSED_AND_WHITESPACE
                    break F2;
                } 
                l.ungetChars(0)

            case '\\':
                c = l.Next();
        }

        c = l.Next()
    }

<HEREDOC>.|[ \t\n\r]
    searchLabel := []byte{}
    tb := []lex.Char{}
    
    HEREDOCFOR:for {
        if c == -1 {
            break;
        }

        switch c {
            case '\n': fallthrough
            case '\r':
                if bytes.Equal(append(l.charsToBytes(heredocLabel), ';'), searchLabel) { 
                    l.begin(HEREDOC_END)
                    tb = l.ungetChars(len(heredocLabel)+1)
                    break HEREDOCFOR;
                }

                if bytes.Equal(l.charsToBytes(heredocLabel), searchLabel) { 
                    l.begin(HEREDOC_END)
                    tb = l.ungetChars(len(heredocLabel))
                    break HEREDOCFOR;
                }
                
                searchLabel = []byte{}
            
            case '$':
                c = l.Next();
                if rune(c) == '{' || c >= 'A' && c <= 'Z' || c == '_' || c >= 'a' && c <= 'z' || c >= '\u007f' && c <= 'ÿ' {
                    tb = l.ungetChars(1)
                    break HEREDOCFOR;
                } 
                l.ungetChars(0)
                searchLabel = []byte{}
            
            case '{':
                c = l.Next();
                if rune(c) == '$' {
                    tb = l.ungetChars(1)
                    break HEREDOCFOR;
                } 
                l.ungetChars(0)
                searchLabel = []byte{}

            case '\\':
                c = l.Next();
                searchLabel = []byte{}
            
            default:
                searchLabel = append(searchLabel, byte(rune(c)))
        }

        c = l.Next()
    }
    
    lval.Token(l.newToken(tb)); 
    return T_ENCAPSED_AND_WHITESPACE

<STRING_VAR>\${VAR_NAME}                    lval.Token(l.newToken(l.Token())); return T_VARIABLE
<STRING_VAR>->{VAR_NAME}                    lval.Token(l.newToken(l.ungetChars(len(l.Token())-2))); return T_OBJECT_OPERATOR
<STRING_VAR>{VAR_NAME}                      l.popState();lval.Token(l.newToken(l.Token())); return T_STRING
<STRING_VAR>\[                              l.pushState(STRING_VAR_INDEX);lval.Token(l.newToken(l.Token())); return Rune2Class(rune(l.TokenBytes(nil)[0]))
<STRING_VAR>.|[ \t\n\r]                     l.ungetChars(1);l.popState()

<STRING_VAR_INDEX>{LNUM}|{HNUM}|{BNUM}      lval.Token(l.newToken(l.Token())); return T_NUM_STRING
<STRING_VAR_INDEX>\${VAR_NAME}              lval.Token(l.newToken(l.Token())); return T_VARIABLE
<STRING_VAR_INDEX>{VAR_NAME}                lval.Token(l.newToken(l.Token())); return T_STRING
<STRING_VAR_INDEX>\]                        l.popState(); l.popState();lval.Token(l.newToken(l.Token())); return Rune2Class(rune(l.TokenBytes(nil)[0]))
<STRING_VAR_INDEX>[ \n\r\t\\'#]             l.popState(); l.popState();lval.Token(l.newToken(l.Token())); return T_ENCAPSED_AND_WHITESPACE
<STRING_VAR_INDEX>{OPERATORS}               lval.Token(l.newToken(l.Token())); return Rune2Class(rune(l.TokenBytes(nil)[0]))
<STRING_VAR_INDEX>.                         lval.Token(l.newToken(l.Token())); return Rune2Class(rune(l.TokenBytes(nil)[0]))

<STRING_VAR_NAME>{VAR_NAME}[\[\}]           l.popState();l.pushState(PHP);lval.Token(l.newToken(l.ungetChars(1))); return T_STRING_VARNAME
<STRING_VAR_NAME>.                          l.ungetChars(1);l.popState();l.pushState(PHP)

%%
    if c, ok := l.Abort(); ok { return int(c) }
    goto yyAction
}