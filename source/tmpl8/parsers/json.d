module tmpl8.parsers.json;

import jsonserialized.deserialization : deserializeFromJSONValue;
import stdx.data.json : toJSONValue;

import tmpl8.parser : Parser;
import tmpl8.interfaces : IParser;
import tmpl8.utils.encoding : decode;

class JsonParser : IParser {
    static this() {
        Parser.register("json", new typeof(this)());
    }

    /// Parse a UTF-8 encoded byte array of JSON into variables
    string[string] parse(string[string] parameters, const ubyte[] data) {
        /* Get encoding name, or default to UTF-8 if none is specified. */
        auto encodingName = parameters.get("encoding", "utf-8");

        /* Decode input data to string */
        auto json = decode(data, encodingName);

        string[string] vars;

        if (data.length == 0)
            return vars;

        vars.deserializeFromJSONValue(json.toJSONValue);

        return vars;
    }
}
