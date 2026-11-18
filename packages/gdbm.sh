package: gdbm
description: GNU dbm key-value database library (static, for Python's dbm.gnu)
version: "1.24"
sources:
  - https://ftp.gnu.org/gnu/gdbm/gdbm-%(version)s.tar.gz
build_requires:
  - bits-recipe-tools
  - "GCC-Toolchain:(?!osx)"
license: GPL-3.0-or-later
references:
  - cpe:2.3:a:gnu:gdbm:%(version)s
---
#!/bin/bash -e
##############################
. $(bits-include AutoToolsRecipe)
##############################
MODULE_OPTIONS="--root"
##############################
# Temporary, for LHCb's Python (python.sh): static, so its _gdbm needs nothing at
# run time. Goes when lcg.bits' Python is built with gdbm.
# -std=gnu17: 1.24's tools/var.c names a member "bool", a keyword in C23 (GCC 15).
function Configure() {
  ./configure --prefix="$INSTALLROOT" --disable-shared --enable-static --with-pic \
    --without-readline --disable-nls CFLAGS="${CFLAGS:--g -O2} -std=gnu17"
}
