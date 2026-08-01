import std.stdio;
import log;
import build;

// 
// DONE: Finish extraction
// DONE: Add building
// DONE: Add install with DESTDIR
// TODO: Add SHA256 hashes for source downloads
// TODO: Add package splitting; one package can create multiple package archives
// TODO: Add fully custom package scripts (to support like PKGBUILDs etc)
// 

int main(string[] argv) {
	auto argc = argv.length;
	if (argc == 1) {
	  log.error("No arguments provided");
		return 2;
	}

	if (argv[1] == "build") {
	  if (argc == 2) {
			log.error("Not enough arguments");
			return 2;
		}

		build.Package[] packages;
		bool verbose = false;
		foreach (arg; argv[2 .. $]) {
		  if (arg == "--verbose") {
			verbose = true;
		  } else if (arg == "--no-verbose") {
			verbose = false;
		  } else {
			Package h;
			h.verbose = verbose;
			h.name = arg;
			packages ~= h;
		  }
		}
		build.build(packages);

	} else if (argv[1] == "--help") {
	  if (argc > 2 && argv[2] == "name") {
			writeln("There is a Linkin Park video where Chester says:");
			writeln("> \033[2mThe cracks in the floor represent the bLOOD that has " ~
			  "been pourED IN from aLl Of OuR \033[0;1mANceSTorS\033[0;2m, OVER MANY MILLENIA!\033[0m");
			return 0;
		}

	  log.info("ancestor v1.0");
		writeln("  Build system for Redrose Linux packages.\n");
		writeln("  --help       view this message");
		writeln("  --help name  learn about the naming of this");
		writeln("  build <pkgs> build some packages");
		writeln("    --verbose  print more extra messages");
		return 0;

	} else {
	  log.error("Unknown argument: " ~ argv[1]);
		writeln("  Use --help to view available commands.");
		return 2;
	}

	return 0;
}
