import std.process : environment;
import std.array : split;
import std.file;

string[] paths() {
  auto path = environment.get("ANCESTOR_PATH", "/var/ancestor:pkg/");
  string[] dirs;
  foreach (dir; path.split(":")) {
    dirs ~= dir;
  }
  return dirs;
}

/* Check if a package is found in ANCESTOR_PATH. Takes a string[] path
 * which the caller gets using the string[] paths() function.  Returns
 * "" if not found, otherwise the path of the package directory.*/
string found(string pkg, string[] path) {
  foreach (dir; path) {
    auto file = dir ~ "/" ~ pkg;
    if (exists(file)) {
      return file;
    }
  }
  return "";
}
