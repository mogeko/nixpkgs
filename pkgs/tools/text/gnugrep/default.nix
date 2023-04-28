{ lib, stdenv, fetchurl, pcre2, libiconv, perl, autoreconfHook }:

# Note: this package is used for bootstrapping fetchurl, and thus
# cannot use fetchpatch! All mutable patches (generated by GitHub or
# cgit) that are needed here should be included directly in Nixpkgs as
# files.

let version = "3.11"; in

stdenv.mkDerivation {
  pname = "gnugrep";
  inherit version;

  src = fetchurl {
    url = "mirror://gnu/grep/grep-${version}.tar.xz";
    hash = "sha256-HbKu3eidDepCsW2VKPiUyNFdrk4ZC1muzHj1qVEnbqs=";
  };

  nativeCheckInputs = [ perl ];
  outputs = [ "out" "info" ]; # the man pages are rather small

  buildInputs = [ pcre2 libiconv ];

  # cygwin: FAIL: multibyte-white-space
  # freebsd: FAIL mb-non-UTF8-performance
  doCheck = !stdenv.isCygwin && !stdenv.isFreeBSD;

  # On macOS, force use of mkdir -p, since Grep's fallback
  # (./install-sh) is broken.
  preConfigure = ''
    export MKDIR_P="mkdir -p"
  '';

  # Fix reference to sh in bootstrap-tools, and invoke grep via
  # absolute path rather than looking at argv[0].
  postInstall =
    ''
      rm $out/bin/egrep $out/bin/fgrep
      echo "#! /bin/sh" > $out/bin/egrep
      echo "exec $out/bin/grep -E \"\$@\"" >> $out/bin/egrep
      echo "#! /bin/sh" > $out/bin/fgrep
      echo "exec $out/bin/grep -F \"\$@\"" >> $out/bin/fgrep
      chmod +x $out/bin/egrep $out/bin/fgrep
    '';

  meta = with lib; {
    homepage = "https://www.gnu.org/software/grep/";
    description = "GNU implementation of the Unix grep command";

    longDescription = ''
      The grep command searches one or more input files for lines
      containing a match to a specified pattern.  By default, grep
      prints the matching lines.
    '';

    license = licenses.gpl3Plus;

    maintainers = [
      maintainers.das_j
      maintainers.m00wl
    ];
    platforms = platforms.all;
    mainProgram = "grep";
  };

  passthru = {
    inherit pcre2;
  };
}
