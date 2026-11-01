package: FieldMap
description: LHCb data package FieldMap (magnetic field maps)
version: "%(tag_basename)s"
tag: "v5r11"
source: https://gitlab.cern.ch/lhcb-datapkg/FieldMap.git
build_requires:
  - bits-recipe-tools
  # Its Makefile converts the .cdf maps to the .bin ones LHCb reads, with numpy.
  - Python
  - numpy
---
#!/bin/bash -e
# Installed as <prefix>/FieldMap/<version>, where LHCb's find_data_package looks
# (the module puts <prefix> on CMAKE_PREFIX_PATH); the module sets what its xenv sets.
. $(bits-include ModuleRecipe)
MODULE_OPTIONS="--cmake"
dest="$INSTALLROOT/FieldMap/$PKGVERSION"
mkdir -p "$dest"
rsync -a --exclude .git "$SOURCEDIR"/ "$dest"/
mkdir -p shim && ln -sf "$(command -v python3)" shim/python   # the Makefile calls `python`
PATH="$PWD/shim:$PATH" make -C "$dest" ${JOBS:+-j$JOBS}
MakeModule
cat >> "$MODULEFILE" <<EoF
setenv FIELDMAPROOT \$PKG_ROOT/FieldMap/$PKGVERSION
setenv FIELDMAP \$PKG_ROOT/FieldMap/$PKGVERSION/cdf/field047.cdf
EoF
