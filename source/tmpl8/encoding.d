module tmpl8.encoding;

import tmpl8.interfaces : IEncoding;

static class Encoding {
    private static IEncoding[string] _encodings;

    static void register(const string name, IEncoding implementation) {
        _encodings[name] = implementation;
    }

    static IEncoding get(const string name) {
        return _encodings.get(name, null);
    }
}
