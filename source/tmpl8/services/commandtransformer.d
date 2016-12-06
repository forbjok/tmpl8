module tmpl8.services.commandtransformer;

import std.conv : to;
import std.process : pipeShell, Redirect, wait;

interface ICommandTransformer {
}

/// Service for transforming variables
class CommandTransformer : ICommandTransformer {
    // Transform a value by piping it through a command
    string transform(in string command, in string inValue) {
        // Execute command
        auto pipe = pipeShell(command, Redirect.stdin | Redirect.stdout);

        // Write input value to stdin
        auto stdin = pipe.stdin;
        stdin.write(inValue);
        stdin.close();

        // Wait for process to exit
        pipe.pid.wait();

        // Get stdout of pipe
        auto stdout = pipe.stdout;

        // Read output value from process stdout
        auto data = new byte[stdout.size().to!size_t];
        stdout.rawRead(data);

        return cast(string) data;
    }
}
