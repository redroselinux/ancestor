import config;
import log;
import std.string;
import std.conv;
import std.uri;
import std.array : replace;
import std.algorithm.searching : canFind;

// this file is shit - mostypc123, july 28th 2026 22:22 (YES THATS THE TIME RN NOT JOKING)
// maple sirup is in between my g and h keycaps so i had to clean them - mostypc123, july 30th 2026 22:23 (HOW)
// today put fine by mike shinoda on repeat - mostypc123, july 31th 2026 22:06

/* Simple helper to log parse errors. */
void error_helper(string msg, int linec, ref config.PackageOptions result) {
  log.error(msg);
  log.info("line " ~ to!string(linec));
  result.name = "failed to parse: " ~ msg ~ " on line " ~ to!string(linec);
}

/* Simple uriLength wrapper to check if an URL is valid. */
bool url_valid(string url) {
  auto len = uriLength(url);
  return len != -1;
}

/* Parse a manifest file into a PackageOptions struct. 
 * result.name will be set to "failed to parse <message> 
 * on line <line>" if parsing fails. */
config.PackageOptions parse(string manifest) {
  config.PackageOptions result;

  string btype; // not needed in the struct but used here
  string binresult; // same here, for dub
  int linec = 1;
  foreach (line; splitLines(manifest)) {
    if (line.startsWith("--")) continue; // comments
    if (line.strip().length == 0) continue; // empty lines

    auto opts = line.split("::");
    auto optsc = opts.length;

    auto type = strip(opts[0]);

    if (type == "author") {
      if (optsc < 3) {
        error_helper(
          "Parse Error: Not enough arguments for property 'author'.", linec, result
        );
        return result;
      }

      // author :: name :: email = name <email>
      result.author_string = strip(opts[1]) ~ " <" ~ strip(opts[2]) ~ ">";

    } else if (type == "package") {
      if (optsc < 3) {
        error_helper(
          "Parse Error: Not enough arguments for property 'package'.", linec, result
        );
        return result;
      }

      // package :: name :: version
      result.name = strip(opts[1]);
      result.ver = strip(opts[2]);

    } else if (type == "build_deps") {
      if (optsc < 2 || optsc > 2) {
        error_helper(
          "Parse Error: Wrong arguments for property 'build_deps'.", linec, result
        );
        return result;
      }

      // build_deps :: dep1 dep2 dep3 ...
      result.build_deps = strip(opts[1]).split(" ");

    } else if (type == "download") {
      if (optsc < 3) {
        error_helper(
          "Parse Error: Not enough arguments for property 'download'.", linec, result
        );
        return result;
      }

      // download :: gnu_ftp :: .tar.<> OR
      // download :: git :: <url> :: <checkout> OR
      // download :: git <url> OR (clones with --depth 1 and no checkout)
      // download :: git <url> :: auto OR (checkout is the same as the package version)
      // download :: manual :: <url>
      // THEN
      // download :: sha256 :: <sha256sum>
      auto download_type = strip(opts[1]);
      if (download_type == "gnu_ftp") {
        if (result.name == "") {
          error_helper(
            "Parse Error: Property 'package' must be defined before 'download'.", linec, result
          );
          return result;
        }

        string url = "https://ftp.gnu.org/gnu/" ~ result.name ~ "/" ~
          result.name ~ "-" ~ result.ver ~ strip(opts[2]);
        
        result.download = url;

        if (strip(opts[2]).canFind(".tar.")) {
          result.extract_cmd = "tar -xf <placeholder> --strip-components=1 -C <dir>";
        } else {
          error_helper(
            "Parse Error: Cannot generate extract command for file extension '" ~ strip(opts[2]) ~ "'." ~
            " You should try using 'manual_extract' instead.",
            linec, result
          );
          return result;
        }

      } else if (download_type == "manual") {
        string url = strip(opts[2]);

        log.info("Downloading from " ~ url);
        result.download = url;
      } else if (download_type == "git") {
        result.git = true;
        string url = strip(opts[2]);
        // to indicate for download.d that its a git repo
        if (!url.endsWith(".git")) url ~= ".git";

        if (optsc > 3) {
          result.git_checkout_ver = opts[3] == "auto" ? result.ver : strip(opts[3]);
        }

        result.download = "git+" ~ url;
        log.info("Downloading from git+" ~ url ~ " (" ~ result.git_checkout_ver ~ ")");

      } else {
        error_helper(
          "Parse Error: Unknown download type '" ~ opts[1] ~ "'.", linec, result
        );
        return result;
      }

      if (!url_valid(strip(result.download.replace("git+", "")))) {
        error_helper(
          "Parse Error: Invalid URL '" ~ strip(opts[2]) ~ "'.", linec, result
        );
        return result;
      }
    
    } else if (type == "manual_extract") {
      if (optsc < 2) { 
        error_helper(
          "Parse Error: Not enough arguments for property 'manual_extract'.", linec, result
        );
        return result;
      }

      if (result.extract_cmd != "") {
        log.warn("Warning: Line " ~ to!string(linec) ~ " overwrites an already set extract command.");
      }

      if (!strip(opts[1]).canFind("<placeholder>")) {
        error_helper(
          "Parse Error: Extract command must contain '<placeholder>' to indicate the file to extract.",
          linec, result
        );
        return result;
      } else if (!strip(opts[1]).canFind("<dir>")) {
        error_helper(
          "Parse Error: Extract command must contain '<dir>' to indicate the dir to extract to.", 
          linec, result
        );
        return result;
      }

      // manual_extract :: <cmd>
      result.extract_cmd = strip(opts[1]);

    } else if (type == "build") {
      if (optsc < 2) {
        error_helper(
          "Parse Error: Not enough arguments for property 'build'.", linec, result
        );
        return result;
      }

      // build :: autotools_make OR
      // build :: manual :: <cmd1> :: <cmd2> :: ...
      auto build_type = strip(opts[1]);

      if (build_type == "autotools_make") {
        btype = "autotools_make";
        if (result.git_checkout_ver != "") {
          result.build_cmds ~= "autoreconf -i";
        }

        if (optsc > 2) {
          result.build_cmds ~= "./configure --prefix=/usr " ~ strip(opts[2]);
        } else {
          result.build_cmds ~= "./configure --prefix=/usr";
        }
        result.build_cmds ~= "make -j$(nproc)";

      } else if (build_type == "nimble_single_bin") {
        btype = "nimble_single_bin";
        if (optsc < 3) {
          error_helper(
            "Parse Error: Not enough arguments for property 'build'.", linec, result
          );
          return result;
        }

        result.build_cmds ~= "nimble build -d:release";
        binresult = strip(opts[2]);

      } else if (build_type == "manual") {
        btype = "manual";
        if (optsc < 3) {
          error_helper(
            "Parse Error: Not enough arguments for property 'build'.", linec, result
          );
          return result;
        }

        foreach (cmd; opts[2 .. $]) {
          result.build_cmds ~= strip(cmd);
        }
      } else if (build_type == "dub_single_bin") {
        if (optsc < 3) {
          error_helper(
            "Parse Error: Not enough arguments for property 'build'.", linec, result
          );
          return result;
        }

        btype = "dub_single_bin";
        result.build_cmds ~= "dub build --build=release";
        binresult = strip(opts[2]);
      }
    } else if (type == "install_cmd") {
      if (optsc < 2) {
        error_helper(
          "Parse Error: Not enough arguments for property 'install_cmd'.", linec, result
        );
        return result;
      }

      auto install_type = strip(opts[1]);

      void single_bin_helper() {
        result.install_cmds ~= "mkdir -p <placeholder>/usr/bin/";
        result.install_cmds ~= "cp " ~ binresult ~ " <placeholder>/usr/bin/";
      }

      if (install_type == "auto") {
        if (btype == "manual") {
          error_helper(
            "Parse Error: Property 'install_cmd' cannot be 'auto' when build type is 'manual'.",
            linec, result
          );
          return result;
        } else if (btype == "autotools_make") {
          result.install_cmds ~= "make install DESTDIR=<placeholder>";
        }  else if (btype == "dub_single_bin") {
          single_bin_helper();
        } else if (btype == "nimble_single_bin") {
          single_bin_helper();
        } else {
          error_helper(
            "Parse Error: Property 'install_cmd' must be used after the 'build' property.",
            linec, result
          );
          return result;
        }
      } else if (install_type == "manual") {
        if (optsc < 3) {
          error_helper(
            "Parse Error: Not enough arguments for property 'install_cmd'.", linec, result
          );
          return result;
        }

        foreach (cmd; opts[2 .. $]) {
          result.install_cmds ~= strip(cmd);
        }
      } else {
        error_helper(
          "Parse Error: Unknown install_cmd type '" ~ opts[1] ~ "'.", linec, result
        );
        return result;
        
      }
    } else if (type == "car_post_inst") {
      if (optsc < 2) {
        error_helper(
          "Parse Error: Not enough arguments for property 'car_post_inst'.", linec, result
        );
        return result;
      }

      foreach (cmd; opts[1 .. $]) {
        result.car_conf ~= "exec " ~ strip(cmd);
      }
    } else if (type == "car_dep") {
      if (optsc < 2) {
        error_helper(
          "Parse Error: Not enough arguments for property 'car_dep'.", linec, result
        );
        return result;
      }

      foreach (dep; opts[1 .. $]) {
        result.car_conf ~= "dep " ~ strip(dep);
      }

    } else {
      error_helper(
        "Parse Error: Unknown property '" ~ type ~ "'.", linec, result
      );
      return result;
    }

    linec++;
  }

  if (!result.git && result.extract_cmd == "") {
    error_helper("Parse Error: Extract command was not set.", linec, result);
  }

  return result;
}
