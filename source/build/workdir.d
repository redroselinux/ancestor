import std.file;
import std.path;

string make_workdir(string pkg) {
  string path = expandTilde("~/.cache/ancestor/workdir/" ~ pkg);
  if (exists(path)) {
    rmdirRecurse(path);
  }
  mkdirRecurse(path);
  return path;
}
