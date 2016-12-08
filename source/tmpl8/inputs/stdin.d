module tmpl8.inputs.stdin;

import std.conv : to;
import std.exception : ErrnoException;
import std.stdio : File, stdin;

import tmpl8.input : Input;
import tmpl8.interfaces : IInput;

/// stdin input implementation
class StdinInput : IInput {
    static this() {
        Input.register("stdin", new this());
    }

    ubyte[] getData(string[string] parameters) {
        try {
            auto dataSize = stdin.size().to!size_t;
            auto data = new ubyte[dataSize];

            stdin.rawRead(data);

            return data;
        }
        catch (ErrnoException) {
            return new ubyte[0];
        }
    }
}
