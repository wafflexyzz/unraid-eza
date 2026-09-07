# unraid-eza

This is an eza plugin for **Unraid 7+**.

<img src="./assets/unraid-eza.png"/>

## description

eza is a modern replacement for the venerable file-listing command-line program ls that ships with Unix and Linux operating systems, giving it more features and better defaults. It uses colours to distinguish file types and metadata. It knows about symlinks, extended attributes, and Git. And it’s small, fast, and just one single binary.

By deliberately making some decisions differently, eza attempts to be a more featureful, more user-friendly version of ls. For more information, see [the eza repository](https://github.com/eza-community/eza).

## Build locally

The plugin can be built without Drone using Docker. Docker Desktop (or another
Docker-compatible runtime) is required because the package contains an
x86_64 Linux binary and is created with Slackware's `makepkg`.

```sh
./build.sh v0.23.5
```

The version defaults to the version in `unraid-eza.plg` when omitted. The
script initializes the `eza` submodule, checks out the matching eza tag,
builds and smoke-tests the binary, and writes these files to `dist/`:

- `unraid-eza-v0.23.5.txz`
- `md5sum.txt`

Tag versions follow eza releases.

## credits

Originally based on the unraid-exa plugin created by [dtomlinson91](https://github.com/dtomlinson91).
