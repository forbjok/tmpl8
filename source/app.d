static import std.getopt;

import std.algorithm : until;
import std.array : array;
import std.path : baseName;
import std.range : chain, takeExactly;
import std.stdio : stderr, writefln;
import std.string : startsWith;

import cli.command : getCommand;

int main(string[] args)
{
    bool versionWanted = false;

    try {
        /* Concatenate the executable path with all subsequent arguments up to
           the first one that does not start with optionChar. (normally "-")

           This is required to prevent getopt from parsing options that are
           intended for the command. */
        auto options = chain(args.takeExactly(1), args[1..$].until!(a => !a.startsWith(std.getopt.optionChar))).array();

        // Parse arguments
        auto getoptResult = std.getopt.getopt(options,
            std.getopt.config.bundling,
            "version", &versionWanted);

        if (getoptResult.helpWanted) {
            // If user wants help, give it to them
            writeUsage(args[0]);
            return 0;
        }
    }
    catch(Exception ex) {
        // If there is an error parsing arguments, print it
        stderr.writeln(ex.msg);
        return 1;
    }

    if (versionWanted) {
        writefln("Tmpl8 version %s", import("VERSION"));
        return 0;
    }

    if (args.length == 1) {
        stderr.writeln("No command specified.");
        writeUsage(args[0]);
        return 1;
    }

    // Get command
    auto command = args[1];

    auto commandImplementation = getCommand(command);
    if (commandImplementation is null) {
        stderr.writefln("Unknown command: %s.", command);
        writeUsage(args[0]);
        return 1;
    }

    return commandImplementation.Execute(args[1..$]);
}

void writeUsage(in string executable) {
    stderr.writefln("Usage: %s <generate|get> [--help] [...]", executable.baseName());
}
