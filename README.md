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
  `x86_64-ubuntu2604`. Pass it as `--architecture`: by itself bits names a machine after
  its OS (an EL9 machine `slc9_x86-64`), which is not one of them. See [Finding a platform
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

```bash
bits init lhcb.bits && cd lhcb.bits     # or: git clone https://github.com/bitsorg/lhcb.bits
bits use --architecture x86_64-el9 --defaults lhcb::gcc14::opt
bits use build --docker --set release=LCG_110
bits build --dry-run lcg-view           # optional: what would be reused and what built
bits build lcg-view                     # all LHCb externals, then the manifest and toolchain
bits enter lcg-view/latest              # sub-shell with the externals loaded; leave with `exit`
```

`bits use` records the options once for this directory (saved in `./.bitsuse`): the
platform and the defaults for every command, so `bits q` and `bits enter` find this build,
the rest for `bits build`. `--docker` builds in the platform's builder image; on a machine
of the same platform `bits enter` then works here. Without it, bits builds with this
machine's compilers and system packages, and reuses nothing the CI built. To build
elsewhere, `export BITS_WORK_DIR=/path/to/sw`.

`--defaults lhcb::gcc14::opt` loads the stacks.bits `release` base, this repository's
`lhcb` overlay, and the stacks.bits `gcc14` and `opt` profiles. `--set release=LCG_110`
selects the `LCG_110` branches of lcg.bits and stacks.bits and versions `lcg-view`;
`lcg-view` refuses a value that is not an LCG release. To build only the externals, without
the manifest and toolchain, build `lcg-externals` instead.

### Building LHCb software against the result

After the usual LbEnv setup, source `setupLHCb.sh` from this repository. It takes
`sw/<arch>/lcg-view/latest`, or when nothing is built there the newest `lcg-view` published
under the `prefix:` of `cvmfs.yaml` (`/cvmfs/bits.cern.ch/lhcb/<arch>/Packages/lcg-view`).
It sets `BINARY_TAG`, `LCG_VERSION`, `LCG_RELEASE_BASE` and `CMAKE_PREFIX_PATH`, without
LbEnv's `/cvmfs/lhcb.cern.ch/lib/lcg` and `lib/contrib` (they would supply whatever the
view lacks), and prints the lcg-view's real path and the matching lb-stack-setup settings:

```bash
source /cvmfs/lhcb.cern.ch/lib/LbEnv
source setupLHCb.sh                   # optional argument: a BINARY_TAG from the toolchain directory
```

`BINARY_TAG` defaults to the `x86_64_v3` variant when the CPU supports it. If the work
directory is not `sw/` in this repository, or there is more than one `lcg-view`, set `BITS_SW`
and `BITS_ARCH` (e.g. `x86_64-el9-gcc14-opt`); `BITS_CVMFS_PREFIX` sets another CVMFS
prefix, and empty never uses CVMFS. Then build with LbDevTools or lb-stack-setup
as usual, in native mode (`useDocker false`), not in its Docker container.

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
  main branches of lcg.bits and stacks.bits. The versions are LHCb's in any case
  ([LHCb versions](#lhcb-versions)).
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
| `defaults-lhcb.sh` | LHCb overlay on the stacks.bits base: the versions of LHCb's LCG flavour (generated), LHCb generator variants, tags for Gaudi, Detector, LHCb and Lbcom, and DD4hep built minimal (Geant4, LCIO and EDM4hep disabled). The CVMFS layout is in `cvmfs.yaml`. |
| `tools/lcg-deltas.py` | Writes the version overrides of `defaults-lhcb.sh` from LHCb's `lcg-toolchains` ([LHCb versions](#lhcb-versions)). |
| `lcg-externals.sh` | Meta-package: LHCb's top-level LCG externals. |
| `lcg-view.sh` | Top of the externals build: writes `LCG_externals_<platform>.txt` and the LHCb toolchain `lcg-toolchains/LCG_<N>/<platform>.cmake` (plus an `x86_64_v3` variant). |
| `setupLHCb.sh` | Points LbEnv / lb-stack-setup at the bits-built `lcg-view`, local or on CVMFS. |
| `gaudi.sh`, `detector.sh`, `lhcb.sh`, `lbcom.sh`, `simple_conddb_cxx.sh` | Recipes for the LHCb projects themselves. Work in progress; build the projects with lb-stack-setup (below). |

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
