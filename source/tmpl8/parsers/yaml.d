module tmpl8.parsers.yaml;

import yamlserialized.deserialization : deserializeInto;
import yaml : Loader;

import tmpl8.parser : Parser;
import tmpl8.interfaces : IParser;

class YamlParser : IParser {
    static this() {
        Parser.register("yaml", new this());
    }

    /// Parse a UTF-8 encoded byte array of YAML into variables
    string[string] parse(string[string] parameters, const ubyte[] data) {
        auto yaml = cast(char[]) data;

        string[string] vars;

        if (data.length == 0)
            return vars;

        auto node = Loader.fromString(yaml).load();
        node.deserializeInto(vars);

        return vars;
    }
}
