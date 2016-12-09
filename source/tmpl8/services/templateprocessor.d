module tmpl8.services.templateprocessor;

import std.conv : to;
import std.file : read, write;
import std.path : baseName;
import std.stdio : stderr;

import tmpl8.interfaces : IEncoding;
import tmpl8.utils.templating : replaceTemplateVars;

class TemplateProcessor {
    void processTemplate(IEncoding encoding, in string templateFile, in string outputFile, in string[string] variables) {
        try {
            auto data = cast(ubyte[]) read(templateFile);

            // Read template
            auto text = encoding.decode(data).to!string;

            // Perform replacements
            text = text.replaceTemplateVars(variables);

            // Write output file
            write(outputFile, cast(void[]) encoding.encode(text.to!(dchar[])));
        }
        catch(Exception ex) {
            stderr.writefln("Error processing template [ %s ]: %s", baseName(templateFile), ex.msg);
        }
    }
}
