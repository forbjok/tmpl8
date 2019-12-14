module tmpl8.inputs.exec;

import std.algorithm : joiner;
import std.array : array;
import std.process : pipeShell, Redirect;

import tmpl8.input : Input;
import tmpl8.interfaces : IInput;

/// Execute command input implementation
class ExecInput : IInput {
    static this() {
        Input.register("exec", new typeof(this)());
    }

    ubyte[] getData(string[string] parameters) {
        auto command = parameters.get("command", "");

        // Execute command
        auto pipe = pipeShell(command, Redirect.stdout);

        // Get stdout of pipe
        auto stdout = pipe.stdout();

        auto data = stdout.byChunk(4096).joiner.array();
        return data;
    }
}
