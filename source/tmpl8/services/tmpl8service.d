module tmpl8.services.tmpl8service;

import std.stdio : writeln;
import std.file : chdir, readText;
import std.path : baseName, buildPath, dirName, relativePath, stripExtension;

import jsonserialized.deserialization : deserializeFromJSONValue;
import stdx.data.json : toJSONValue;

import tmpl8.config : Config;
import tmpl8.input : Input;
import tmpl8.parser : Parser;
import tmpl8.services.filelocator : FileLocator;
import tmpl8.services.commandtransformer : CommandTransformer;
import tmpl8.services.templateprocessor : TemplateProcessor;

class Tmpl8Service {
    void generate(in string configFilePath) {
        auto rootPath = configFilePath.dirName();

        Config cfg;
        string configText = readText(configFilePath);
        auto configJsonValue = configText.toJSONValue;
        cfg.deserializeFromJSONValue(configJsonValue);

        /* Change current working directory to config root path.
        This is necessary to ensure that any executables executed by the
        config can be found in a path relative to the config regardless
        of which subdirectory the generation is run from. */
        chdir(rootPath);

        string[string] vars;

        writeln("Harvesting variables...");

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

        writeln("Executing transforms...");

        auto commandTransformer = new CommandTransformer();
        foreach(tf; cfg.transforms) {
            auto inValue = vars.get(tf.inVariable, "");

            auto outValue = commandTransformer.transform(
                tf.command,
                inValue);

            vars[tf.outVariable] = outValue;
        }

        string[] ignoreFiles;

        /* Process templates */
        auto templateProcessor = new TemplateProcessor();

        foreach(tmpItem; cfg.templates.byKeyValue()) {
            auto pattern = tmpItem.key;
            auto tmp = tmpItem.value;

            // Locate all matching templates withing the root directory
            auto fileLocator = new FileLocator();
            auto templateFiles = fileLocator.locateTemplates(rootPath, pattern);

            foreach(string templateFile; templateFiles) {
                // Get output filename by stripping the template extension
                auto outputFile = templateFile.stripExtension();

                auto relativeTemplatePath = relativePath(outputFile, rootPath);
                writeln("Processing template: ", relativeTemplatePath);

                // Process the template
                templateProcessor.processTemplate(templateFile, outputFile, vars);

                // Add to list of files to ignore
                ignoreFiles ~= relativeTemplatePath;
            }
        }

        if (cfg.updateGitIgnore.length > 0) {
            writeln("Updating .gitignore file: ", cfg.updateGitIgnore);

            import tmpl8.services.gitignoreupdater : GitIgnoreUpdater;
            auto gitIgnoreUpdater = new GitIgnoreUpdater();

            gitIgnoreUpdater.updateGitIgnore(buildPath(rootPath, cfg.updateGitIgnore), ignoreFiles);
        }

        foreach(var; vars.byKeyValue()) {
            auto key = var.key;
            auto value = var.value;

            writeln(key, " = ", value);
        }
    }
}
