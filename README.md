# lhcb.bits
Repository for LHCb specific package recipes 

## Building LHCb software against the bits LCG stack

Build the externals with `bits build lcg-view --defaults release::lhcb::gcc14::opt --set release=LCG_110`.
`lcg-view` installs the LCG manifest plus an LHCb toolchain
(`lcg-toolchains/LCG_110/<BINARY_TAG>.cmake`, also as `x86_64_v3-...`) that uses
the bits compiler and externals. After LbEnv, `source setupLHCb.sh` (sets
`BINARY_TAG`, `LCG_VERSION`, `CMAKE_PREFIX_PATH`) and build with LbDevTools /
lb-stack-setup as usual (native, not docker). On a CVMFS publish the manifest is
rewritten to the packages' published paths (`etc/profile.d/post-relocate.sh`). LHCb's lcg-toolchains fragments are taken from
`LCG_TOOLCHAINS_DIR` (default `/cvmfs/lhcb.cern.ch/lib/lhcb/lcg-toolchains`).
