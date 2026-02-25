package: Gaudi
version: "%(tag_basename)s"
tag: "v40r2"
source: https://gitlab.cern.ch/gaudi/Gaudi.git
requires:
  - "GCC-Toolchain:(?!osx)"
  - rangev3
  - boost
  - ROOT
  - cppgsl
  - fmt
  - HepPDT
  - CLHEP
  - TBB
  - xercesc
  - CppUnit
  - Catch2
  - cppgsl
  - Python-modules
  - Python-modules-list
  - Python
  
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
MODULE_OPTIONS="--bin --lib --cmake"
##############################

function Prepare() {
    rsync -av --delete --delete-excluded $SOURCEDIR/ ./
}

function Configure() {
    mkdir build && cd build
    export PATH=$PATH:$PYTHON_MODULES/bin
    cmake -S .. -B . \
 	   -DCMAKE_BUILD_TYPE=Developer \
           -DCMAKE_INSTALL_PREFIX=$INSTALLROOT \
	   -DCPPGSL_INCLUDE_DIR=$CPPGSL_ROOT/include \
           -DRANGEV3_INCLUDE_DIR=$RANGEV3_ROOT/include \
	   -DROOT_INCLUDE_DIR=$ROOTSYS/include \
	   -DCPPUNIT_INCLUDE_DIR=$CPPUNIT_ROOT/include -DCPPUNIT_LIBRARY=$CPPUNIT_ROOT/lib/libcppunit.so \
           -DGAUDI_USE_HEPPDT=OFF \
           -DGAUDI_USE_AIDA=OFF \
           -DGAUDI_USE_DOXYGEN=OFF \
           -DGAUDI_USE_GPERFTOOLS=FALSE \
           -DCMAKE_FIND_FRAMEWORK=LAST \
           -DBoost_NO_BOOST_CMAKE=FALSE \
           -DCMAKE_CXX_STANDARD=20 \
           -DCMAKE_PREFIX_PATH="$BOOST_ROOT;$FMT_ROOT;$CATCH2_ROOT;$ROOTSYS;$CLHEP_ROOT;$RANGEV3_ROOT"
}

function Make() {
   cmake --build . -- ${CMAKE_OPTIONS} ${JOBS:+-j$JOBS}
}

function MakeInstall() {
   cmake --install .  ${CMAKE_OPTIONS}
}

function PostInstall() {
cat >> "$MODULEFILE" <<EoF
  prepend-path PYTHONPATH \$PKG_ROOT/python
  prepend-path ROOT_INCLUDE_PATH \$PKG_ROOT/include
EoF
}

declare -f Run
