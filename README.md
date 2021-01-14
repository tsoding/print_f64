# print_f64

print_f64 implementation purely in assembly without using any 3rd party dependencies including libc, libm, etc. We are only depending on Linux syscalls: `sys_write`, `sys_exit`.

## Quick Start

Build dependencies:
- [nasm](https://www.nasm.us/)

Build:
```console
$ ./build.sh
$ ./print_f64
```

Debug:
```console
$ gdb ./print_f64 -x ./tools/debug.gdb
```

## References

- Steele Jr, Guy L., and Jon L. White. "How to print floating-point numbers accurately." Proceedings of the ACM SIGPLAN 1990 conference on Programming language design and implementation. 1990.
