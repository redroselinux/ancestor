import std.net.curl;
import std.process : spawnShell, wait;
import std.algorithm;
import log;

/* The name is shit because the download() function is already taken so uh get this */


bool I_HATE_NAME_CONFLICTS_SO_FUCK_YOU_THIS_IS_THE_FUNC_NAME(string url, string dest, string checkout) {
  if (url.startsWith("git+")) {
    string args = "git clone " ~ url[4 .. $] ~ " " ~ dest;

    if (checkout == "") {
      args ~= " --depth=1";
    } else {
      args ~= " --branch " ~ checkout;
    }

    auto pid = spawnShell(args);
    auto status = wait(pid);

    if (status != 0) {
      log.error("Git clone failed.");
      return false;
    }

  } else {
    try {
      download(url, dest);
      return true;
    } catch (Exception e) {
      log.error("Download failed: " ~ e.msg);
      return false;
    }
  }

  // if this is reached idk how it prolly should fail ??
  return false;
}