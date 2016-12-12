module tmpl8.services.gitignoreupdater;

import std.algorithm : any, map;
import std.array : array;
import std.file : exists, readText, write;
import std.path : dirName, dirSeparator, relativePath;
import std.string : join, replace, splitLines, startsWith;

class GitIgnoreUpdater {
    private const string beginComment = "### BEGIN TMPL8 ###";
    private const string endComment = "### END TMPL8 ###";

    void updateGitIgnore(in string filename, in string[] ignoreFiles) {
        string[] linesBefore;
        string[] linesAfter;
        string[] newBlockLines;

        if (exists(filename)) {
            /* If .gitignore file already exists, read it and
               try to detect the existing autogenerated block. */
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

            /* If no block was present before, add a blank line before the new block */
            if (!afterBlock) {
                newBlockLines ~= "";
            }
        }

        // Get path of directory containing the .gitignore
        auto gitIgnorePath = dirName(filename);

        auto ignoreFileLines = ignoreFiles
            // Make ignore files relative to .gitignore path
            .map!(f => relativePath(f, gitIgnorePath))

            // Replace all dir separators (which could be backslashes in Windows) with forward-slashes
            .map!(f => f.replace(dirSeparator, "/"))

            // Append slash to the beginning of the ignore file path to ensure that it only matches the exact file
            .map!(f => "/" ~ f)

            // Make an array of the ignore file lines
            .array();

        newBlockLines ~= [beginComment] ~ ignoreFileLines ~ [endComment];
        auto newLines = (linesBefore ~ newBlockLines ~ linesAfter).join("\n") ~ "\n";

        // Write new file
        write(filename, newLines);
    }
}
