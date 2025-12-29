# Dart `dart test` exit-time segfault when using sqlite3 (ormed_sqlite)

## Summary
Running `dart test` for this repo completes successfully, prints “All tests passed!”, and then the Dart VM segfaults during process shutdown. Running each test file in its own `dart test` process avoids the crash.

This looks like a native teardown/finalizer issue rather than a Dart exception.

## Environment
- OS: Linux x64
- Dart SDK: 3.10.4 (stable) (Tue Dec 9 00:01:55 2025 -0800)
- Packages:
  - `ormed_sqlite: ^0.1.0-dev+5`
  - `sqlite3: ^3.1.1`
- Project: local CLI tool using SQLite via ormed/ormed_sqlite.

## Reproduction
```bash
dart pub get
dart test
```

## Expected
`dart test` exits cleanly with exit code 0 after all tests pass.

## Actual
`dart test` reports all tests passing, then crashes during process shutdown:
```
00:07 +56: All tests passed!

===== CRASH =====
si_signo=Segmentation fault(11), si_code=SEGV_MAPERR(1), si_addr=0xb390
version=3.10.4 (stable) (Tue Dec 9 00:01:55 2025 -0800) on "linux_x64"
pid=177598, thread=177598, isolate_group=(nil)((nil)), isolate=(nil)((nil))
os=linux, arch=x64, comp=no, sim=no
isolate_instructions=0, vm_instructions=0
fp=7ffc45dfe330, sp=7ffc45dfe308, pc=b390
  pc 0x000000000000b390 fp 0x00007ffc45dfe330 Unknown symbol
  pc 0x00007f9e2b5e916e fp 0x00007ffc45dfe3d0 /lib64/ld-linux-x86-64.so.2+0x616e
  pc 0x00007f9e2b240c71 fp 0x00007ffc45dfe430 /usr/lib/libc.so.6+0x40c71
  pc 0x00007f9e2b240d4e fp 0x00007ffc45dfe440 exit+0x1e
  pc 0x00005633b2fd40a9 fp 0x00007ffc45dfe460 /.../dartvm+0x20b50a9
  ...
```

## Notes / Observations
- Crash happens **after** tests pass, during process exit, with `isolate=(nil)`.
- Running **individual test files** does **not** crash:
  ```bash
  dart test test/history_db_test.dart
  dart test test/cli_daemon_test.dart
  ```
- Running the whole suite **always** crashes.
- This points to native resource teardown/finalizers, likely in `sqlite3`.

## Workaround
Run each test file in a separate process:
```bash
dart run tool/run_tests.dart
```

This avoids the crash because each suite has its own VM lifecycle.

## Project context (what uses sqlite3)
- Each test opens/closes SQLite connections via `ormed_sqlite`’s `SqliteDriverAdapter` and `DataSource`.
- We already call `HistoryDb.close()` (which calls `DataSource.dispose()`).
- The VM still crashes at shutdown.

## Suspected root cause
Likely a native finalizer or teardown path in `sqlite3` (or its Dart FFI wrappers) running after the Dart isolate is gone.

## What I tried
- Ensured all `HistoryDb` instances are closed.
- Avoided watcher threads; tests run sequentially (`dart test -j 1`) still crash.
- Using `dart test` per file avoids crash.

## Requested guidance
Any known issues with `sqlite3`/Dart VM exit-time segfaults?
Any recommended teardown to force native finalizers to flush before shutdown?

