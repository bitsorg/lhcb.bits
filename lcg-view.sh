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
env:
  # LbDevTools reads $LCG_RELEASE_BASE/LCG_<ver>/LCG_externals_<platform>.txt. It is
  # this package's install prefix (the dir that contains LCG_<ver>/).
  LCG_RELEASE_BASE: "$LCG_VIEW_ROOT"
  # LCG_PLATFORM is DERIVED in the body from $ARCHITECTURE (opt/dbg already glued on
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
# Release LABEL from the build-wide flavour (same value version_from used above).
release="${release:?lcg-view: 'release' flavour not set — build with --set release=LCG_<N>}"
release="LCG_${release#LCG_}"   # normalize: accept LCG_110 or 110
relnum="${release#LCG_}"        # bare number for --version-number
postfix=""
# LCG platform == the bits arch subtree ($ARCHITECTURE); opt/dbg already glued on.
plat="${LCG_PLATFORM:-${ARCHITECTURE}}"

"${BITS_SCRIPT_DIR:?}/bits" overlay lcg \
    --architecture "$ARCHITECTURE" \
    --work-dir "${WORK_DIR:-${BITS_WORK_DIR:-$PWD}}" \
    --platform "$plat" \
    --version-number "$relnum" \
    --postfix "$postfix" \
    --out "$INSTALLROOT"

# Carry the LCG vars to dependents via the modulefile (--none emits no env:).
MakeModule
cat >> "$MODULEFILE" <<EOF
setenv LCG_RELEASE_BASE  \$PKG_ROOT
setenv LCG_PLATFORM      $plat
EOF
