package: Gaudi
version: "%(tag_basename)s"
tag: "master"
source: https://gitlab.cern.ch/gaudi/Gaudi.git
requires:
  - "GCC-Toolchain:(?!osx)"
  - rangev3
  - boost
  - ROOT
  - GSL
  - fmt
  - HepPDT
  - CLHEP
  - TBB
  - xercesc
  - CppUnit
  - Catch2
  - cppgsl
  
build_requires:
  - bits-recipe-tools
  - CMake
  
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
  cmake .. -DCMAKE_INSTALL_PREFIX=$INSTALLROOT \
	   -DRANGEV3_INCLUDE_DIR=$RANGEV3_ROOT/include \
	   -DCPPGSL_INCLUDE_DIR=$CPPGSL_ROOT/include \
	   -DCPPUNIT_INCLUDE_DIR=$CPPUNIT_ROOT/include -DCPPUNIT_LIBRARY=$CPPUNIT_ROOT/lib/libcppunit.so \
           -DGAUDI_USE_HEPPDT=OFF \
           -DGAUDI_USE_AIDA=OFF \
           -DGAUDI_USE_DOXYGEN=OFF
}

function Make() {
   cmake --build . -- ${CMAKE_OPTIONS} ${JOBS:+-j$JOBS}
}

function MakeInstall() {
    cmake --install .   
}
