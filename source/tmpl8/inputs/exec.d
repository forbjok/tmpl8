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

    byte[] getData(string[string] parameters) {
        auto command = parameters.get("command", "");

        // Execute command
        auto pipe = pipeShell(command, Redirect.stdout);

        // Wait for process to exit
        wait(pipe.pid);

        // Get stdout of pipe
        auto stdout = pipe.stdout();

        // Read data from process stdout
        auto data = new byte[stdout.size().to!size_t];
        stdout.rawRead(data);

        return data;
    }
}
