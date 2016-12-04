module tmpl8.interfaces;

interface IInput {
    byte[] getData(string[string] parameters);
}

interface IParser {
    string[string] parse(string[string] parameters, const byte[] data);
}
