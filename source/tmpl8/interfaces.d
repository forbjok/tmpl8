module tmpl8.interfaces;

interface IInput {
    ubyte[] getData(string[string] parameters);
}

interface IParser {
    string[string] parse(string[string] parameters, const ubyte[] data);
}
