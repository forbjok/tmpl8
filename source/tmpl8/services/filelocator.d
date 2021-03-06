module tmpl8.services.filelocator;

import std.algorithm;
import std.file : exists, isDir, isFile;
import std.path : absolutePath, buildPath, dirName, relativePath;
import std.string : replace;

interface IFileLocator {
}

/// Service for locating files
class FileLocator : IFileLocator {
    /// Locate a file in the current path or a parent directory
    string locateFileInPathOrParent(in string startPath, in string filename) {
        auto path = startPath.absolutePath();
        assert(path.isDir());

        auto prevPath = "";
        while(path != prevPath) {
            // Construct the full path to the desired file in the current path
            auto fullPath = buildPath(path, filename);

            // Check if the file exists
            if (fullPath.exists() && fullPath.isFile()) {
                // File existed, so return its path
                return fullPath;
            }

            // Store previous path
            prevPath = path;

            // Set path to previous path's parent directory
            path = path.dirName();
        }

        return null;
    }
}
