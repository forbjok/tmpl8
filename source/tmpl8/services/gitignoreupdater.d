module tmpl8.services.gitignoreupdater;

import std.algorithm : map;
import std.array : array;
import std.file : readText, write;
import std.path : dirSeparator;
import std.string : join, replace, splitLines, startsWith;

class GitIgnoreUpdater {
    private const string beginComment = "### BEGIN TMPL8 ###";
    private const string endComment = "### END TMPL8 ###";

    void updateGitIgnore(in string filename, in string[] ignoreFiles) {
        string[] linesBefore;
        string[] linesAfter;

        auto fileText = readText(filename);

        bool insideBlock = false;
        bool afterBlock = false;
        foreach(line; fileText.splitLines()) {
            if (insideBlock) {
                if (line.startsWith(endComment)) {
                    afterBlock = true;
                    insideBlock = false;
                    continue;
                }
            }
            else {
                if (line.startsWith(beginComment)) {
                    insideBlock = true;
                    continue;
                }

                if (afterBlock) {
                    linesAfter ~= line;
                }
                else {
                    linesBefore ~= line;
                }
            }
        }

        string[] newBlockLines;

        /* If no block was present before, add a blank line before the new block */
        if (!afterBlock) {
            newBlockLines ~= "";
        }

        newBlockLines ~= [beginComment] ~ ignoreFiles.map!(f => f.replace(dirSeparator, "/")).array() ~ [endComment];
        auto newLines = (linesBefore ~ newBlockLines ~ linesAfter).join("\n");

        // Write new file
        write(filename, newLines);
    }
}
