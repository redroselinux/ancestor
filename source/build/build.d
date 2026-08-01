import log;
import parse;
import repo;
import downloads;
import workdir;
import std.stdio;
import std.file;
import std.algorithm;
import std.array;
import std.path;
import std.process : spawnShell, wait;

struct Package {
  bool verbose;
  string name;
}

/* Build packages. Returns an array with return codes with the same lenght as the
 * input string[] packages array. 0 on success, 1 on fail and 2 on partial fail. */
int[] build(Package[] packages) {
  string[] path = repo.paths();
  int[] returns;
  bool verbose;

  /* Simple helper so I dont have to write if (verbose) 50 times. */
  void verbosel(string msg) {
    if (verbose) {
      log.verbose(msg);
    }
  }

  foreach (pkgstruct ; packages) {
    string pkg = pkgstruct.name;
    verbose = pkgstruct.verbose;
    string curdir = getcwd();

    string found = repo.found(pkg, path);
    bool f = false;
    if (exists(pkg))
      f = true;

    if (found == "") {
      log.error("Package " ~ pkg ~ " not found.");
      writeln("  Maybe try changing ANCESTOR_PATH?");

      returns ~= 1;
      continue;
    }

    if (!f && !exists(found ~ "/" ~ pkg ~ ".manifest")) {
      log.error("Package " ~ pkg ~ " is missing a manifest file.");
      returns ~= 1;
      continue;
    }

    log.info("Building " ~ pkg);
    // read the the file without formatting if the package is a path
    auto file = f ? readText(found) : readText(found ~ "/" ~ pkg ~ ".manifest");
    auto parsed = parse.parse(file);

    if (parsed.name.startsWith("failed to parse")) {
      log.error("Failed to parse " ~ pkg);
      returns ~= 1;
      continue;
    }

    auto work = workdir.make_workdir(parsed.name);
    auto workd = work;
    auto workdx = work ~ "/extracted"; // obv dir for extracts
    auto workdxi = workdx ~ "/stage"; // obv for stage
    mkdirRecurse(workdx);

    string dl_dest = work;
    if (!parsed.git) {
      dl_dest = work ~ "/" ~ parsed.download.split("/")[$ - 1];
    }

    if (!parsed.git) log.info("Downloading from " ~ parsed.download);

    verbosel(dl_dest);
    // I seriously couldnt come up with a name cos name collisions :sob:
    if (!downloads.I_HATE_NAME_CONFLICTS_SO_FUCK_YOU_THIS_IS_THE_FUNC_NAME(
      parsed.download, dl_dest, parsed.git_checkout_ver
    )) {
      returns ~= 1;
      log.error("Failed to download " ~ parsed.download);
      continue;
    }

    if (parsed.git) {
      chdir(workd ~ "/cloned");
    }

    if (!parsed.git) {
      auto extract_cmd = parsed.extract_cmd
        .replace("<placeholder>", dl_dest)
        .replace("<dir>", workdx);
      log.info("Extracting source: " ~ dl_dest);
      verbosel(extract_cmd);
      
      auto pid = spawnShell(extract_cmd);
      auto status = wait(pid);
      if (status != 0) {
        log.error("Failed to extract " ~ dl_dest ~ ".");
        returns ~= 1;
        continue;
      }

      chdir(workdx);
    }

    /* Simple helper to not write 50 million lines of code. */
    bool runBuildCmd(string command) {
      log.verbose(command); // no one said i cant use verbose for nonverbose :)

      auto pid = spawnShell(command);
      auto status = wait(pid);

      if (status != 0) {
        log.error("Running command failed: " ~ command);
        return false;
      }
      return true;
    }

    log.info("Starting compilation");
    foreach (command; parsed.build_cmds) {
      if (!runBuildCmd(command)) {
        returns ~= 1;
        continue;
      }
    }

    log.info("Staging package files");
    foreach (command; parsed.install_cmds) {
      command = command.replace("<placeholder>", workdxi);

      if (!runBuildCmd(command)) {
        returns ~= 1;
        continue;
      }
    }

    log.info("Creating /car metadata file.");
    string metadata;
    parsed.car_conf.insertInPlace(0, parsed.author_string);
    parsed.car_conf.insertInPlace(1, "version " ~ parsed.ver);
    metadata = parsed.car_conf.join("\n");
    std.file.write(workdxi ~ "/car", metadata);

    log.info("Creating package archive");
    string output = parsed.name ~ ".tar.zst";
    string outputabs = absolutePath(output);
    string cmd = "fakeroot tar -I zstd -cf " ~ outputabs ~ " -C " ~ absolutePath(workdx) ~ " stage";
    if (!runBuildCmd(cmd)) {
      returns ~= 1;
      continue;
    }

    // go back to original pos
    chdir(curdir);

    string founddir = absolutePath(found.split("/")[0 .. $ - 1].join("/"));
    string foutput = founddir ~ "/" ~ output;
    log.info("Copying package archive to " ~ founddir);
    verbosel("Copying " ~ outputabs ~ " to " ~ foutput);
    copy(outputabs, foutput);

    log.ok("Built " ~ pkg ~ " successfully.");
    returns ~= 0;
  }

  return returns;
}
