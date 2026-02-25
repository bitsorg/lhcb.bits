package: LHCb
version: "%(tag_basename)s"
tag: "2025-patches"
source: https://gitlab.cern.ch/lhcb/LHCb.git
requires:
  - "GCC-Toolchain:(?!osx)"
  - Gaudi
  - Detector
  - GitCondDB
  - libgit2
  - yamlcpp
  - rapidyaml
  - Vc
  - BLAS
  - PyTorch
  - AIDA
  - Eigen3
  - ONNXRuntime
  - abseil
  - vdt
  - ZeroMQ
  - sodium
  - Catch2
  - RELAX
  - rangev3
  - ZeroMQ
  - Clang
  - CLHEP
  - boost
  - Python-modules

#-- Could NOT find FieldMap (missing: FieldMap_ROOT_DIR)
#-- Could NOT find ParamFiles (missing: ParamFiles_ROOT_DIR)
#-- Could NOT find PRConfig (missing: PRConfig_ROOT_DIR)
#-- Could NOT find RawEventFormat (missing: RawEventFormat_ROOT_DIR)
#-- Could NOT find TCK/HltTCK (missing: TCK/HltTCK_ROOT_DIR)
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
  export CXXFLAGS="-I$CLHEP_ROOT/include -I$GAUDI_ROOT/GaudiKernel/include -I$AIDA_ROOT/include $CXXFLAGS"
  export ROOT_INCLUDE_PATH="$ROOT_INCLUDE_PATH:$CLHEP_ROOT/include:$GAUDI_ROOT/GaudiKernel/include"
  cmake -S .. -B . -DCMAKE_INSTALL_PREFIX=$INSTALLROOT \
           -DRANGEV3_INCLUDE_DIR=$RANGEV3_ROOT/include \
           -DCPPGSL_INCLUDE_DIR=$CPPGSL_ROOT/include \
           -DCLHEP_INCLUDE_DIRS=$CLHEP_ROOT/include: \
           -DCPPUNIT_INCLUDE_DIR=$CPPUNIT_ROOT/include \
	   -DCPPUNIT_LIBRARY=$CPPUNIT_ROOT/lib/libcppunit.so \
           -Dabsl_DIR="$ABSEIL_ROOT/lib/cmake/absl" \
           -Donnxruntime_INCLUDE_DIR="$ONNXRUNTIME_ROOT/include" \
           -DGaudiProject_DIR="$GAUDI_ROOT" \
	   -DBUILD_TESTING=FALSE \
  -DCMAKE_PREFIX_PATH="$GAUDI_ROOT;$BOOST_ROOT;$FMT_ROOT;$DETECTOR_ROOT;$GITCONDDB_ROOT;$LIBGIT2_ROOT;$YAMLCPP_ROOT;$RAPIDYAML_ROOT;$VC_ROOT;$BLAS_ROOT;$PYTORCH_ROOT;$AIDA_ROOT;$EIGEN3_ROOT;$ABSEIL_ROOT;$ONNXRUNTIME_ROOT;$VDT_ROOT;$ZEROMQ_ROOT;$SODIUM_ROOT;$CATCH2_ROOT;$RELAX_ROOT;$ZEROMQ_ROOT;$CLHEP_ROOT"
}

function Make() {
    cmake --build . -- ${CMAKE_OPTIONS} ${JOBS:+-j$JOBS}
}

function MakeInstall() {
    cmake --install .   
}
