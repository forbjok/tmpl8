module tmpl8.inputs.none;

import tmpl8.input : Input;
import tmpl8.interfaces : IInput;

/// Dummy input that returns an empty byte array
class NoneInput : IInput {
    static this() {
        Input.register("none", new this());
    }

    byte[] getData(string[string] parameters) {
        return new byte[0];
    }
}
