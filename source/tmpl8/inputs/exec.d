module tmpl8.inputs.exec;

import std.conv : to;
import std.process : pipeShell, Redirect, wait;

import tmpl8.input : Input;
import tmpl8.interfaces : IInput;

/// Execute command input implementation
class ExecInput : IInput {
    static this() {
        Input.register("exec", new this());
    }

    ubyte[] getData(string[string] parameters) {
        auto command = parameters.get("command", "");

        // Execute command
        auto pipe = pipeShell(command, Redirect.stdout);

        // Wait for process to exit
        wait(pipe.pid);

        // Get stdout of pipe
        auto stdout = pipe.stdout();

        // Get size of output
        auto dataSize = stdout.size().to!size_t;

        // If there is no output, simply return an empty array
        if (dataSize == 0)
            return new ubyte[0];

        // Read data from process stdout
        auto data = new ubyte[dataSize];
        stdout.rawRead(data);

        return data;
    }
}
