module tmpl8.inputs.file;

import std.conv : to;
import std.file : read;

import tmpl8.input : Input;
import tmpl8.interfaces : IInput;

/// File input implementation
class FileInput : IInput {
    static this() {
        Input.register("file", new typeof(this)());
    }

    ubyte[] getData(string[string] parameters) {
        auto filename = parameters.get("path", "");

        auto data = cast(ubyte[]) read(filename);

        return data;
    }
}
