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

    struct Transform {
        string command;
        string inVariable;
        string outVariable;
    }

    struct Template {
        string encoding;
    }

    Source[] sources;
    Transform[] transforms;
    Template[string] templates;
}
