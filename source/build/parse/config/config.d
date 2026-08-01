struct PackageOptions {
  string author_string;
  string name;
  string ver;
  string git_checkout_ver;
  string[] build_deps;
  string download;
  string extract_cmd;
  string[] build_cmds;
  string[] install_cmds;
  string[] car_conf;
  bool git;
}
