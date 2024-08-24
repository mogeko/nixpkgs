{
  lib,
  fetchgit,
  unstableGitUpdater,
  stdenv,
  doxygen,
  graphviz,
  python3Packages,
}:

stdenv.mkDerivation {
  pname = "xtf";
  version = "0-unstable-2024-07-25";

  outputs = [
    "out" # xtf-runner and test suite.
    "doc" # Autogenerated HTML documentation website.
    "dev" # Development headers.
  ];

  src = fetchgit {
    url = "https://xenbits.xenproject.org/git-http/xtf.git";
    rev = "f37c4574dd79d058c035be989ac6648508556a1a";
    hash = "sha256-3eOKQXdyFX0iY90UruK8lLfnXQt+cOlvyW/KMj2hczQ=";
  };

  nativeBuildInputs =
    (with python3Packages; [
      python
      wrapPython
    ])
    ++ [
      doxygen
      graphviz
    ];

  buildFlags = [ "doxygen" ];

  installFlags = [
    "xtfdir=$(out)/share/xtf"
  ];

  postInstall =
    # Much like Xen, XTF installs its files to dist/nix/store/*/*,
    # so we need to copy them to the right place.
    ''
      mkdir -p ''${!outputBin}/share
      cp -prvd dist/nix/store/*/* ''${!outputBin}
    ''
    # The documentation and development headers aren't in the dist/
    # folder, so we copy those too.
    + ''
      mkdir -p ''${!outputDoc}/share/doc/xtf
      cp -prvd docs/autogenerated/html ''${!outputDoc}/share/doc/xtf

      mkdir -p ''${!outputDev}/include
      cp -prvd include ''${!outputDev}
    ''
    # Wrap xtf-runner, and link it to $out/bin.
    # This is necessary because the real xtf-runner should
    # be in the same directory as the tests/ directory.
    + ''
      wrapPythonProgramsIn "''${!outputBin}/share/xtf" "''${!outputBin} $pythonPath"
      mkdir -p ''${!outputBin}/bin
      ln -s ''${!outputBin}/share/xtf/xtf-runner ''${!outputBin}/bin/xtf-runner
    '';

  passthru.updateScript = unstableGitUpdater { };

  meta = {
    description = "Xen Test Framework and Suite for creating microkernel-based tests";
    homepage = "https://xenbits.xenproject.org/docs/xtf/index.html";
    license = lib.licenses.bsd2;
    maintainers = with lib.maintainers; [ sigmasquadron ];
    mainProgram = "xtf-runner";
    platforms = lib.lists.intersectLists lib.platforms.linux lib.platforms.x86_64;
  };
}
