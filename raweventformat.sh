package: RawEventFormat
description: LHCb data package RawEventFormat (raw event layouts)
version: "%(tag_basename)s"
tag: "v1r10p1"
source: https://gitlab.cern.ch/lhcb-datapkg/RawEventFormat.git
build_requires:
  - bits-recipe-tools
---
#!/bin/bash -e
# Installed as <prefix>/RawEventFormat/<version>, where LHCb's find_data_package looks
# (the module puts <prefix> on CMAKE_PREFIX_PATH); the module sets what its xenv sets.
. $(bits-include ModuleRecipe)
MODULE_OPTIONS="--cmake"
dest="$INSTALLROOT/RawEventFormat/$PKGVERSION"
mkdir -p "$dest"
rsync -a --exclude .git "$SOURCEDIR"/ "$dest"/
MakeModule
cat >> "$MODULEFILE" <<EoF
setenv RAWEVENTFORMATROOT \$PKG_ROOT/RawEventFormat/$PKGVERSION
prepend-path PYTHONPATH \$PKG_ROOT/RawEventFormat/$PKGVERSION/python
EoF
