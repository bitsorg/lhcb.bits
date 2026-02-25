package: Detector
version: "%(tag_basename)s"
tag: "v3r9"
source: https://gitlab.cern.ch/lhcb/Detector.git
requires:
  - "GCC-Toolchain:(?!osx)"
  - Gaudi
  - simple_conddb_cxx
  - rapidyaml
  - DD4Hep
  - yamlcpp
  - fmt
  
build_requires:
  - CMake
  - bits-recipe-tools
  
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
  export CXXFLAGS="-I${YAMLCPP_ROOT}/include -march=native "$CCXXFLAGS
  export LDFLAGS="-L${YAMLCPP_ROOT}/lib "$LDFLAGS
  cmake .. -DCMAKE_INSTALL_PREFIX=$INSTALLROOT \
	   -DRANGEV3_INCLUDE_DIR=$RANGEV3_ROOT/include \
	   -DCPPGSL_INCLUDE_DIR=$CPPGSL_ROOT/include \
	   -DCPPUNIT_INCLUDE_DIR=$CPPUNIT_ROOT/include -DCPPUNIT_LIBRARY=$CPPUNIT_ROOT/lib/libcppunit.so \
           -DGAUDI_USE_HEPPDT=ON \
           -DGAUDI_USE_AIDA=OFF \
           -DGAUDI_USE_DOXYGEN=OFF \
           -DGAUDI_USE_GPERFTOOLS=FALSE \
           -DCMAKE_FIND_FRAMEWORK=LAST \
           -DBoost_NO_BOOST_CMAKE=FALSE \
           -DCMAKE_CXX_STANDARD=20 \
	   -DBUILD_TESTING=FALSE \
           -DCMAKE_PREFIX_PATH="$FMT_ROOT;$YAMLCPP_ROOT;$RAPIDYAML_ROOT;$BOOST_ROOT;$VC_ROOT;$CATCH2_ROOT;$SIMPLE_CONDDB_CXX_ROOT;"
}

function Make() {
   cmake --build . -- ${CMAKE_OPTIONS} ${JOBS:+-j$JOBS}
}

function MakeInstall() {
    cmake --install .    
}

