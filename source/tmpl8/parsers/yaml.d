module tmpl8.parsers.yaml;

import std.conv : to;

import yamlserialized : deserializeInto;
import dyaml : Loader;

import tmpl8.parser : Parser;
import tmpl8.interfaces : IParser;
import tmpl8.utils.encoding : decode;

class YamlParser : IParser {
    static this() {
        Parser.register("yaml", new typeof(this)());
    }

    /// Parse a UTF-8 encoded byte array of YAML into variables
    string[string] parse(string[string] parameters, const ubyte[] data) {
        /* Get encoding name, or default to UTF-8 if none is specified. */
        auto encodingName = parameters.get("encoding", "utf-8");

        /* Decode input data to string */
        auto yaml = decode(data, encodingName);

        string[string] vars;

        if (data.length == 0)
            return vars;

        auto node = Loader.fromString(yaml.to!(char[])).load();
        node.deserializeInto(vars);

        return vars;
    }
}
