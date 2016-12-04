import std.stdio : writeln;
import std.file : getcwd, readText;

import jsonserialized.deserialization : deserializeFromJSONValue;
import stdx.data.json : toJSONValue;

import tmpl8.config : Config;
import tmpl8.input : Input;
import tmpl8.parser : Parser;
import tmpl8.services.filelocator : FileLocator;

int main(string[] args)
{
    auto loc = new FileLocator();
    auto fileFound = loc.locateFileInPathOrParent(getcwd(), "tmpl8.json");

    writeln("File found: ", fileFound);

    Config cfg;
    string configText = readText(fileFound);
    auto configJsonValue = configText.toJSONValue;
    cfg.deserializeFromJSONValue(configJsonValue);

    string[string] vars;

    foreach(source; cfg.sources) {
        auto input = Input.get(source.input);
        auto parser = Parser.get(source.parser);

        if (input is null) {
            throw new Exception("Input not found.");
        }

        if (parser is null) {
            throw new Exception("Parser not found.");
        }

        auto curVars = parser.parse(source.parserParameters, input.getData(source.inputParameters));

        foreach(var; curVars.byKeyValue()) {
            auto mapTo = source.mappings.get(var.key, null);

            if (source.excludeUnmapped && mapTo is null)
                continue;

            if (mapTo is null)
                mapTo = var.key;

            vars[mapTo] = var.value;
        }
    }

    foreach(var; vars.byKeyValue()) {
        auto key = var.key;
        auto value = var.value;

        writeln(key, " = ", value);
    }

    return 0;
}
