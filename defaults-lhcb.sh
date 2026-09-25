package: defaults-lhcb
version: v1

# LHCb group overlay — compose with:  --defaults lhcb[::gcc14]
#
# Adds only LHCb policy on top of the shared stacks.bits base: the LHCb CVMFS
# namespace/layout and the LHCb version pins. No env: and no package_family —
# both are hashed, and inheriting them unchanged keeps every untouched LCG
# external reusable across stacks.
#
# The release comes from the command line (--set release=LCG_110); `main` is
# only the default. Same rule in every stacks.bits-based overlay.

variables:
  release: "main"

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
  cvmfs_releases_template:    "{prefix}/{release}/{pkg}/{tag}/{platform}"
  cvmfs_modules_template:     "{prefix}/{release}/{platform}/Modules/modulefiles/{pkg}"
  cvmfs_shared_path_template: "{prefix}/{release}/noarch/{pkg}/{tag}"

overrides:
  # Recipe pool and policy layer at the branch named by `release`.
  lcg.bits:
    tag: "%(release)s"
  stacks.bits:
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

  # LHCb-patched generators (.lhcb arms in lcg.bits, version-gated). Same upstream
  # tarball as the base/.atlas build; only the source patch differs.
  photoscpp:
    version: "3.64.lhcb"
    tag: "v3.64.lhcb"
  tauolacpp:
    version: "1.1.9.lhcb"
    tag: "v1.1.9.lhcb"
  crmc:
    version: "2.0.1p6.lhcb"
    tag: "2.0.1p6.lhcb"
  # madgraph diverges (LHCb 3.5.9.atlas13 vs base/ATLAS 3.5.11.atlas16): the
  # override carries the alternative 3.5.9 source; the recipe's version-gated
  # 3.5.9.atlas13 patch arm then activates.
  madgraph5amc:
    version: "3.5.9.atlas13"
    tag: "3.5.9.atlas13"
    sources:
      - https://lcgpackages.web.cern.ch/tarFiles/sources/MCGeneratorsTarFiles/MG5_aMC_v3.5.9.tar.gz

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
