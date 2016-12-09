module tmpl8.inputs.stdin;

import std.algorithm : joiner;
import std.array : array;
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
        version (Posix) {
            import core.sys.posix.unistd : isatty;

            // If it's a tty (terminal), no data was piped to stdin
            // Return an empty buffer.
            if (isatty(stdin.fileno()))
                return new ubyte[0];

            auto data = stdin.byChunk(4096).joiner.array();
            return data;
        }
        else version (Windows) {
            import core.sys.windows.winbase : FILE_TYPE_PIPE, GetFileType;

            // If stdin file is not a pipe, return an empty buffer
            if (GetFileType(stdin.windowsHandle) != FILE_TYPE_PIPE)
                return new ubyte[0];

            auto data = stdin.byChunk(4096).joiner.array();
            return data;
        }
    }
}
