# Homebrew tap for OpenMX

This tap installs the OpenMX 4.0.1 main executable from the official OpenMX
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

## Maintainer checks

```sh
brew style Formula/openmx.rb
brew audit --strict --online Formula/openmx.rb
brew install --build-from-source --verbose ./Formula/openmx.rb
brew test miz77/openmx/openmx
brew linkage --test --strict miz77/openmx/openmx
```

## License

OpenMX itself is distributed by the OpenMX authors under GPLv3. This tap does
not redistribute OpenMX source archives or binaries; it points Homebrew to the
official upstream download URLs.

The tap metadata and Formula code in this repository are licensed under the MIT
License. That MIT license does not apply to OpenMX itself.
