import std.stdio : writeln;
import std.path : dirName, getcwd;

import tmpl8.services.filelocator : FileLocator;
import tmpl8.services.tmpl8service : Tmpl8Service;

private const tmpl8ConfigFilename = "tmpl8.json";

int main(string[] args)
{
    auto fileLocator = new FileLocator();
    auto configFile = fileLocator.locateFileInPathOrParent(getcwd(), tmpl8ConfigFilename);

    writeln("Config file found: ", configFile);

    auto tmpl8Service = new Tmpl8Service();
    tmpl8Service.generate(configFile);

    return 0;
}
