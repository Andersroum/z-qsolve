# Z-qsolve
A quadratic equation solver written in Zig.
Solves equations in the form `ax² + bx + c = 0` and outputs exact results using fractions, square roots, and complex numbers.
## Usage
```sh
zig run main.zig -- <a> <b> <c>
```
Inputs can be integers, fractions (`1/2`), or decimals (`5.34`).
## Examples
```sh
$ zig run main.zig -- 1 -5 6
```
```text
this quadratic has two real solutions:
      3 ± 1
```
```sh
$ zig run main.zig -- 4 -4 5
```
```text
this quadratic has complex solutions:
      1/2 ± 1i
```
```sh
$ zig run main.zig -- 1/2 -1/3 5/6
```
```text
this quadratic has complex solutions:
      1/3 ± (1/3)i√14
```
