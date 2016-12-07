module cli.commands.generate;

import std.getopt : getopt;
import std.path : getcwd;
import std.stdio : stderr, writefln, writeln;

import cli.command : ICommand, registerCommand;
import tmpl8.services.filelocator : FileLocator;
import tmpl8.services.tmpl8service : Tmpl8Service;

private const tmpl8ConfigFilename = "tmpl8.json";

class GenerateCommand : ICommand {
    static this() {
        auto instance = new this();

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
            auto fileLocator = new FileLocator();
            auto configFile = fileLocator.locateFileInPathOrParent(getcwd(), tmpl8ConfigFilename);

            writeln("Config file found: ", configFile);

            auto tmpl8Service = new Tmpl8Service();
            tmpl8Service.generate(configFile);

            return 0;
        }
        catch (Exception ex) {
            stderr.writeln(ex.msg);
            return 1;
        }
    }
}
