package: defaults-lhcb
version: v1

# LHCb group overlay — compose with:  --defaults lhcb[::gcc14]
#
# Adds only LHCb-specific policy on top of the shared stacks.bits defaults
# (build env, source/sandbox policy, and the lcg.bits externals provider): the
# LHCb CVMFS namespace/layout, the LHCb package families, and the LHCb project
# version pins. lhcb.bits drops its own defaults-release.sh and inherits the
# shared one from stacks.bits, so LHCb builds against the same reusable LCG
# externals base as every other stack. stacks.bits -> lcg.bits is LHCb's ONLY
# external-provider dependency; the residual common.bits references in the
# project recipes (gaudi, ...) are being migrated onto the lcg.bits base.

env:
  CFLAGS: -fPIC -O2
  CMAKE_BUILD_TYPE: RELWITHDEBINFO
  CXXFLAGS: -fPIC -O2 -std=c++20
  CXXSTD: '20'
  MACOSX_DEPLOYMENT_TARGET: '14.0'

requires:
  - stacks.bits

# LHCb CVMFS namespace + layout (system: is NOT hashed, so it never affects
# artifact reuse). Kept here — overriding the templates inherited from
# stacks.bits — so lhcb.bits can drop its own defaults-release.sh while still
# publishing into the LHCb tree with LHCb's path templates.
system:
  # {prefix} is the releases ROOT (auth boundary). bits-console (ui-config.yaml:
  # cvmfs_prefix) injects the authoritative value, which WINS; the value below MUST
  # match it (kept in sync by bits-admin PR) or an injected build refuses to publish.
  prefix:                     "/cvmfs/bits.cern.ch/lhcb/releases"
  cvmfs_user_prefix:          "/cvmfs/bits.cern.ch/lhcb/user"  # sibling of releases, not {prefix}/user
  cvmfs_releases_template:    "{prefix}/{pkg}/{tag}/{platform}"
  cvmfs_modules_template:     "{prefix}/{platform}/Modules/modulefiles/{pkg}"
  cvmfs_shared_path_template: "{prefix}/noarch/{pkg}/{tag}"

package_family:
  default: externals
  lcg:
    - ROOT
  lhcb:
    - Gaudi

overrides:
  # Build lcg.bits at the selected release branch (--flavour release=<X>, e.g.
  # LCG_110). Must be in this configDir overlay: the provider is cloned on the
  # early path before stacks.bits' defaults-release is applied, so the override
  # has to be here (mirrors defaults-atlas.sh).
  lcg.bits:
    tag: "%(release)s"

  # --- LHCb externals deltas vs the LCG_110 base (from heptools-dev4lhcb) ---
  # Core externals the LHCb software (Gaudi v40r2, LHCb v58r8, ...) compiles
  # against; LHCb pins these OLDER than the LCG_110 base. ROOT <6.40 is handled
  # by lcg.bits/ROOT.sh; Boost is a plain tarball pin. (hepmc3 3.3.1 already
  # matches the base, so no override.) DD4hep is pinned to 01.36 and built
  # minimal via the disable: block below. Generator .lhcb variants are separate
  # recipe work (patches to port from lcgcmake).
  ROOT:
    version: "v6.36.04"
    tag: "v6-36-04"
  Boost:
    version: "1.89.0"
    tag: "1.89.0"
  DD4hep:
    version: "v01-36"
    tag: "v01-36"

  Gaudi:
    tag: "v40r2"
  Detector:
    tag: "v3r9"
  LHCb:
    tag: "v58r8"
  Lbcom:
    tag: "v38r8"
  Rec:
    tag: "v39r8"
  Allen:
    tag: "v7r8"

# LHCb DD4hep is built minimal (ROOT/XercesC geometry only), like lcgcmake's
# heptools-lhcbsetup. Disabling these backends prunes them from DD4hep's requires
# (and thus from the externals closure — none are LHCb top-level externals in
# dev4lhcb.json); lcg.bits/DD4hep.sh then sets -DDD4HEP_USE_* OFF automatically
# because their <PKG>_ROOT is unset. (podio drops out with EDM4hep/LCIO.)
disable:
  - Geant4
  - LCIO
  - EDM4hep
---
