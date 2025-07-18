{ pkgs, lib, config, inputs, ... }:

{
  # dotenv.enable = true;
  difftastic.enable = true;

  stdenv = pkgs.clangStdenv;

  # https://devenv.sh/packages/
  packages = with pkgs; [
    just
    llvmPackages_20.libllvm
    llvmPackages_20.clang-tools
    ninja
    cmake
    codespell
    conan
    cppcheck
    ccache
    doxygen
    gtest
    gcovr
  ];

  # https://devenv.sh/languages/
  # languages.cpp.enable = true;

  # https://devenv.sh/processes/
  # processes.cargo-watch.exec = "cargo-watch";

  # https://devenv.sh/services/
  # services.postgres.enable = true;

  # https://devenv.sh/scripts/
  # scripts.hello.exec = ''
  #   echo hello from $GREET
  # '';

  # enterShell = ''
  #   hello
  #   git --version
  # '';

  # https://devenv.sh/tasks/
  # tasks = {
  #   "myproj:setup".exec = "mytool build";
  #   "devenv:enterShell".after = [ "myproj:setup" ];
  # };

  # https://devenv.sh/tests/
  # enterTest = ''
  #   echo "Running tests"
  #   git --version | grep --color=auto "${pkgs.git.version}"
  # '';

  # https://devenv.sh/git-hooks/
  # git-hooks.hooks.shellcheck.enable = true;

  # See full reference at https://devenv.sh/reference/options/
}
