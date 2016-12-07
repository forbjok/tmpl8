import std.stdio : writeln;
import std.file : chdir, getcwd, readText;
import std.path : baseName, dirName, stripExtension;

import jsonserialized.deserialization : deserializeFromJSONValue;
import stdx.data.json : toJSONValue;

import tmpl8.config : Config;
import tmpl8.input : Input;
import tmpl8.parser : Parser;
import tmpl8.services.filelocator : FileLocator;
import tmpl8.services.commandtransformer : CommandTransformer;
import tmpl8.services.templateprocessor : TemplateProcessor;

int main(string[] args)
{
    auto fileLocator = new FileLocator();
    auto configFile = fileLocator.locateFileInPathOrParent(getcwd(), "tmpl8.json");

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

        /* Copy all variables from source, unless excludeUnmapped is true */
        if (!source.excludeUnmapped) {
            foreach(var; curVars.byKeyValue()) {
                vars[var.key] = var.value;
            }
        }

        /* Copy mappings */
        foreach(mapping; source.mappings.byKeyValue()) {
            vars[mapping.key] = curVars.get(mapping.value, "");
        }
    }

    auto commandTransformer = new CommandTransformer();
    foreach(tf; cfg.transforms) {
        auto inValue = vars.get(tf.inVariable, "");

        auto outValue = commandTransformer.transform(
            tf.command,
            inValue);

        vars[tf.outVariable] = outValue;
    }

    /* Process templates */
    auto templateProcessor = new TemplateProcessor();

    foreach(tmpItem; cfg.templates.byKeyValue()) {
        auto pattern = tmpItem.key;
        auto tmp = tmpItem.value;

        // Locate all matching templates withing the root directory
        auto templateFiles = fileLocator.locateTemplates(rootPath, pattern);

        foreach(string templateFile; templateFiles) {
            // Get output filename by stripping the template extension
            auto outputFile = templateFile.stripExtension();

            auto templateFilename = templateFile.baseName();
            writeln("Processing template: ", templateFilename);

            // Process the template
            templateProcessor.processTemplate(templateFile, outputFile, vars);
        }
    }

    foreach(var; vars.byKeyValue()) {
        auto key = var.key;
        auto value = var.value;

        writeln(key, " = ", value);
    }

    return 0;
}
