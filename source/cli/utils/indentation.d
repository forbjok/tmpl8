module cli.utils.indentation;

import std.regex : regex, replaceAll;

string spacify(in string s) {
    auto re = regex(r"(?<!^)\t");

    /* Replace all tabs with 2 spaces. */
    return replaceAll(s, re, "  ");
}
