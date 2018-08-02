/*
 * Copyright 2004-2018 Cray Inc.
 * Other additional copyright holders may be indicated within.
 *
 * The entirety of this work is licensed under the Apache License,
 * Version 2.0 (the "License"); you may not use this file except
 * in compliance with the License.
 *
 * You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */


/* A help module for the mason package manager */

use Help;
use MasonUtils;


proc masonHelp() {
  writeln("Chapel's package manager");
  writeln();
  writeln('Usage:');
  writeln('    mason <command> [<args>...]');
  writeln('    mason [options]');
  writeln();
  writeln('Options:');
  writeln('    -h, --help          Display this message');
  writeln('    -V, --version       Print version info and exit');
  writeln('    --list              List installed commands');
  writeln();
  writeln('Some common mason commands are (see all commands with --list):');
  writeln('    new         Create a new mason project');
  writeln('    add         Add a dependency to Mason.toml');
  writeln('    rm          Remove a dependency from Mason.toml');
  writeln('    update      Update/Generate Mason.lock');
  writeln('    build       Compile the current project');
  writeln('    run         Build and execute src/<project name>.chpl');
  writeln('    search      Search the registry for packages');
  writeln('    env         Print environment variables recognized by mason');
  writeln('    clean       Remove the target directory');
  writeln('    doc         Build this project\'s documentation');
  writeln('    test        Compile and run tests found in test/');
  writeln('    system      Integrate with system packages found via pkg-config');
}

proc masonList() {
  writeln('Installed Mason Commands:');
  writeln('      add                ');
  writeln('      rm                 ');
  writeln('      new                ');
  writeln('      update             ');
  writeln('      build              ');
  writeln('      run                ');
  writeln('      test                ');
  writeln('      search             ');
  writeln('      env                ');
  writeln('      clean              ');
  writeln('      doc                ');
  writeln('      help               ');
  writeln('      version            ');
  writeln('      system             ');
}


proc masonRunHelp() {
  writeln('Run the compiled project and output to standard output');
  writeln();
  writeln('Usage:');
  writeln('   mason run [options]');
  writeln();
  writeln('Options:');
  writeln('    -h, --help                   Display this message');
  writeln('        --build                  Compile before running binary');
  writeln('        --show                   Increase verbosity');
  writeln('        --example <example>      Run an example');
  writeln();
  writeln('Runtime arguments can also be included after the run arguments ');
  writeln('When --example is thrown without an example, all available examples will be listed');
  writeln();
  writeln('When no options are provided, the following will take place:');
  writeln('   - Execute binary from mason project if target/ is present');
  writeln('   - If no target directory, build and run is Mason.toml is present');
}

proc masonBuildHelp() {
  writeln('Compile a local package and all of its dependencies');
  writeln();
  writeln('Usage:');
  writeln('    mason build [options]');
  writeln();
  writeln('Options:');
  writeln('    -h, --help                   Display this message');
  writeln('        --show                   Increase verbosity');
  writeln('        --release                Compile to target/release with optimizations (--fast)');
  writeln('        --force                  Force Mason to build the project');
  writeln('        --example <example>      Build an example from the example/ directory');
  writeln();
  writeln('When --example is thrown without an example, all examples will be built');
  writeln('When no options are provided, the following will take place:');
  writeln('   - Build from mason project if Mason.lock present');  
}

proc masonNewHelp() {
  writeln('Usage:');
  writeln('    mason new [options] <project name>');
  writeln();
  writeln('Options:');
  writeln('    -h, --help                   Display this message');
  writeln('        --show                   Increase verbosity');
  writeln('        --no-vcs                 Do not initialize a git repository');

}

proc masonSearchHelp() {
  const desc =
"When no query is provided, all packages in the registry will be listed. The\n" +
"query will be used in a case-insensitive search of all packages in the\n" +
"registry.\n" +
"\n" +
"Packages will be listed regardless of their chplVersion compatibility.";

  writeln("Search the registry for a package");
  writeln();
  writeln("Usage:");
  writeln("    mason search [options] <query>");
  if developerMode {
    writeln('        --debug                 Print debug information');
  }
  writeln();
  writeln("Options:");
  writeln("    -h, --help                  Display this message");
  writeln();
  writeln(desc);
}

proc masonModifyHelp() {
  writeln("Modify a Mason package's Mason.toml");
  writeln();
  writeln("Usage:");
  writeln("    mason rm [options] package");
  writeln("    mason add [options] package@version");
  writeln();
  writeln("Options:");
  writeln("    -h, --help                  Display this message");
  writeln("        --external              Add/Remove dependency from external dependencies");
  writeln("        --system                Add/Remove dependency from system dependencies");  
  writeln();
  writeln("Not listing an option will add/remove the dependency from the Mason [dependencies] table");
  writeln("Versions are necessary for adding dependencies, but not for removing dependencies");
  writeln("Manually edit the Mason.toml if multiple versions of the same package are listed");
  writeln("Package names and versions are not validated upon adding");
}

proc masonEnvHelp() {
  writeln("Print environment variables recognized by mason");
  writeln();
  writeln("Usage:");
  writeln("    mason env [options]");
  writeln();
  writeln("Options:");
  writeln("    -h, --help                  Display this message");
  writeln();
  writeln("Environment variables set by the user will be printed with an");
  writeln("asterisk at the end of the line.");
}

proc masonTestHelp() {
  writeln("Run test files located within target/debug/test");
  writeln();
  writeln("Usage:");
  writeln("    mason test [options]");
  writeln();
  writeln("Options:");
  writeln("    -h, --help                  Display this message");
  writeln("        --show                  Direct output of tests to stdout");
  writeln("        --no-run                Compile tests without running them");
  writeln("        --parallel              Run tests in parallel(sequential by default)");
  writeln();
  writeln("Test configuration is up to the user");
  writeln("Tests pass if they exit with status code 0");
}


proc masonSystemHelp() {
  writeln("Integrate a Mason package with system packages found via pkg-config");
  writeln();
  writeln("Usage:");
  writeln('    mason system [options] [<args>...]');
  writeln("    mason system [options]");
  writeln();
  writeln("Options:");
  writeln("    pc                          Print a system package's .pc file");
  writeln("    search                      Search all packages available on the system");  
  writeln("    -h, --help                  Display this message");
  writeln();
  writeln("The pc command sometimes has trouble finding a .pc file if the file is named ");
  writeln("something other than <package name>.pc  Use -i to ensure package exists");
  writeln("For more information on using system dependencies see Mason documentation");
}

proc masonSystemSearchHelp() {
  writeln("Search for packages on system found via pkg-config");
  writeln();
  writeln("Usage:");
  writeln("    mason search [options]");
  writeln();
  writeln("Options:");
  writeln("    -h, --help                  Display this message");
  writeln("        --no-show-desc          Only display package name");
  writeln("        --desc                  Parse descriptions of package to include more search results");
  writeln();
}


proc masonSystemPcHelp() {
  writeln("Print a package's .pc file (pkg-config file)");
  writeln();
  writeln("Usage:");
  writeln("    mason pc [options]");
  writeln();
  writeln("Options:");
  writeln("    -h, --help                  Display this message");
  writeln();
}


