module tmpl8.parsers.json;

import jsonserialized.deserialization : deserializeFromJSONValue;
import stdx.data.json : toJSONValue;

import tmpl8.parser : Parser;
import tmpl8.interfaces : IParser;

class JsonParser : IParser {
    static this() {
        Parser.register("json", new this());
    }

    /// Parse a UTF-8 encoded byte array of JSON into variables
    string[string] parse(string[string] parameters, const ubyte[] data) {
        auto json = cast(string) data;

        string[string] vars;

        if (data.length == 0)
            return vars;

        vars.deserializeFromJSONValue(json.toJSONValue);

        return vars;
    }
}
