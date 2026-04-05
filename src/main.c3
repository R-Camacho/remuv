module remuv;

import std::io;

import remuv::lexer;

fn int main(String[] args)
{
    if (args.len != 2)
    {
        io::printn("Need to pass the file as a command line argument");
        return 1;
    }

    String? src = (String)file::load_temp(args[1]);
    if (catch err = src)
    {
        io::printfn("Could not open file %s: %s", args[1], err);
        return 1;
    }

    Lexer l = {};
    l.init(src);
    defer l.free();

    // This only serves to test the lexer
    lexer::run_prompt();
	return 0;
}
