module cli.commands.get;

static import std.getopt;
import std.path : getcwd;
import std.stdio : stderr, stdout;
import std.string : replace;

import jsonserialized.serialization : serializeToJSONValue;
import stdx.data.json : toJSON;

import cli.command : ICommand, registerCommand;
import tmpl8.services.tmpl8service : Tmpl8Service;

class GetCommand : ICommand {
    static this() {
        registerCommand("get", new this());
    }

    private void writeUsage(in string command) {
        stderr.writefln("Usage: tmpl8 %s [--format=<FORMAT>]", command);
        stderr.writeln("Supported formats: json");
    }

    int Execute(string[] args) {
        string format;

        try {
            // Parse arguments
            auto getoptResult = std.getopt.getopt(args,
                std.getopt.config.bundling,
                "f|format", &format);

            if (getoptResult.helpWanted) {
                // If user wants help, give it to them
                writeUsage(args[0]);
                return 1;
            }
        }
        catch(Exception ex) {
            // If there is an error parsing arguments, print it
            stderr.writeln(ex.msg);
            return 1;
        }

        if (format.length == 0) {
            stderr.writeln("No format specified.");
            writeUsage(args[0]);

            return 1;
        }

        try {
            switch (format) {
                case "json":
                    auto vars = getVariables();
                    auto json = vars.serializeToJSONValue().toJSON();

                    /* Replace tabs with two spaces for niceness */
                    json = json.replace("\t", "  ");

                    stdout.writeln(json);
                    break;
                default:
                    throw new Exception("Unsupported format: " ~ format);
            }

            return 0;
        }
        catch(Exception ex) {
            stderr.writeln(ex.msg);
            return 1;
        }
    }

    private string[string] getVariables() {
        auto tmpl8Service = new Tmpl8Service(getcwd());

        auto vars = tmpl8Service.harvestVariables();
        return vars;
    }
}
