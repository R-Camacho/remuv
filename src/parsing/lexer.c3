module remuv::lexer;

import std::io;
import std::io::file;
import std::collections;
import std::core::ascii;

import remuv::instructions;

enum TokenKind
{
    EOF,

    INSTRUCTION,
    REGISTER,
    IMMEDIATE,
    LABEL,

    COMMA,
    COLON,
    OPEN_PAREN,
    CLOSE_PAREN,
}

struct Token
{
    TokenKind kind;
    String lexeme;
}

fn void Token.debug(Token* t)
{
    io::printfn("%s(%s)", t.kind, t.lexeme);
}

struct Lexer
{
    String src;
    List {Token} tokens;
    usz current;
    usz line;
}

fn void Lexer.init(Lexer* l, String src) 
{
    l.src = src;
    l.tokens.init(mem);
    l.current = 0;
    l.line = 1;
    return;
}

fn void Lexer.free(Lexer* l)
{
    l.tokens.free();
}


fn Token Lexer.next(Lexer* l)
{
    for (;;) {
        char c = l.peek();

        if (c == '\0')
        {
            return {EOF, ""};
        }

        if (c.is_blank())
        {
            l.advance();
            continue;
        }

        if (c == '\n')
        {
            l.advance();
            l.line++;
            continue;
        }
        
        // TODO: support hexadecimal and binary in the future (with 0x and 0b)
        if (c.is_digit())
        {
            return l.number();
        }

        if (c.is_alpha())
        {
            return l.identifier();
        }

        switch (c)
        {
            case '#':
                // Single line comment
                l.skip_line();
                break;
            case '/':
                l.advance();
                char next = l.peek();
                if (next == '/')
                {
                    // Single line comment
                    l.advance();
                    l.skip_line();
                    break;
                } 
                else if (next == '*')
                {
                    // Multi line comment
                    l.advance();
                    for (;;)
                    {
                        l.advance();
                        char c1 = l.peek();

                        if (c1 == '\0') 
                        {
                            // TODO: this may not need an error
                            lex_error(l.line, "Unclosed multi-line comment");
                            return { EOF, "" };
                        }
                        if (c1 == '*')
                        {
                            l.advance();
                            char c2 = l.peek();
                            if (c2 == '/')
                            {
                                l.advance();
                                break;
                            }
                        }
                    }
                    continue;
                }
                else
                {
                    lex_error(l.line, "Unexpected character '/'");
                    return {};
                }
            case ',':
                l.advance();
                return {COMMA, ""};
            case ':':
                l.advance();
                return {COLON, ""};
            case '(':
                l.advance();
                return {OPEN_PAREN, ""};
            case ')':
                l.advance();
                return {CLOSE_PAREN, ""};
            default:
                // FIXME: lex_error for single characters
                l.advance();
                lex_error(l.line, "Unexpected character '%c'", c);
                return {};
        }
    }
}

fn void run_prompt()
{
    for (;;)
    {
        io::print("> ");
        String line = io::treadline()!!;
        if (line.len == 0) break;
        Lexer l = {};
        l.init(line);

        Token token = l.next();
        while (token.kind != EOF)
        {
            token.debug(); 
            token = l.next();
        }
    }
}

fn Token Lexer.number(Lexer* l)
{
    usz start = l.current;

    while (ascii::is_digit(l.peek()))
    {
        l.advance();
    }
    
    return {IMMEDIATE, l.src[start .. l.current - 1]};
}

fn Token Lexer.identifier(Lexer* l)
{
    usz start = l.current;
    
    char c = l.peek();
    while (ascii::is_alnum(c) || c == '_')
    {
        l.advance(); 
        c = l.peek();
    }

    String slice = l.src[start .. l.current - 1];

    // TODO: labels can also start with numbers, needs refactor
    if (c == ':')
    {
        l.advance();
        return {LABEL, slice};
    }

    // TODO: check if identifier is an instruction 

    return {INSTRUCTION, slice};
}

// A few helper functions

fn void Lexer.advance(Lexer* l)
{
    l.current++;
}

fn char Lexer.peek(Lexer* l)
{
    if (l.current >= l.src.len)
    {
        return '\0';
}
    return l.src[l.current];
}

fn void Lexer.skip_line(Lexer* l)
{
    while (l.peek() != '\n' && l.peek() != '\0') {
        l.advance();
    }
}

fn void lex_error(usz line, String fmt, args...)
{
    io::eprintf("On line %d: ", line);
    io::eprintfn(fmt, args);
}

