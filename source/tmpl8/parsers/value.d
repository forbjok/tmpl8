module tmpl8.parsers.value;

import tmpl8.parser : Parser;
import tmpl8.interfaces : IParser;

class ValueParser : IParser {
    static this() {
        Parser.register("value", new this());
    }

    /// Parse a UTF-8 encoded byte array of JSON into variables
    string[string] parse(string[string] parameters, const ubyte[] data) {
        auto key = parameters.get("key", "");
        auto stringData = cast(string) data;

        string[string] vars;
        vars[key] = stringData;

        return vars;
    }
}
