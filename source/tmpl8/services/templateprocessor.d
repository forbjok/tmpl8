module tmpl8.services.templateprocessor;

import std.conv : to;
import std.file : exists, read, remove, write;
import std.path : baseName;
import std.stdio : stderr;

import tmpl8.utils.encoding : decode, encode;
import tmpl8.utils.templating : replaceTemplateVars;

class TemplateProcessor {
    void processTemplate(in string templateFile, in string outputFile, in string[string] variables, in string encodingName) {
        try {
            // Remove the previous output file if it exists
            if (exists(outputFile))
                remove(outputFile);

            auto data = cast(ubyte[]) read(templateFile);

            // Read template
            auto text = decode(data, encodingName).to!string;

            // Perform replacements
            text = text.replaceTemplateVars(variables);

            // Write output file
            write(outputFile, cast(void[]) encode(text.to!(dchar[]), encodingName));
        }
        catch(Exception ex) {
            stderr.writefln("Error processing template [ %s ]: %s", baseName(templateFile), ex.msg);
        }
    }
}
