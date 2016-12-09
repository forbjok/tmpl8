module tmpl8.interfaces;

interface IInput {
    ubyte[] getData(string[string] parameters);
}

interface IParser {
    string[string] parse(string[string] parameters, const ubyte[] data);
}

interface IEncoding {
    dchar[] decode(in ubyte[] data);
    ubyte[] encode(in dchar[] str);
}
