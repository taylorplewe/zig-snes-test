# Zig SNES
Template for using zig on the SNES with batteries included.
This uses [llvm-mos-bootstrap](https://github.com/kassane/zig-mos-bootstrap) to accomplish this.

## NOTE
This is very very WIP! Don't expect any stability!

## Building
All you need is to have Docker and [scuba](https://github.com/JonathonReinhart/scuba) installed.
After this, run `scuba build`, and an ELF and ROM will be output in the `zig-out/bin` folder.
If `scuba build` results in an `AccessDenied` error, ensure your folder is set to recursively allow other users to modify content.
