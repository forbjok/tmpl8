import std.stdio : writeln;
import std.file : chdir, getcwd, readText;
import std.path : dirName;

import jsonserialized.deserialization : deserializeFromJSONValue;
import stdx.data.json : toJSONValue;

import tmpl8.config : Config;
import tmpl8.input : Input;
import tmpl8.parser : Parser;
import tmpl8.services.filelocator : FileLocator;
import tmpl8.services.commandtransformer : CommandTransformer;

int main(string[] args)
{
    auto loc = new FileLocator();
    auto configFile = loc.locateFileInPathOrParent(getcwd(), "tmpl8.json");

    auto rootPath = configFile.dirName();
    writeln("Config file found: ", configFile);

    Config cfg;
    string configText = readText(configFile);
    auto configJsonValue = configText.toJSONValue;
    cfg.deserializeFromJSONValue(configJsonValue);

    /* Change current working directory to config root path.
       This is necessary to ensure that any executables executed by the
       config can be found in a path relative to the config regardless
       of which subdirectory the generation is run from. */
    chdir(rootPath);

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

    auto commandTransformer = new CommandTransformer();
    foreach(tf; cfg.transforms) {
        auto outValue = commandTransformer.transform(
            tf.command,
            vars[tf.inVariable]);

        vars[tf.outVariable] = outValue;
    }

    foreach(var; vars.byKeyValue()) {
        auto key = var.key;
        auto value = var.value;

        writeln(key, " = ", value);
    }

    return 0;
}
