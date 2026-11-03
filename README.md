# lhcb.bits

LHCb recipes and defaults for [bits](https://github.com/bitsorg/bits). The repository
builds the LCG externals that the LHCb software stack (Gaudi, LHCb, Lbcom, ...) compiles
against, with LHCb's own version pins, and installs an LHCb toolchain so that the usual
LHCb tools (LbEnv, LbDevTools, lb-stack-setup) build against the bits-built externals. It
holds only the LHCb policy and a few LHCb recipes; the externals recipes come from
[lcg.bits](https://github.com/bitsorg/lcg.bits) and the shared base defaults from
[stacks.bits](https://github.com/bitsorg/stacks.bits). `defaults-lhcb.sh` requires
`stacks.bits`, which in turn requires `lcg.bits`; both are fetched automatically through
the [bits-providers](https://github.com/bitsorg/bits-providers) registry, at the branch
named by the LCG release you build (for example `LCG_110`). The files are listed under
[Files](#files).

## Prerequisites

- bits, and one of two setups (see [Installation &
  Prerequisites](https://github.com/bitsorg/bits/blob/main/docs/USERGUIDE.md#2-installation--prerequisites)
  in the bits user guide; `bits doctor` checks the machine):
  - docker or rootless podman, to build in the platform's builder image with `--docker`
    (recommended, and the only way to reuse what the LHCb CI built);
  - or the system packages listed in [Building
    natively](https://github.com/bitsorg/bits/blob/main/docs/USERGUIDE.md#building-natively-what-to-install),
    to build with this machine's compilers and libraries.
- A platform the LHCb CI builds, so that its binaries are reused: `x86_64-el8`,
  `x86_64-el9`, `x86_64-el10`, `aarch64-el9`, `x86_64-ubuntu2204`, `x86_64-ubuntu2404` and
  `x86_64-ubuntu2604`. Pass it as `--architecture`; on one of them, `bits architecture` prints it. See [Finding a platform
  with pre-built
  binaries](https://github.com/bitsorg/bits/blob/main/docs/USERGUIDE.md#finding-a-platform-with-pre-built-binaries).
- `x86_64-el9` also names the install directories and the toolchain like LHCb platforms
  (`x86_64-el9-gcc14-opt`).
- The compiler is chosen with a stacks.bits compiler defaults (e.g. `gcc14`, `gcc15`); the
  build type is `opt` or `dbg`. The externals' versions are LHCb's (see [LHCb
  versions](#lhcb-versions)), the same for every compiler.
- To use the result with the LHCb tools on a machine that is not EL9, an EL9 container,
  e.g. `gitlab-registry.cern.ch/lhcb-docker/os-base/alma9-devel` with the OS package
  `zlib-devel` added (lb-stack-setup's own `el9-build` image is not public).
- To build LHCb projects against the result: `/cvmfs/lhcb.cern.ch` for LbEnv and for the
  LHCb `lcg-toolchains` fragments (or set `LCG_TOOLCHAINS_DIR`), and
  [lb-stack-setup](https://gitlab.cern.ch/lhcb-core/dev-tools/lb-stack-setup) or
  LbDevTools.

## Getting started

### Using the published externals

The LHCb externals are published on CVMFS as `lcg-view` releases (now `LCG_110` on
`x86_64-el9`, with gcc14 and gcc15, `opt` and `dbg`), so nothing has to be built or checked
out:

```bash
export BITS_CVMFS_PREFIX=/cvmfs/bits.cern.ch/lhcb
bits q -a x86_64-el9-gcc14-opt lcg-view           # the published versions: lcg-view/LCG_110-<N>
bits enter -a x86_64-el9-gcc14-opt lcg-view/<version>
source setupLHCb.sh                               # in that sub-shell
```

`BITS_CVMFS_PREFIX` names LHCb's tree (with the CVMFS entry point
`/cvmfs/bits.cern.ch/bits/bin/bits`, `bits --community lhcb ...` sets it; in a checkout of
this repository, `cvmfs.yaml` does). `-a` picks one of the published platforms.

`setupLHCb.sh` comes with the `lcg-view` builds made since it moved into the recipe (from
November 2026; `LCG_110-1` and `LCG_110-2` do not have it). Outside `bits enter`, source it
by its path,
`/cvmfs/bits.cern.ch/lhcb/<arch>/Packages/lcg-view/<version>/bin/setupLHCb.sh`.

`bits enter` opens a sub-shell set up from the release view: the externals on the paths,
`LCG_PLATFORM` and `LCG_RELEASE_BASE` set, and `setupLHCb.sh` on `PATH`; leave it with
`exit`. `setupLHCb.sh` sources LbEnv (`/cvmfs/lhcb.cern.ch/lib/LbEnv`) when `lb-run` is not found yet, then sets `BINARY_TAG`,
`LCG_VERSION`, `LCG_RELEASE_BASE` and `CMAKE_PREFIX_PATH`, without LbEnv's
`/cvmfs/lhcb.cern.ch/lib/lcg` and `lib/contrib` (they would supply whatever the view lacks),
and prints the lb-stack-setup settings. `BINARY_TAG` is the `x86_64_v3` variant when the
CPU supports it; another one of the view's toolchains can be given as its argument
(`source setupLHCb.sh x86_64-el9-gcc14-opt`).

### Building Gaudi and the LHCb projects

In the same sub-shell, with [lb-stack-setup](https://gitlab.cern.ch/lhcb-core/dev-tools/lb-stack-setup)
installed as its README describes, apply the settings `setupLHCb.sh` printed and build in
native mode, not in its Docker container:

```bash
cd /path/to/stack
utils/config.py binaryTag <as printed>
utils/config.py lcgVersion <as printed>
utils/config.py cmakePrefixPath '<as printed>'
utils/config.py useDocker false
make Gaudi
```

The settings stay in the stack directory: later it is only `bits enter`, `source
setupLHCb.sh` and `make`. lb-stack-setup checks out the projects' default branches; the
versions this repository's recipes pin ([The LHCb projects as bits
packages](#the-lhcb-projects-as-bits-packages)) are the ones that go with these externals.
LbDevTools works the same way after `source setupLHCb.sh`.

### Building the externals yourself

Only to change the externals, in a checkout of this repository:

```bash
bits init lhcb.bits && cd lhcb.bits     # or: git clone https://github.com/bitsorg/lhcb.bits
bits use --architecture x86_64-el9 --defaults lhcb::gcc14::opt
bits use build --docker --set release=LCG_110
bits build --dry-run lcg-view           # optional: what would be reused and what built
bits build lcg-view                     # all LHCb externals, then the manifest and toolchain
bits enter lcg-view/latest              # sub-shell with the externals loaded; leave with `exit`
source setupLHCb.sh                     # then as above
```

`bits use` records the options once for this directory (saved in `./.bitsuse`): the
platform and the defaults for every command, so `bits q` and `bits enter` find this build,
the rest for `bits build`. `--docker` builds in the platform's builder image, and reuses
what the CI built; on a machine of the same platform `bits enter` then works here. Without
it, bits builds with this machine's compilers and system packages, and reuses nothing the
CI built. To build elsewhere, `export BITS_WORK_DIR=/path/to/sw`.

`--defaults lhcb::gcc14::opt` loads the stacks.bits `release` base, this repository's
`lhcb` overlay, and the stacks.bits `gcc14` and `opt` profiles. `--set release=LCG_110`
selects the `LCG_110` branches of lcg.bits and stacks.bits and versions `lcg-view`;
`lcg-view` refuses a value that is not an LCG release. To build only the externals, without
the manifest and toolchain, build `lcg-externals` instead.

### The LHCb projects as bits packages

The projects up to DaVinci also build as bits packages, at the versions of the LHCb stack
`RTA/2026.08.30` (LCG 108c, in
[lhcbstacks](https://gitlab.cern.ch/lhcb-core/lhcbstacks/-/blob/master/data/stacks/RTA/2026.08.30.yml)):

| Project | Version | Project | Version |
|---|---|---|---|
| Gaudi | `v40r5` | Rec | `v41r1` |
| Detector | `v3r17` | Allen | `v9r1` (CPU) |
| LHCb | `v60r1` | Moore | `v60r1` |
| Lbcom | `v40r1` | DaVinci | `v68r1` |

with the data packages they look for, at their versions of that date: FieldMap `v5r11`,
ParamFiles `v8r72`, PRConfig `v1r116`, RawEventFormat `v1r10p1`, TCK/HltTCK `v3r19p29`,
TMVAWeights `v1r20`, AppConfig `v3r469`, SprucingConfig `v26r7p2` and QMTestFiles `v1r3`.
New, and not built by the CI yet. In a checkout of this repository:

```bash
bits use --architecture x86_64-el9 --defaults lhcb::gcc15::opt
bits use build --docker
bits build Gaudi                        # its externals, then Gaudi; or any project up to DaVinci
bits enter Gaudi/latest
```

A project needs neither `lcg-view` nor an LCG release: it builds against the lcg.bits and
stacks.bits branches `release` names (`main` by default, or `--set release=LCG_110`). To
build against another lcg.bits branch, a pull request's for example, add
`--set lcg_branch=<branch>`. Each project is configured with `bits-toolchain.cmake`
from `lhcb-toolchains` (`CMAKE_TOOLCHAIN_FILE`): LHCb's compilation flags for the platform
(`opt`, `dbg` or `opt+g`), the build's GCC-Toolchain and its dependencies from
`CMAKE_PREFIX_PATH`. It builds with Ninja, without the tests and, for Rec, Moore and
DaVinci, without the functor caches (`BUILD_FUNCTOR_CACHE=OFF`; functors are compiled when
first used). A recipe requires the project below it, the externals of its
`cmake/<Project>Dependencies.cmake`, the Python modules its python packages import and the
data packages it finds with `find_data_package`. A data package is installed as `<prefix>/<name>/<version>`, where
`find_data_package` looks, and its module sets what its `.xenv` sets. A project's module
adds its `python`, `include` and `lib` to `PYTHONPATH`, `ROOT_INCLUDE_PATH` and
`GAUDI_PLUGIN_PATH`, and sets the variables the installed project needs at run time
(`DETECTOR_PROJECT_ROOT`, the functor compiler's, `ALLEN_INSTALL_DIR`, and LHCb's
`PYTHONHASHSEED=0` and thread limits); those that point into a project's sources, such as
`STDOPTS`, are not set. DD4hep is built with Geant4 units, which Detector requires: the
`dd4hep_geant4_units` variable in `defaults-lhcb.sh` turns on a patch of lcg.bits' DD4hep
recipe (lcg.bits needs that patch first). Two packages need the network while they build:
`simple_conddb_cxx` (its CMake fetches Corrosion and CLI11, and cargo its crates) and
TCK/HltTCK (its Makefile downloads the TCK database, about 280 MB, checked against its
sha256 in git). As LHCb releases them, x86_64 builds are for `x86_64_v3`
(`-march=x86-64-v3`, `LHCB_PLATFORM` `x86_64_v3-el9-…`): the build host and the machines
running them need AVX2. `-DLCG_ARCHITECTURE=x86_64_v2` in a recipe's Configure lowers it
(Detector needs at least SSE4.2, so not the baseline `x86_64`).

To move to another stack, take the project tags from its file in lhcbstacks and the data
packages' tags of its date, in these recipes.

## LHCb versions

The externals are built at the versions of LHCb's own LCG flavour (now `LCG_108c`
`LHCB_11`), not those of the LCG release the recipes come from. `defaults-lhcb.sh` carries
them as overrides, generated between two marker lines by `tools/lcg-deltas.py` from
LHCb's [lcg-toolchains](https://gitlab.cern.ch/lhcb-core/lcg-toolchains); entries written by
hand outside the markers win (the LHCb projects, the LHCb generator variants). To move to
another flavour, regenerate:

```bash
git clone https://gitlab.cern.ch/lhcb-core/lcg-toolchains.git ../lcg-toolchains
bits status --json --architecture x86_64-el9 --defaults lhcb::gcc14::opt \
    --set release=LCG_110 lcg-externals > /tmp/closure.json    # bits with status --set
tools/lcg-deltas.py --lcginfo ../lcg-toolchains/LCG_108c/lcginfo.json --flavour LHCB_11 \
    --platform x86_64-el9-gcc15-opt --recipes ../lcg.bits --closure /tmp/closure.json \
    --check-urls --write
```

`--recipes` is an lcg.bits checkout at the release branch (`LCG_110`). `--closure` limits the
overrides to what `lcg-externals` builds; `--check-urls` checks each new source tarball
exists. Without `--write` the block is printed. The script reports what it leaves alone: LCG
packages with no lcg.bits recipe or outside the closure, overrides written by hand that
differ from LCG, and packages kept at the lcg.bits version because its patches are for that
version or LHCb's is a patched build (`3.3.1.lhcb1`) lcg.bits has no patch for. It exits 1
when a tag or source does not follow the version: that needs an override by hand.

## Notes for LHCb users

- **Releases.** The release comes from the command line; the default `main` follows the
  main branches of lcg.bits and stacks.bits; `lcg_branch` moves lcg.bits alone. The
  versions are LHCb's in any case ([LHCb versions](#lhcb-versions)).
- **CVMFS layout.** Builds publish under `/cvmfs/bits.cern.ch/lhcb` with the shared
  [stacks.bits layout](https://github.com/bitsorg/stacks.bits#cvmfs-layout); only the
  prefix differs. When `lcg-view` is published, its manifest is rewritten to the published
  package paths.
- **Publishing** is done from [bits-console](https://gitlab.cern.ch/buncic/bits-console).
  The prefix `/cvmfs/bits.cern.ch/lhcb` in `cvmfs.yaml` must match the `cvmfs_prefix`
  bits-console sets for LHCb; a build whose prefix disagrees refuses to publish.
- **Developing a package.** Inside this repository, `bits init -c . <pkg>` makes a writable
  checkout that the next `bits build` uses; see the
  [Cookbook](https://github.com/bitsorg/bits/blob/main/docs/COOKBOOK.md#develop-and-iterate-on-a-single-package).

## Files

| File | Role |
|---|---|
| `defaults-lhcb.sh` | LHCb overlay on the stacks.bits base: the versions of LHCb's LCG flavour (generated), LHCb generator variants, and DD4hep built minimal (Geant4, LCIO and EDM4hep disabled) with Geant4 units. The CVMFS layout is in `cvmfs.yaml`. |
| `tools/lcg-deltas.py` | Writes the version overrides of `defaults-lhcb.sh` from LHCb's `lcg-toolchains` ([LHCb versions](#lhcb-versions)). |
| `lcg-externals.sh` | Meta-package: LHCb's top-level LCG externals. |
| `lcg-view.sh` | Top of the externals build: writes `LCG_externals_<platform>.txt`, the LHCb toolchain `lcg-toolchains/LCG_<N>/<platform>.cmake` (plus an `x86_64_v3` variant) and `bin/setupLHCb.sh`, which points LbEnv / lb-stack-setup at it. |
| `gaudi.sh`, `detector.sh`, `lhcb.sh`, `lbcom.sh`, `rec.sh`, `allen.sh`, `moore.sh`, `davinci.sh` | The LHCb projects up to DaVinci ([The LHCb projects as bits packages](#the-lhcb-projects-as-bits-packages)). |
| `fieldmap.sh`, `paramfiles.sh`, `prconfig.sh`, `raweventformat.sh`, `hlttck.sh`, `tmvaweights.sh`, `appconfig.sh`, `sprucingconfig.sh`, `qmtestfiles.sh` | The LHCb data packages the projects find. |
| `lhcb-toolchains.sh`, `simple_conddb_cxx.sh` | LHCb's toolchain fragments (its lcg-toolchains repository), which the `lcg-view` toolchain includes, with `bits-toolchain.cmake`, which the projects build with; and the conditions reader Detector uses. |
| `python.sh`, `gdbm.sh` | Temporary: lcg.bits' Python with GNU dbm (static), so that Python 3.12 writes Gaudi's `Gaudi.confdb2` with `dbm.gnu`. |

## More information

- [lb-stack-setup](https://gitlab.cern.ch/lhcb-core/dev-tools/lb-stack-setup): LHCb stack
  development tools; bits [bits enter](https://github.com/bitsorg/bits/blob/main/docs/REFERENCE.md#bits-enter)
  and [Docker Support](https://github.com/bitsorg/bits/blob/main/docs/REFERENCE.md#22-docker-support)
- [stacks.bits](https://github.com/bitsorg/stacks.bits#readme) and
  [lcg.bits](https://github.com/bitsorg/lcg.bits#readme) READMEs: profiles, releases,
  CVMFS layout and the recipe pool; [bits-providers](https://github.com/bitsorg/bits-providers): the registry
- bits [User Guide](https://github.com/bitsorg/bits/blob/main/docs/USERGUIDE.md),
  [Cookbook](https://github.com/bitsorg/bits/blob/main/docs/COOKBOOK.md),
  [Reference](https://github.com/bitsorg/bits/blob/main/docs/REFERENCE.md)
- [bits-console](https://gitlab.cern.ch/buncic/bits-console): CI builds and CVMFS publishing

## License

This repository does not contain a LICENSE file yet.
