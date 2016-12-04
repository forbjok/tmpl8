module tmpl8.config;

struct Config {
    struct Source {
        string input;
        string parser;
        string[string] inputParameters;
        string[string] parserParameters;
        string[string] mappings;
        bool excludeUnmapped;
    }

    Source[] sources;
}
