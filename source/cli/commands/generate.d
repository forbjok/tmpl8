module cli.commands.generate;

import std.file : getcwd;
import std.getopt : getopt;
import std.stdio : stderr, writefln, writeln;

import cli.command : ICommand, registerCommand;
import tmpl8.services.tmpl8service : Tmpl8Service;

class GenerateCommand : ICommand {
    static this() {
        auto instance = new typeof(this)();

        registerCommand("generate", instance);
        registerCommand("gen", instance);
    }

    private void writeUsage(in string command) {
        stderr.writefln("Usage: tmpl8 %s", command);
    }

    int Execute(string[] args) {
        try {
            // Parse arguments
            auto getoptResult = getopt(args);

            if (getoptResult.helpWanted) {
                // If user wants help, give it to them
                writeUsage(args[0]);
                return 1;
            }
        }
        catch (Exception ex) {
            // If there is an error parsing arguments, print it
            stderr.writeln(ex.msg);
            return 1;
        }

        try {
            auto tmpl8Service = new Tmpl8Service(getcwd());
            tmpl8Service.generate();

            return 0;
        }
        catch (Exception ex) {
            stderr.writeln(ex.msg);
            return 1;
        }
    }
}
