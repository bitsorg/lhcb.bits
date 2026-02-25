package: RELAX
version: 6.1.2
tag: 6.1.2
sources:
  - https://lcgpackages.web.cern.ch/tarFiles/sources/RELAX-6.1.2.tar.gz

requires:
  - "GCC-Toolchain:(?!osx)"
  - CLHEP
  - ROOT
  
build_requires:
  - "CMake"
  - bits-recipe-tools
---
#!/bin/bash -e
##############################
. $(bits-include CMakeRecipe)
##############################
MODULE_OPTIONS="--lib --cmake"
##############################

function Prepare() {
    tar zxvf $SOURCEDIR/$PKGNAME-$PKGVERSION.tar.gz && cd $PKGNAME-$PKGVERSION
}
