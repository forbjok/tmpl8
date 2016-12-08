module tmpl8.services.templateprocessor;

import std.file : readText, write;
import std.path : baseName;
import std.stdio : stderr;

import tmpl8.utils.templating : replaceTemplateVars;

class TemplateProcessor {
    void processTemplate(in string templateFile, in string outputFile, in string[string] variables) {
        try {
            // Read template
            auto text = readText(templateFile);

            // Perform replacements
            text = text.replaceTemplateVars(variables);

            // Write output file
            write(outputFile, cast(void[]) text);
        }
        catch(Exception ex) {
            stderr.writefln("Error processing template [ %s ]: %s", baseName(templateFile), ex.msg);
        }
    }
}
