module cli.commands.get;

static import std.getopt;

import std.path : getcwd;
import std.stdio : stderr, stdout;
import std.string : replace;

import dyaml.stream : YStream;
import jsonserialized.serialization : serializeToJSONValue;
import stdx.data.json : toJSON;
import yaml : Dumper;
import yamlserialized : toYAMLNode;

import cli.command : ICommand, registerCommand;
import tmpl8.services.tmpl8service : Tmpl8Service;

/// dyaml YStream implementation for writing to stdout
class YStdOut : YStream {
	void writeExact(const void* buffer, size_t size) {
		stdout.write(cast(const char[]) buffer[0 .. size]);
	}

	size_t write(const(ubyte)[] buffer) {
		stdout.write(cast(const char[]) buffer);
		return buffer.length;
	}

	void flush() {
		stdout.flush();
	}

	@property bool writeable() { return true; }
}

class GetCommand : ICommand {
    static this() {
        registerCommand("get", new this());
    }

    private void writeUsage(in string command) {
        stderr.writefln("Usage: tmpl8 %s <FORMAT>", command);
        stderr.writeln("Supported formats: json, yaml");
    }

    int Execute(string[] args) {
        try {
            // Parse arguments
            auto getoptResult = std.getopt.getopt(args, std.getopt.config.passThrough);

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

        // Make sure a format was specified
        if (args.length < 2) {
            stderr.writeln("No format specified.");
            writeUsage(args[0]);

            return 1;
        }

        // Get format
        auto format = args[1];

        try {
            switch (format) {
                case "json":
                    auto vars = getVariables();
                    auto json = vars.serializeToJSONValue().toJSON();

                    /* Replace tabs with two spaces for niceness */
                    json = json.replace("\t", "  ");

                    stdout.writeln(json);
                    break;
                case "yaml":
                    auto vars = getVariables();
                    auto node = vars.toYAMLNode();

                    auto dumper = Dumper(new YStdOut());
                    dumper.dump(node);
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
