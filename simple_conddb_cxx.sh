package: simple_conddb_cxx
version: "%(tag_basename)s"
tag: "v0.1.0"
source: https://gitlab.cern.ch/lhcb/simple_conddb_cxx.git
requires:
  - "GCC-Toolchain:(?!osx)"
  
build_requires:
  - bits-recipe-tools
  - CMake
  - rust
  
prefer_system: (?!slc5)
prefer_system_check:
---
#!/bin/bash -e
##############################
. $(bits-include CMakeRecipe)
##############################
MODULE_OPTIONS="--bin --lib"
##############################
function Prepare() {
    rsync -av --delete --delete-excluded $SOURCEDIR/ ./
}

function Configure() {
  mkdir build && cd build
  cmake .. -DCMAKE_INSTALL_PREFIX=$INSTALLROOT 
}

function Make() {
   cmake --build . -- ${CMAKE_OPTIONS} ${JOBS:+-j$JOBS}
}

function MakeInstall() {
    cmake --install .    
}

