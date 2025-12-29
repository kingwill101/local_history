/// Snapshot benchmark tool for Local History.
import 'dart:async';
import 'dart:io';
import 'dart:math';

import 'package:args/args.dart';
import 'package:path/path.dart' as p;

/// Runs the snapshot benchmark with CLI-configured parameters.
Future<void> main(List<String> args) async {
  final parser = ArgParser()
    ..addOption(
      'files',
      help: 'Number of files to generate.',
      defaultsTo: '1000',
    )
    ..addOption(
      'max-size-mb',
      help: 'Maximum file size in MB (per file).',
      defaultsTo: '5',
    )
    ..addOption(
      'min-size-kb',
      help: 'Minimum file size in KB (per file).',
      defaultsTo: '1',
    )
    ..addOption(
      'concurrency',
      help: 'Snapshot concurrency override (passed to lh snapshot).',
    )
    ..addOption(
      'write-batch',
      help: 'Snapshot write batch override (passed to lh snapshot).',
    )
    ..addOption('lh-bin', help: 'Path to the compiled lh binary.')
    ..addOption('seed', help: 'Random seed for deterministic generation.')
    ..addOption(
      'workers',
      help: 'File generation worker count.',
      defaultsTo: '4',
    )
    ..addFlag('keep', help: 'Keep the temp directory after the run.')
    ..addFlag('help', abbr: 'h', help: 'Show usage.', negatable: false);

  final results = parser.parse(args);
  if (results['help'] as bool) {
    stdout.writeln('Snapshot benchmark');
    stdout.writeln(parser.usage);
    exit(0);
  }

  final fileCount = _parsePositiveInt(results['files'] as String, 'files');
  final maxSizeMb = _parsePositiveInt(
    results['max-size-mb'] as String,
    'max-size-mb',
  );
  final minSizeKb = _parsePositiveInt(
    results['min-size-kb'] as String,
    'min-size-kb',
  );
  final concurrency = results['concurrency'] as String?;
  final writeBatch = results['write-batch'] as String?;
  final lhBinOverride = results['lh-bin'] as String?;
  final seedRaw = results['seed'] as String?;
  final workers = _parsePositiveInt(results['workers'] as String, 'workers');
  final keep = results['keep'] as bool;

  if (maxSizeMb <= 0 || minSizeKb <= 0) {
    stderr.writeln('Sizes must be positive.');
    exit(1);
  }

  final maxSizeBytes = maxSizeMb * 1024 * 1024;
  final minSizeBytes = minSizeKb * 1024;
  if (minSizeBytes > maxSizeBytes) {
    stderr.writeln('min-size-kb cannot exceed max-size-mb.');
    exit(1);
  }

  final seed = seedRaw == null
      ? DateTime.now().millisecondsSinceEpoch
      : int.tryParse(seedRaw);
  if (seed == null) {
    stderr.writeln('Invalid seed: $seedRaw');
    exit(1);
  }

  final tempDir = await Directory.systemTemp.createTemp('lh_bench_');
  stdout.writeln('Benchmark directory: ${tempDir.path}');
  final rng = Random(seed);

  final generationStopwatch = Stopwatch()..start();
  await _generateFiles(
    root: tempDir,
    count: fileCount,
    minSizeBytes: minSizeBytes,
    maxSizeBytes: maxSizeBytes,
    rng: rng,
    workers: workers,
  );
  generationStopwatch.stop();

  stdout.writeln(
    'Generated $fileCount files in '
    '${generationStopwatch.elapsedMilliseconds} ms',
  );

  final lhBin = _resolveLhBinary(lhBinOverride);
  stdout.writeln('Using lh binary: $lhBin');

  final initResult = await _runProcess(lhBin, [
    'init',
  ], workingDirectory: tempDir.path);
  if (initResult.exitCode != 0) {
    stderr.writeln(
      'lh init failed:\n${initResult.stdout}\n${initResult.stderr}',
    );
    exit(initResult.exitCode);
  }

  final snapshotArgs = <String>['snapshot'];
  if (concurrency != null) {
    snapshotArgs.addAll(['--concurrency', concurrency]);
  }
  if (writeBatch != null) {
    snapshotArgs.addAll(['--write-batch', writeBatch]);
  }

  final snapshotStopwatch = Stopwatch()..start();
  final snapshotResult = await _runProcess(
    lhBin,
    snapshotArgs,
    workingDirectory: tempDir.path,
  );
  snapshotStopwatch.stop();

  if (snapshotResult.exitCode != 0) {
    stderr.writeln(
      'lh snapshot failed:\n${snapshotResult.stdout}\n${snapshotResult.stderr}',
    );
    exit(snapshotResult.exitCode);
  }

  stdout.writeln(
    'Snapshot completed in ${snapshotStopwatch.elapsedMilliseconds} ms',
  );
  stdout.writeln(snapshotResult.stdout.trim());

  if (!keep) {
    await tempDir.delete(recursive: true);
  } else {
    stdout.writeln('Keeping benchmark directory: ${tempDir.path}');
  }
}

int _parsePositiveInt(String value, String name) {
  final parsed = int.tryParse(value);
  if (parsed == null || parsed < 1) {
    stderr.writeln('Invalid $name: $value');
    exit(1);
  }
  return parsed;
}

Future<void> _generateFiles({
  required Directory root,
  required int count,
  required int minSizeBytes,
  required int maxSizeBytes,
  required Random rng,
  required int workers,
}) async {
  final libDir = Directory(p.join(root.path, 'lib'));
  await libDir.create(recursive: true);

  final buffer = List<int>.generate(8192, (_) => 97 + rng.nextInt(26));
  for (var i = 0; i < count; i += workers) {
    final end = min(i + workers, count);
    final tasks = <Future<void>>[];
    for (var index = i; index < end; index += 1) {
      final size = minSizeBytes + rng.nextInt(maxSizeBytes - minSizeBytes + 1);
      tasks.add(_writeFile(libDir, index, size, buffer));
    }
    await Future.wait(tasks);
  }
}

Future<void> _writeFile(
  Directory libDir,
  int index,
  int size,
  List<int> buffer,
) async {
  final file = File(p.join(libDir.path, 'file_$index.txt'));
  final sink = file.openWrite();
  var remaining = size;
  while (remaining > 0) {
    if (remaining >= buffer.length) {
      sink.add(buffer);
      remaining -= buffer.length;
    } else {
      sink.add(buffer.sublist(0, remaining));
      remaining = 0;
    }
  }
  await sink.close();
}

String _resolveLhBinary(String? overridePath) {
  if (overridePath != null && overridePath.trim().isNotEmpty) {
    final file = File(overridePath);
    if (!file.existsSync()) {
      stderr.writeln('lh binary not found at $overridePath');
      exit(1);
    }
    return file.path;
  }
  final repoRoot = Directory.current;
  final candidate = File(
    p.join(
      repoRoot.path,
      'build',
      'cli',
      'linux_x64',
      'bundle',
      'bin',
      'local_history',
    ),
  );
  if (!candidate.existsSync()) {
    stderr.writeln(
      'lh binary not found. Pass --lh-bin /path/to/lh (compiled binary).',
    );
    exit(1);
  }
  return candidate.path;
}

Future<ProcessResult> _runProcess(
  String executable,
  List<String> arguments, {
  required String workingDirectory,
}) async {
  return Process.run(
    executable,
    arguments,
    workingDirectory: workingDirectory,
    runInShell: false,
  );
}
