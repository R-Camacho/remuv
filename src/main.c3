module remuv;

import std::io;

import remuv::lexer;

fn int main(String[] args)
{
    if (args.len == 1)
    {
        // This only serves to test the lexer
        lexer::run_prompt();
    }
    else if (args.len == 2)
    {
        String? src = (String)file::load_temp(args[1]);
        if (catch err = src)
        {
            io::printfn("Could not open file %s: %s", args[1], err);
            return 1;
        }
        Lexer l = {};
        l.init(src);
        defer l.free();
        
        l.lex_file();
        l.print_tokens();
    }
    else 
    {
        io::printn("Usage: remuv [file]");
        return 1;
    }

	return 0;
}
