module tmpl8.parsers.value;

import std.conv : to;
import std.string : empty;

import tmpl8.parser : Parser;
import tmpl8.interfaces : IParser;
import tmpl8.utils.encoding : decode;

class ValueParser : IParser {
    static this() {
        Parser.register("value", new this());
    }

    /// Parse a UTF-8 encoded byte array of JSON into variables
    string[string] parse(string[string] parameters, const ubyte[] data) {
        /* Get encoding name, or default to UTF-8 if none is specified. */
        auto encodingName = parameters.get("encoding", "utf-8");

        auto key = parameters.get("outVariable", "");

        /* Decode input data to string */
        auto stringData = decode(data, encodingName).to!string;

        if (key.empty) {
            throw new Exception("No output variable specified for value parser with input: " ~ stringData);
        }

        string[string] vars;
        vars[key] = stringData;

        return vars;
    }
}
