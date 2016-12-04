module tmpl8.input;

import tmpl8.interfaces : IInput;

static class Input {
    private static IInput[string] _inputs;

    static void register(const string name, IInput implementation) {
        _inputs[name] = implementation;
    }

    static IInput get(const string name) {
        return _inputs.get(name, null);
    }
}
