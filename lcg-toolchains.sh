package: lcg-toolchains
description: LHCb's lcg-toolchains fragments (compiler flags, package handling), and bits-toolchain.cmake that the LHCb projects build with
version: "%(short_hash)s"
tag: "e5d8a399ab8d815e38ee9f1172ed24dbfe890daf"   # master of 2026-07-29 (LHCB_11 added)
source: https://gitlab.cern.ch/lhcb-core/lcg-toolchains.git
build_requires:
  - bits-recipe-tools
license: GPL-3.0-only
env:
  LCG_TOOLCHAINS_DIR: "$LCG_TOOLCHAINS_ROOT"
---
#!/bin/bash -e
. $(bits-include ModuleRecipe)
MODULE_OPTIONS="--root"
rsync -a --exclude .git "$SOURCEDIR"/ "$INSTALLROOT"/

# The LHCb projects' toolchain in a bits build: LHCb's compilation flags for
# LCG_PLATFORM, with the build environment's compiler and dependencies (from
# CMAKE_PREFIX_PATH), so no LCG release or externals manifest is needed.
cat > "$INSTALLROOT/bits-toolchain.cmake" <<\EOF
include_guard(GLOBAL)
cmake_policy(PUSH)
cmake_policy(SET CMP0007 NEW)

if(NOT DEFINED LCG_PLATFORM)
  set(LCG_PLATFORM "$ENV{LCG_PLATFORM}")
endif()
if(NOT LCG_PLATFORM MATCHES "^[^-]+-[^-]+-[^-]+-[^-]+$")
  message(FATAL_ERROR "LCG_PLATFORM '${LCG_PLATFORM}' is not <arch>-<os>-<compiler>-<opt>")
endif()
# try_compile projects re-read this file without the cache: pass it via the env.
set(ENV{LCG_PLATFORM} "${LCG_PLATFORM}")
string(REPLACE "-" ";" _platform_bits "${LCG_PLATFORM}")
set(_i 0)
foreach(_v IN ITEMS ARCHITECTURE OS COMPILER OPTIMIZATION)
  if(NOT DEFINED LCG_${_v})
    list(GET _platform_bits ${_i} LCG_${_v})
  endif()
  math(EXPR _i "${_i} + 1")
endforeach()
if(NOT DEFINED LHCB_PLATFORM)
  set(LHCB_PLATFORM ${LCG_PLATFORM})
endif()
string(REGEX REPLACE "-[^-]+\$" "" LCG_SYSTEM "${LCG_PLATFORM}")
string(REGEX REPLACE "-[^-]+\$" "" LCG_HOST "${LCG_SYSTEM}")
set(FRAGMENTS_DIR "${CMAKE_CURRENT_LIST_DIR}/fragments")

# Compiler: the build environment's GCC-Toolchain, through wrapper scripts as in
# lcg-toolchains (Rec's FunctorCore reads the compiler file as one), which keep the
# environment. ID and version are preset: the flag logic runs before CMake detects it.
set(_gcc_root "$ENV{GCC_TOOLCHAIN_ROOT}")
if(_gcc_root AND EXISTS "${_gcc_root}/bin/g++")
  execute_process(COMMAND "${_gcc_root}/bin/g++" -dumpfullversion
                  OUTPUT_VARIABLE _gcc_version OUTPUT_STRIP_TRAILING_WHITESPACE)
  execute_process(COMMAND "${_gcc_root}/bin/g++" -dumpmachine
                  OUTPUT_VARIABLE _gcc_target OUTPUT_STRIP_TRAILING_WHITESPACE)
  foreach(_pair IN ITEMS C:gcc CXX:g++ Fortran:gfortran)
    string(REPLACE ":" ";" _pair "${_pair}")
    list(GET _pair 0 _lang)
    list(GET _pair 1 _cmd)
    if(EXISTS "${_gcc_root}/bin/${_cmd}")
      file(WRITE "${CMAKE_BINARY_DIR}/toolchain/${_cmd}"
"#!/bin/sh
exec ${_gcc_root}/bin/${_cmd} \"\$@\"
")
      execute_process(COMMAND chmod a+x "${CMAKE_BINARY_DIR}/toolchain/${_cmd}")
      execute_process(COMMAND touch --reference=${_gcc_root}/bin/${_cmd} "${CMAKE_BINARY_DIR}/toolchain/${_cmd}")
      set(CMAKE_${_lang}_COMPILER "${CMAKE_BINARY_DIR}/toolchain/${_cmd}" CACHE FILEPATH "${_lang} compiler")
      set(CMAKE_${_lang}_COMPILER_ID "GNU")
      set(CMAKE_${_lang}_COMPILER_VERSION "${_gcc_version}")
    endif()
  endforeach()
  set(GCC_TOOLCHAIN_ROOT "${_gcc_root}")
  set_property(DIRECTORY ${CMAKE_SOURCE_DIR} APPEND PROPERTY LINK_OPTIONS
               $<HOST_LINK:-Wl$<COMMA>-rpath$<COMMA>${_gcc_root}/lib64>)
  set(_gcc_includes "${_gcc_root}/include/c++/${_gcc_version}:${_gcc_root}/include/c++/${_gcc_version}/${_gcc_target}")
  string(FIND ":$ENV{ROOT_INCLUDE_PATH}:" ":${_gcc_includes}:" _found)
  if(_found EQUAL -1)
    set(ENV{ROOT_INCLUDE_PATH} "${_gcc_includes}:$ENV{ROOT_INCLUDE_PATH}")
  endif()
elseif(CMAKE_HOST_SYSTEM_NAME STREQUAL "Linux")
  message(FATAL_ERROR "No GCC-Toolchain: GCC_TOOLCHAIN_ROOT ('${_gcc_root}') has no bin/g++")
endif()

# Dependencies: bits puts their roots on CMAKE_PREFIX_PATH, ':' or ';' separated.
string(REPLACE ":" ";" _prefixes "$ENV{CMAKE_PREFIX_PATH}")
list(APPEND CMAKE_PREFIX_PATH ${_prefixes})
list(REMOVE_DUPLICATES CMAKE_PREFIX_PATH)
list(FILTER CMAKE_PREFIX_PATH EXCLUDE REGEX "^$")
set(GAUDI_USE_INTELAMPLIFIER FALSE CACHE BOOL "enable IntelAmplifier based profiler in Gaudi")

# Build-time tools (genconf, tests) run through this wrapper with the same env.
file(WRITE ${CMAKE_BINARY_DIR}/toolchain/wrapper
"#!/bin/sh -e
export PATH=$ENV{PATH}
export LD_LIBRARY_PATH=$ENV{LD_LIBRARY_PATH}
export PYTHONPATH=$ENV{PYTHONPATH}
export ROOT_INCLUDE_PATH=$ENV{ROOT_INCLUDE_PATH}
exec \"\$@\"
")
execute_process(COMMAND chmod a+x ${CMAKE_BINARY_DIR}/toolchain/wrapper)

include(${FRAGMENTS_DIR}/compilation_flags.cmake)

set(CMAKE_SYSTEM_NAME ${CMAKE_HOST_SYSTEM_NAME})
set(CMAKE_SYSTEM_PROCESSOR ${CMAKE_HOST_SYSTEM_PROCESSOR})
set(CMAKE_CROSSCOMPILING_EMULATOR ${CMAKE_BINARY_DIR}/toolchain/wrapper)
foreach(_action IN ITEMS COMPILE LINK CUSTOM)
  if(DEFINED CMAKE_RULE_LAUNCH_${_action})
    set_property(GLOBAL PROPERTY RULE_LAUNCH_${_action} "${CMAKE_RULE_LAUNCH_${_action}}")
  endif()
endforeach()

cmake_policy(POP)
EOF

MakeModule
echo "setenv LCG_TOOLCHAINS_DIR \$PKG_ROOT" >> "$MODULEFILE"
