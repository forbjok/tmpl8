module tmpl8.parsers.env;

import std.process : environment;

import tmpl8.parser : Parser;
import tmpl8.interfaces : IParser;

class EnvParser : IParser {
    static this() {
        Parser.register("env", new typeof(this)());
    }

    /// Return environment variables
    string[string] parse(string[string] parameters, const ubyte[] data) {
        return environment.toAA();
    }
}
