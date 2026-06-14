# Homebrew tap for OpenMX

This tap installs OpenMX 4.0.1, data files, examples, and the auxiliary
utilities shipped in the upstream source tree from the official OpenMX
distribution URL and the official 4.0.1 patch.

## Install

```sh
brew install miz77/openmx/openmx
```

You can also tap the repository first:

```sh
brew tap miz77/openmx
brew install openmx
```

The GitHub repository for this tap should be named `miz77/homebrew-openmx`.
Homebrew maps that repository to the tap name `miz77/openmx`.

## Utilities

OpenMX utilities such as `DosMain`, `cohp`, `jx`, `cube2xsf`, `cif2omx`, and
`diff_geo` are installed into Homebrew's normal `bin` directory with their
upstream names. This tap does not add prefixed wrapper commands.

## Maintainer checks

The tap CI intentionally runs a broader pre-submission matrix than a
Homebrew/core pull request should carry. When preparing a core PR, copy only the
formula changes into `homebrew/core` and leave this tap workflow behind.

```sh
brew untap miz77/openmx 2>/dev/null || true
brew tap miz77/openmx "$PWD"
brew style miz77/openmx/openmx
brew audit --strict --new --online miz77/openmx/openmx
HOMEBREW_NO_INSTALL_FROM_API=1 brew install --build-from-source --verbose miz77/openmx/openmx
brew test miz77/openmx/openmx
brew linkage --test --strict miz77/openmx/openmx
```

Before opening a Homebrew/core pull request from a local `homebrew/core` checkout:

```sh
HOMEBREW_NO_INSTALL_FROM_API=1 brew install --build-from-source openmx
brew lgtm --online
```

Disclose AI/LLM assistance in the initial Homebrew PR text if any generated code
or prose is used.

## License

OpenMX itself is distributed by the OpenMX authors under GPLv3. This tap does
not redistribute OpenMX source archives or binaries; it points Homebrew to the
official upstream download URLs.

The tap metadata and Formula code in this repository are licensed under the MIT
License. That MIT license does not apply to OpenMX itself.
