module tmpl8.services.tmpl8service;

import std.algorithm : map, setDifference;
import std.array : array, empty;
import std.stdio : stderr;
import std.file : chdir, readText;
import std.path : baseName, buildPath, dirName, extension, getcwd, relativePath, stripExtension;

import jsonserialized.deserialization : deserializeFromJSONValue;
import stdx.data.json : toJSONValue;

import yaml : Loader;
import yamlserialized.deserialization : deserializeInto;

import tmpl8.config : Config;
import tmpl8.input : Input;
import tmpl8.parser : Parser;
import tmpl8.services.filelocator : FileLocator;
import tmpl8.services.commandtransformer : CommandTransformer;
import tmpl8.services.templateprocessor : TemplateProcessor;

private const tmpl8ConfigFilenames = ["tmpl8.yml", "tmpl8.json"];

class Tmpl8Service {
    private {
        struct UpdateGitIgnore {
            string gitIgnore;
            string[] ignoreFiles;

            this(string gitIgnore, string[] ignoreFiles) {
                this.gitIgnore = gitIgnore;
                this.ignoreFiles = ignoreFiles;
            }
        }

        string _configFilePath;
        string _rootPath;
        Config _config;
    }

    this(in string path) {
        auto fileLocator = new FileLocator();

        foreach(configFileName; tmpl8ConfigFilenames) {
            _configFilePath = fileLocator.locateFileInPathOrParent(path, configFileName);

            /* If a configuration file was found, break out of loop */
            if (_configFilePath.length != 0)
                break;
        }

        if (_configFilePath.length == 0)
            throw new Exception("No config file found!");

        _rootPath = _configFilePath.dirName();

        stderr.writeln("Config file found: ", _configFilePath);

        // Attempt to load config
        loadConfig();
    }

    private void loadConfig() {

        auto configFileExtension = _configFilePath.extension();
        switch (configFileExtension) {
            case ".yml":
                /* Load YAML file and deserialize it into _config */
                auto node = Loader(_configFilePath).load();
                node.deserializeInto(_config);
                break;
            case ".json":
                /* Load JSON file and deserialize it into _config */
                string configText = readText(_configFilePath);
                auto configJsonValue = configText.toJSONValue;
                _config.deserializeFromJSONValue(configJsonValue);
                break;
            default:
                throw new Exception("Unsupported configuration file type: ", configFileExtension);
        }
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
            /* If no input is specified, default to none */
            if (source.input.length == 0)
                source.input = "none";

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

        if (!_config.transforms.empty) {
            stderr.writeln("Executing transforms...");

            auto commandTransformer = new CommandTransformer();
            foreach(tf; _config.transforms) {
                auto inValue = vars.get(tf.inVariable, "");

                auto outValue = commandTransformer.transform(
                    tf.command,
                    inValue);

                vars[tf.outVariable] = outValue;
            }
        }

        return vars;
    }

    void generate() {
        // Harvest variables
        auto vars = harvestVariables();

        UpdateGitIgnore[] updateGitIgnores;

        string[] defaultIgnoreFiles;
        string[] templateFilesProcessed;

        /* Process templates */
        auto templateProcessor = new TemplateProcessor();

        foreach(tmp; _config.templates) {
            /* Default to UTF-8 if no encoding is specified. */
            auto encodingName = !tmp.encoding.empty ? tmp.encoding : "utf-8";

            string[] ignoreFiles;

            // Locate all matching templates withing the root directory
            auto fileLocator = new FileLocator();
            auto templateFiles = fileLocator.locateTemplates(_rootPath, tmp.glob);

            /* Subtract already processed template files from the located files for this glob
               to ensure that each template file is only processed once. */
            auto templateFilesToProcess = setDifference(templateFiles, templateFilesProcessed);

            foreach(templateFile; templateFilesToProcess) {
                // Get output filename by stripping the template extension
                auto outputFile = templateFile.stripExtension();

                auto relativeTemplatePath = relativePath(templateFile, _rootPath);
                stderr.writeln("Processing template: ", relativeTemplatePath);

                // Process the template
                templateProcessor.processTemplate(templateFile, outputFile, vars, encodingName);

                // Add to list of processed template files
                templateFilesProcessed ~= templateFile;

                // Add to list of files to ignore
                ignoreFiles ~= outputFile;
            }

            if (tmp.gitIgnore.length > 0)
                /* If a template-specific gitIgnore is specified, add it for update. */
                updateGitIgnores ~= UpdateGitIgnore(tmp.gitIgnore, ignoreFiles);
            else
                /* Otherwise, just add this template's ignore files to the default ignore files. */
                defaultIgnoreFiles ~= ignoreFiles;
        }

        updateGitIgnores ~= UpdateGitIgnore(_config.gitIgnore, defaultIgnoreFiles);

        /* Update all .gitignore files */
        foreach(ugi; updateGitIgnores) {
            // If .gitignore path is empty, skip it.
            if (ugi.gitIgnore.length == 0)
                continue;

            stderr.writeln("Updating .gitignore file: ", ugi.gitIgnore);

            import tmpl8.services.gitignoreupdater : GitIgnoreUpdater;
            auto gitIgnoreUpdater = new GitIgnoreUpdater();

            auto gitIgnoreFile = buildPath(_rootPath, ugi.gitIgnore);
            auto gitIgnorePath = dirName(gitIgnoreFile);

            // Make ignored files relative to the .gitignore file's path
            auto ignoreFiles = ugi.ignoreFiles.map!(f => relativePath(f, gitIgnorePath)).array();

            gitIgnoreUpdater.updateGitIgnore(gitIgnoreFile, ignoreFiles);
        }
    }
}
