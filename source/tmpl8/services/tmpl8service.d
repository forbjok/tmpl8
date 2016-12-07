module tmpl8.services.tmpl8service;

import std.stdio : stderr;
import std.file : chdir, readText;
import std.path : baseName, buildPath, dirName, getcwd, relativePath, stripExtension;

import jsonserialized.deserialization : deserializeFromJSONValue;
import stdx.data.json : toJSONValue;

import tmpl8.config : Config;
import tmpl8.input : Input;
import tmpl8.parser : Parser;
import tmpl8.services.filelocator : FileLocator;
import tmpl8.services.commandtransformer : CommandTransformer;
import tmpl8.services.templateprocessor : TemplateProcessor;

private const tmpl8ConfigFilename = "tmpl8.json";

class Tmpl8Service {
    private {
        string _configFilePath;
        string _rootPath;
        Config _config;
    }

    this(in string path) {
        auto fileLocator = new FileLocator();

        _configFilePath = fileLocator.locateFileInPathOrParent(path, tmpl8ConfigFilename);
        _rootPath = _configFilePath.dirName();

        stderr.writeln("Config file found: ", _configFilePath);

        // Attempt to load config
        loadConfig();
    }

    private void loadConfig() {
        string configText = readText(_configFilePath);

        auto configJsonValue = configText.toJSONValue;
        _config.deserializeFromJSONValue(configJsonValue);
    }

    string[string] harvestVariables() {
        // Store current working directory
        auto originalCwd = getcwd();

        // Set current directory back to original upon exiting this function
        scope(exit) chdir(originalCwd);

        /* Change current working directory to config root path.
        This is necessary to ensure that any executables executed by the
        config can be found in a path relative to the config regardless
        of which subdirectory the generation is run from. */
        chdir(_rootPath);

        string[string] vars;

        stderr.writeln("Harvesting variables...");

        foreach(source; _config.sources) {
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

        stderr.writeln("Executing transforms...");

        auto commandTransformer = new CommandTransformer();
        foreach(tf; _config.transforms) {
            auto inValue = vars.get(tf.inVariable, "");

            auto outValue = commandTransformer.transform(
                tf.command,
                inValue);

            vars[tf.outVariable] = outValue;
        }

        return vars;
    }

    void generate() {
        // Harvest variables
        auto vars = harvestVariables();

        string[] ignoreFiles;

        /* Process templates */
        auto templateProcessor = new TemplateProcessor();

        foreach(tmpItem; _config.templates.byKeyValue()) {
            auto pattern = tmpItem.key;
            auto tmp = tmpItem.value;

            // Locate all matching templates withing the root directory
            auto fileLocator = new FileLocator();
            auto templateFiles = fileLocator.locateTemplates(_rootPath, pattern);

            foreach(string templateFile; templateFiles) {
                // Get output filename by stripping the template extension
                auto outputFile = templateFile.stripExtension();

                auto relativeTemplatePath = relativePath(outputFile, _rootPath);
                stderr.writeln("Processing template: ", relativeTemplatePath);

                // Process the template
                templateProcessor.processTemplate(templateFile, outputFile, vars);

                // Add to list of files to ignore
                ignoreFiles ~= relativeTemplatePath;
            }
        }

        if (_config.updateGitIgnore.length > 0) {
            stderr.writeln("Updating .gitignore file: ", _config.updateGitIgnore);

            import tmpl8.services.gitignoreupdater : GitIgnoreUpdater;
            auto gitIgnoreUpdater = new GitIgnoreUpdater();

            gitIgnoreUpdater.updateGitIgnore(buildPath(_rootPath, _config.updateGitIgnore), ignoreFiles);
        }
    }
}
