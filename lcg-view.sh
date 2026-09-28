package: lcg-view
description: LHCb LCG externals manifest (LCG_externals_<platform>.txt) over the bits LCG closure, so LbDevTools' toolchain resolves against bits-built packages. Top of the LCG closure (requires lcg-externals) → built last, shares the release build_id; the merged view itself is the release view published by `bits publish --release-view` and reused by `bits enter --view`.
# Versioned by LCG release: version_from: release takes version/tag/commit_hash
# from the build-wide `release` variable (--set release=LCG_<N>) — same value that
# drives defaults-lhcb's `lcg.bits: tag` and the CVMFS {release} slot.
version_from: release
view: true          # `bits enter lcg-view/<version>` auto-collapses paths onto the merged view
requires:
  # lcg-externals is LHCb's top-level LCG closure (dev4lhcb.json). Requiring it puts
  # lcg-view at the TOP of the graph → built LAST, after the whole closure, in the
  # same round (one build_id). `bits overlay lcg` then scans the complete work-dir
  # tree for the manifest. (No injection / no reverse dependency — the natural
  # direction is view → metapackage.)
  - lcg.bits
  - lcg-externals
build_requires:
  - bits-recipe-tools
  - Python
  # The LHCb toolchain below names this compiler (own_hash, so the arch scan misses it).
  - "GCC-Toolchain:(?!osx)"
env:
  # LbDevTools reads $LCG_RELEASE_BASE/LCG_<ver>/LCG_externals_<platform>.txt. It is
  # this package's install prefix (the dir that contains LCG_<ver>/).
  LCG_RELEASE_BASE: "$LCG_VIEW_ROOT"
  # LCG_PLATFORM is DERIVED in the body from $EFFECTIVE_ARCHITECTURE (opt/dbg already glued on
  # by the ::opt/::dbg defaults), so the manifest filename can never drift from the
  # scanned arch subtree. Set LCG_PLATFORM in the build env to override.
---
#!/bin/bash -e
##############################
. $(bits-include ModuleRecipe)
##############################
MODULE_OPTIONS="--none"   # env-only; carries LCG_RELEASE_BASE/LCG_PLATFORM to dependents
##############################
# Emit the LCG externals manifest for the built closure:
#   $INSTALLROOT/LCG_<num>/LCG_externals_<platform>.txt   name;hash;version;dir;deps
# read by LbDevTools' LCG toolchain (field 4 = absolute bits install prefix).
#
# The merged symlink-farm VIEW is NOT built here: it is the release view produced
# by `bits publish --release-view` at publish time (deployment-correct symlinks
# under Views/<build_id>), which `bits enter/setenv --view lcg-view/<ver>` reuses.
# Building it here (bits overlay lcg --build-view) is available for local demos but
# its symlinks are build-time-relative, so it is left out of the release path.
#
# The resolved release: version_from sets PKGVERSION to it however it was chosen.
release="${PKGVERSION:?}"
release="LCG_${release#LCG_}"   # normalize: accept LCG_110 or 110
relnum="${release#LCG_}"        # bare number for --version-number
[[ "$relnum" =~ ^[0-9]+[a-z]?$ ]] || { echo "lcg-view: '$release' is not an LCG release — build with --set release=LCG_<N>" >&2; exit 1; }
postfix=""
# LCG platform == the install subtree ($EFFECTIVE_ARCHITECTURE, e.g. x86_64-el9-gcc14-opt).
# $ARCHITECTURE is the raw host arch (x86_64-el9), which holds no packages.
plat="${LCG_PLATFORM:-${EFFECTIVE_ARCHITECTURE:?}}"

wd="${WORK_DIR:-${BITS_WORK_DIR:-$PWD}}"
"${BITS_SCRIPT_DIR:?}/bits" overlay lcg \
    --architecture "$EFFECTIVE_ARCHITECTURE" \
    --work-dir "$wd" \
    --platform "$plat" \
    --version-number "$relnum" \
    --postfix "$postfix" \
    --out "$INSTALLROOT"
manifest="$INSTALLROOT/$release$postfix/LCG_externals_$plat.txt"

# Per-entry publish identity (the package's own CVMFS templates, version-revision,
# family, arch) for the CVMFS rewrite below; plus the GCC-Toolchain line for the
# LHCb toolchain: own_hash, so it lives under a build-type-neutral arch that the
# overlay scan does not cover.
mkdir -p "$INSTALLROOT/etc/lcg-view"
python3 - "$wd" "$EFFECTIVE_ARCHITECTURE" "$manifest" "$INSTALLROOT/etc/lcg-view/entries.json" <<\PY
import json, os, sys
sys.path.insert(0, os.environ["BITS_SCRIPT_DIR"])
from bits_helpers.overlay.lcg import collect, manifest_line
wd, arch, manifest, out = sys.argv[1:]
records, _, errors = collect(wd, arch)
if errors:
    sys.exit("lcg-view: " + "; ".join(errors))
gcc = os.environ.get("GCC_TOOLCHAIN_ROOT")
if gcc:
    try:
        with open(os.path.join(gcc, ".meta.json")) as fh:
            records["GCC-Toolchain"] = (gcc, json.load(fh))
    except (OSError, ValueError) as exc:
        sys.exit("lcg-view: cannot read GCC-Toolchain .meta.json: %s" % exc)
entries = []
for name, (install_dir, meta) in sorted(records.items()):
    pkg = meta["package"]
    rev = str(pkg.get("revision") or "")
    entry = {
        "name": name,
        "line": manifest_line(name, os.path.abspath(install_dir), meta),
        "pkg": pkg["name"], "version": pkg["version"], "revision": rev,
        "tag": pkg["version"] + ("-" + rev if rev else ""),
        "family": pkg.get("pkg_family") or "",
        "arch": pkg.get("effective_architecture") or arch,
        "templates": meta.get("cvmfs_templates") or {}}
    entries.append(entry)
    if name == "GCC-Toolchain":
        with open(manifest, "a") as fh:
            fh.write(entry["line"] + "\n")
with open(out, "w") as fh:
    json.dump(entries, fh, indent=1)
PY

# On a CVMFS publish (bits cvmfs publish: INSTALL_BASE under /cvmfs, templated
# layout) the manifest must name where the OTHER packages are published. That is
# only known then, so derive it from this package's own final path and template.
cat > "$INSTALLROOT/etc/lcg-view/cvmfs-manifest.py" <<\PY
# lcg-view: rewrite the manifest dirs to the packages' CVMFS publish paths, as
# bits cvmfs publish computes them: each package's own template (release baked
# in), with the run's context (prefix, platform, install_dir, user) recovered by
# matching INSTALL_BASE against this package's own template. Assumes the run
# publishes every package under one root (the community --prefix-fallback).
import json, os, re, sys
root = os.path.join(os.environ["WORK_DIR"], os.environ["PP"])
base = os.environ["INSTALL_BASE"].rstrip("/")
with open(os.path.join(root, ".meta.json")) as fh:
    meta = json.load(fh)
with open(os.path.join(root, "etc/lcg-view/entries.json")) as fh:
    entries = json.load(fh)
CONTEXT = {"prefix": ".+", "platform": "[^/]*", "install_dir": "[^/]*", "user": "[^/]*"}

def fill(tmpl, e):
    fam = e["family"] + "/" if e["family"] else ""
    for k, v in (("pkg", e["pkg"]), ("tag", e["tag"]), ("version", e["version"]),
                 ("revision", e["revision"]), ("family", fam)):
        tmpl = tmpl.replace("{%s}" % k, v)
    return tmpl

def template(e, tm):
    t = (tm.get("shared") or tm.get("path")) if e["arch"] in ("share", "shared") else tm.get("path")
    if not t:
        sys.exit("lcg-view: %s has no CVMFS template" % e["pkg"])
    return t

pkg = meta["package"]
rev = str(pkg.get("revision") or "")
me = {"pkg": pkg["name"], "version": pkg["version"], "revision": rev, "arch": "",
      "tag": pkg["version"] + ("-" + rev if rev else ""), "family": pkg.get("pkg_family") or ""}
pattern = fill(template(me, meta.get("cvmfs_templates") or {}), me)
rx, pos, seen = "", 0, set()
for m in re.finditer(r"\{(\w+)\}", pattern):
    name = m.group(1)
    if name not in CONTEXT:
        sys.exit("lcg-view: unsupported {%s} in CVMFS template %s" % (name, pattern))
    rx += re.escape(pattern[pos:m.start()])
    rx += "(?P=%s)" % name if name in seen else "(?P<%s>%s)" % (name, CONTEXT[name])
    seen.add(name)
    pos = m.end()
rx += re.escape(pattern[pos:])
m = re.fullmatch(rx, base)
if not m:
    sys.exit("lcg-view: %s does not match its template %s" % (base, pattern))
context = m.groupdict()

lines = []
for e in entries:
    d = fill(template(e, e["templates"]), e)
    for k, v in context.items():
        d = d.replace("{%s}" % k, v)
    if re.search(r"\{\w+\}", d):
        sys.exit("lcg-view: unresolved token in %s for %s" % (d, e["pkg"]))
    f = e["line"].split(";")
    f[3] = d
    lines.append(";".join(f))
manifest = sys.argv[1]
with open(manifest + ".tmp", "w") as fh:
    fh.write("\n".join(lines) + "\n")
os.replace(manifest + ".tmp", manifest)
print("lcg-view: %d manifest entries rewritten for %s" % (len(lines), base))
PY
mkdir -p "$INSTALLROOT/etc/profile.d"
cat > "$INSTALLROOT/etc/profile.d/post-relocate.sh" <<EOF
# lcg-view: templated CVMFS publish -> point the manifest at the published packages.
if [ -n "\${BITS_RELOCATE_STRIP_PP:-}" ]; then
  case "\${INSTALL_BASE:-}" in
    /cvmfs/*) python3 "\$WORK_DIR/\$PP/etc/lcg-view/cvmfs-manifest.py" \\
                "\$WORK_DIR/\$PP/$release$postfix/LCG_externals_$plat.txt" ;;
  esac
fi
EOF

# The rest is the LHCb toolchain (Linux, bits GCC-Toolchain).
if [ -n "${GCC_TOOLCHAIN_ROOT:-}" ]; then
case "$plat" in
  *-*-*-*) ;;
  *) echo "lcg-view: platform '$plat' is not <arch>-<os>-<compiler>-<opt>" >&2; exit 1 ;;
esac

# LHCb toolchain. LbDevTools includes lcg-toolchains/LCG_$LCG_VERSION/$BINARY_TAG.cmake
# found on CMAKE_PREFIX_PATH (see setupLHCb.sh): one for the platform and, on
# x86_64, an x86_64_v3 wrapper around it (as in LHCb's lcg-toolchains).
tcdir="$INSTALLROOT/lcg-toolchains/LCG_$relnum$postfix"
mkdir -p "$tcdir"
sed -e "s|@RELEASE@|$release$postfix|g" -e "s|@PLATFORM@|$plat|g" > "$tcdir/$plat.cmake" <<\EOF
# bits LCG toolchain for LHCb, generated by lcg-view. Compiler and externals come
# from the bits manifest next to it; LHCb's lcg-toolchains fragments (package
# environment, compilation flags) are included from LCG_TOOLCHAINS_DIR.
include_guard(GLOBAL)
cmake_policy(PUSH)
cmake_policy(SET CMP0007 NEW)

if(NOT DEFINED LCG_PLATFORM)
  set(LCG_PLATFORM @PLATFORM@)
endif()
set(LCG_VERSION @RELEASE@)
set(LCG_EXTERNALS_FILE "${CMAKE_CURRENT_LIST_DIR}/../../@RELEASE@/LCG_externals_@PLATFORM@.txt")
if(NOT DEFINED LCG_TOOLCHAINS_DIR)
  if(DEFINED ENV{LCG_TOOLCHAINS_DIR})
    set(LCG_TOOLCHAINS_DIR "$ENV{LCG_TOOLCHAINS_DIR}")
  else()
    set(LCG_TOOLCHAINS_DIR /cvmfs/lhcb.cern.ch/lib/lhcb/lcg-toolchains)
  endif()
endif()
# try_compile projects re-read this file without the cache: pass it via the env.
set(ENV{LCG_TOOLCHAINS_DIR} "${LCG_TOOLCHAINS_DIR}")
set(FRAGMENTS_DIR "${LCG_TOOLCHAINS_DIR}/fragments")
if(NOT EXISTS "${FRAGMENTS_DIR}/packages/macros.cmake")
  message(FATAL_ERROR "LHCb lcg-toolchains not found in ${LCG_TOOLCHAINS_DIR} (set LCG_TOOLCHAINS_DIR)")
endif()
message(STATUS "bits toolchain ${LCG_PLATFORM}: ${LCG_EXTERNALS_FILE}")

macro(_bits_dedup_env name)
  string(REPLACE ":" ";" _tmp "$ENV{${name}}")
  list(REMOVE_DUPLICATES _tmp)
  list(FILTER _tmp EXCLUDE REGEX "^$")
  string(REPLACE ";" ":" _tmp "${_tmp}")
  set(ENV{${name}} "${_tmp}")
endmacro()

# Manifest lines: name;hash;version;dir;deps. Skip comments and KEY: headers, and
# what LHCb builds itself or must not take from LCG (as lcg-nightly.cmake does).
file(STRINGS "${LCG_EXTERNALS_FILE}" _lines)
set(LCG_EXTERNALS_DIRS)
unset(_gcc_root)
unset(_python_home)
foreach(_line IN LISTS _lines)
  list(LENGTH _line _n)
  if(_line MATCHES "^#" OR _line MATCHES "^[A-Z]+:" OR _n LESS 4)
    continue()
  endif()
  list(GET _line 0 _name)
  list(GET _line 3 _dir)
  string(TOLOWER "${_name}" _name)
  if(_name STREQUAL "gcc-toolchain")
    set(_gcc_root "${_dir}")
  elseif(_name MATCHES "^(ccache|cmake|gaudi|geant4|git|ninja|xenv|bits-recipe-tools|lcg-externals|lcg-view|defaults-.*|.*\\.bits)$")
    continue()
  else()
    if(_name STREQUAL "python")
      list(GET _line 2 _python_version)
      string(REGEX MATCH "[0-9]+\\.[0-9]+" _python_version "${_python_version}")
      string(REGEX REPLACE "\\..*$" "" GAUDI_USE_PYTHON_MAJOR "${_python_version}")
      set(GAUDI_USE_PYTHON_MAJOR ${GAUDI_USE_PYTHON_MAJOR} CACHE STRING "Major version of Python to use")
      set(_python_home "${_dir}")
    endif()
    list(APPEND LCG_EXTERNALS_DIRS "${_dir}")
  endif()
endforeach()
if(NOT _gcc_root OR NOT EXISTS "${_gcc_root}/bin/g++")
  message(FATAL_ERROR "No usable GCC-Toolchain in ${LCG_EXTERNALS_FILE}")
endif()

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

# Compiler: bits GCC-Toolchain, used directly. ID/version are preset because the
# flag logic below runs before CMake detects the compiler.
execute_process(COMMAND "${_gcc_root}/bin/g++" -dumpfullversion
                OUTPUT_VARIABLE _gcc_version OUTPUT_STRIP_TRAILING_WHITESPACE)
execute_process(COMMAND "${_gcc_root}/bin/g++" -dumpmachine
                OUTPUT_VARIABLE _gcc_target OUTPUT_STRIP_TRAILING_WHITESPACE)
set(GCC_TOOLCHAIN_ROOT "${_gcc_root}")
foreach(_pair IN ITEMS C:gcc CXX:g++ Fortran:gfortran)
  string(REPLACE ":" ";" _pair "${_pair}")
  list(GET _pair 0 _lang)
  list(GET _pair 1 _cmd)
  if(EXISTS "${_gcc_root}/bin/${_cmd}")
    set(CMAKE_${_lang}_COMPILER "${_gcc_root}/bin/${_cmd}" CACHE FILEPATH "${_lang} compiler")
    set(CMAKE_${_lang}_COMPILER_ID "GNU")
    set(CMAKE_${_lang}_COMPILER_VERSION "${_gcc_version}")
  endif()
endforeach()
set_property(DIRECTORY ${CMAKE_SOURCE_DIR} APPEND PROPERTY LINK_OPTIONS
             $<HOST_LINK:-Wl$<COMMA>-rpath$<COMMA>${_gcc_root}/lib64>)
set(ENV{PATH} "${_gcc_root}/bin:$ENV{PATH}")
set(ENV{LD_LIBRARY_PATH} "${_gcc_root}/lib64:$ENV{LD_LIBRARY_PATH}")
set(ENV{ROOT_INCLUDE_PATH} "${_gcc_root}/include/c++/${_gcc_version}:${_gcc_root}/include/c++/${_gcc_version}/${_gcc_target}:$ENV{ROOT_INCLUDE_PATH}")

# Externals: LHCb's own handling (CMAKE_PREFIX_PATH, PATH, LD_LIBRARY_PATH, ...).
include(${FRAGMENTS_DIR}/packages/macros.cmake)
_init_from_env()
foreach(_dir IN LISTS LCG_EXTERNALS_DIRS)
  _add_lcg_entry("${_dir}")
endforeach()
_add_lbenv_workspace(${LHCB_PLATFORM})
_update_env()
_fix_pkgconfig_search()
if(_python_home)
  _set_pythonhome("${_python_home}")
endif()
foreach(_var IN ITEMS PATH LD_LIBRARY_PATH ROOT_INCLUDE_PATH PYTHONPATH PKG_CONFIG_PATH)
  _bits_dedup_env(${_var})
endforeach()
set(GAUDI_USE_INTELAMPLIFIER FALSE CACHE BOOL "enable IntelAmplifier based profiler in Gaudi")

# Build-time tools (genconf, tests) run through this wrapper with the same env.
file(WRITE ${CMAKE_BINARY_DIR}/toolchain/wrapper
"#!/bin/sh -e
export PATH=$ENV{PATH}
export LD_LIBRARY_PATH=$ENV{LD_LIBRARY_PATH}
export PYTHONPATH=$ENV{PYTHONPATH}
export PYTHONHOME=$ENV{PYTHONHOME}
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
case "$plat" in
  x86_64-*)
    v3="x86_64_v3-${plat#x86_64-}"
    cat > "$tcdir/$v3.cmake" <<EOF
include_guard(GLOBAL)
if(NOT DEFINED LHCB_PLATFORM)
  set(LHCB_PLATFORM $v3)
endif()
if(NOT DEFINED LCG_ARCHITECTURE)
  set(LCG_ARCHITECTURE x86_64_v3)
endif()
include(\${CMAKE_CURRENT_LIST_DIR}/$plat.cmake)
EOF
    ;;
esac
else
  echo "lcg-view: no GCC-Toolchain; LHCb toolchain not generated" >&2
fi

# Carry the LCG vars to dependents via the modulefile (--none emits no env:).
MakeModule
cat >> "$MODULEFILE" <<EOF
setenv LCG_RELEASE_BASE  \$PKG_ROOT
setenv LCG_PLATFORM      $plat
EOF
