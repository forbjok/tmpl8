module tmpl8.utils.encoding;

import std.conv : text, to;
import std.encoding : EncodingScheme;

dchar[] decode(in ubyte[] data, in string encodingName) {
    auto encodingScheme = EncodingScheme.create(encodingName);
    auto tempData = data.to!(const(ubyte)[]);

    if (!encodingScheme.isValid(tempData))
        throw new Exception("Invalid encoding detected.");

    auto numCodePoints = encodingScheme.count(tempData);
    auto str = new dchar[numCodePoints];

    for(size_t i = 0; i < numCodePoints; ++i) {
        auto c = encodingScheme.decode(tempData);
        str[i] = c;
    }

    return str;
}

ubyte[] encode(in dchar[] str, in string encodingName) {
    auto encodingScheme = EncodingScheme.create(encodingName);
    auto tempString = str.to!(dchar[]);
    ubyte[dchar.alignof] buffer;
    ubyte[] data;

    foreach(c; tempString) {
        // If the character cannot be encoded, throw an exception
        if (!encodingScheme.canEncode(c))
            throw new Exception("Character '" ~ text(c) ~ "' cannot be represented in the target encoding '" ~ encodingName ~ "'");

        auto len = encodingScheme.encode(c, buffer);

        data ~= buffer[0..len];
    }

    return data;
}
