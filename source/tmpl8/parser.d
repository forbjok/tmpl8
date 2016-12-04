module tmpl8.parser;

import tmpl8.interfaces : IParser;

static class Parser {
    private static IParser[string] _parsers;

    static void register(const string name, IParser implementation) {
        _parsers[name] = implementation;
    }

    static IParser get(const string name) {
        return _parsers.get(name, null);
    }
}
