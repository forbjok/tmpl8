module tmpl8.encodings.windows1252;

import std.algorithm : joiner, map;
import std.conv : text, to;
import std.encoding : EncodingScheme;
import std.array : array;
import std.process : pipeShell, Redirect;

import tmpl8.encoding : Encoding;
import tmpl8.interfaces : IEncoding;

class Windows1252Encoding : IEncoding {
    private static EncodingScheme _encodingScheme;

    static this() {
        Encoding.register("windows-1252", new this());

        _encodingScheme = EncodingScheme.create("windows-1252");
    }

    dchar[] decode(in ubyte[] data) {
        auto tempData = data.to!(const(ubyte)[]);

        if (!_encodingScheme.isValid(tempData))
            throw new Exception("Invalid encoding detected.");

        auto numCodePoints = _encodingScheme.count(tempData);
        auto str = new dchar[numCodePoints];

        for(size_t i = 0; i < numCodePoints; ++i) {
            auto c = _encodingScheme.decode(tempData);
            str[i] = c;
        }

        return str;
    }

    ubyte[] encode(in dchar[] str) {
        auto tempString = str.to!(dchar[]);
        ubyte[dchar.alignof] buffer;
        ubyte[] data;

        foreach(c; tempString) {
            // If the character cannot be encoded, throw an exception
            if (!_encodingScheme.canEncode(c))
                throw new Exception("Character '" ~ text(c) ~ "' cannot be represented in the target encoding 'windows-1252'");

            auto len = _encodingScheme.encode(c, buffer);

            data ~= buffer[0..len];
        }

        return data;
    }
}
