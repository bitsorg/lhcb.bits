package: GitCondDB
version: "%(tag_basename)s"
tag: "0.2.2"
source: https://gitlab.cern.ch/lhcb/GitCondDB
requires:
  - "GCC-Toolchain:(?!osx)"
  
build_requires:
  - bits-recipe-tools
  - CMake
  - libgit2
  - fmt
  
prefer_system: (?!slc5)
prefer_system_check:
---
#!/bin/bash -e
##############################
. $(bits-include CMakeRecipe)
##############################
MODULE_OPTIONS="--bin --lib --cmake"
##############################
function Configure() {
  mkdir build && cd build
  cmake .. -DCMAKE_INSTALL_PREFIX=$INSTALLROOT  \
           -DCMAKE_PREFIX_PATH="$LIBGIT2_ROOT;$FMT_ROOT"
}

