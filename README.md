# local_history

Lightweight, editor-agnostic local history for project files. Runs a daemon to
capture filesystem changes and provides CLI commands to browse, search, diff,
restore, and verify past versions.

## Contents
- Getting Started
- Concepts
- Project Layout
- Configuration
- CLI Reference
- Examples
- MCP Server (read-only)
- Troubleshooting

## Getting Started

### Requirements
- Linux/Unix only for now.
- A project directory on a local filesystem.

### Install / Run
This repo is a Dart CLI. In development, run it with Dart:

```bash
# From the project root

dart run bin/local_history.dart <command>
```

If you have a compiled binary named `lh` on your PATH, you can use it directly:

```bash
lh <command>
```

### Initialize
Run once per project root:

```bash
lh init
```

This creates:
- `.lh/` directory
- `.lh/config.yaml`
- `.lh/history.db`
- `.lh/lock` (created when daemon starts)
- Adds `.lh/` to `.gitignore`

### Start the daemon
Run in the foreground for now:

```bash
lh daemon
```

The daemon will watch the project root, record file changes, and write
revisions to `.lh/history.db`.

## Concepts

### What gets recorded
For each tracked file change, Local History records a **revision** with:
- `path` (project-root relative)
- `timestamp` (ms since epoch)
- `change_type` (`create`, `modify`, `delete`)
- `content` (raw bytes)
- `content_text` (decoded text for search/diff, when applicable)
- `checksum` (SHA-256 of raw bytes)

### Text vs binary
A file is considered text when its extension appears in `text_extensions`.
Text revisions are decoded as UTF-8 (with fallback for malformed bytes) and
indexed for search. Binary revisions are stored as raw bytes only.

### Concurrency model
- One daemon (single writer) per project
- Many CLI readers
- SQLite runs in WAL mode for safe concurrent reads

### Debounce
Filesystem changes are debounced (default 200ms) to collapse bursty editor
saves into a single revision.

### Config reload
While the daemon is running, changes to `.lh/config.yaml` are detected and
reloaded automatically. Reloads are debounced and followed by a short backoff
(150ms) so pending events can settle.

## Project Layout

```
project-root/
  .lh/
    config.yaml
    history.db
    lock
```

- `.lh/history.db` stores revisions and snapshots.
- `.lh/lock` is created by the daemon to prevent multiple writers.

## Configuration

`lh init` creates `.lh/config.yaml`. You can edit this file while the daemon
is running; it will reload automatically.

### Default config (new projects)
- Tracks the entire repo (`include: ["**"]`)
- Excludes common build/dep/hidden paths by default
- Includes `.txt` by default

Default `exclude` patterns include:
- `.git/**`
- `.lh/**`
- `.dart_tool/**`
- `node_modules/**`
- `build/**`
- `dist/**`
- `target/**`
- `.idea/**`
- `.vscode/**`
- `.pub-cache/**`
- `.gradle/**`
- hidden files and folders (`.*`, `**/.*`, `**/.*/**`)

### Full schema
```yaml
version: 1
watch:
  recursive: true
  include:
    - "**"
  exclude:
    - ".git/**"
    - ".lh/**"
    - ".dart_tool/**"
    - "node_modules/**"
    - "build/**"
    - "dist/**"
    - "target/**"
    - ".idea/**"
    - ".vscode/**"
    - ".pub-cache/**"
    - ".gradle/**"
    - ".*"
    - "**/.*"
    - "**/.*/**"
limits:
  max_revisions_per_file: 200
  max_days: 30
  max_file_size_mb: 5
text_extensions:
  - ".dart"
  - ".js"
  - ".ts"
  - ".json"
  - ".yaml"
  - ".md"
  - ".txt"
```

### Notes
- Paths are matched as POSIX-style relative paths (`lib/main.dart`).
- To include hidden files, remove the `.*` and `**/.*` excludes.
- Files larger than `max_file_size_mb` are skipped.

## CLI Reference

### Global options
Available on all commands:
- `-h, --help` Show help
- `--[no-]ansi` Force ANSI color output
- `-q, --quiet` Silence output
- `--silent` Alias for `--quiet`
- `-n, --no-interaction` Disable prompts
- `-v, --verbose` Increase verbosity

### `lh init`
Initialize local history in the current project.

```
lh init
```

Creates `.lh/`, config, DB, and ensures `.lh/` is in `.gitignore`.

### `lh daemon`
Start the watcher daemon.

```
lh daemon
```

Options:
- `--max-events <n>` Stop after processing N events (testing only)
- `--debounce-ms <ms>` Override debounce window

Notes:
- Writes a lock file at `.lh/lock` to ensure a single daemon.
- Exit code `75` indicates another daemon is already running.
- Handles `SIGINT` to shut down cleanly.
- Reloads config automatically on change.

### `lh history <path>`
List revision history for a file.

```
lh history lib/main.dart
```

Options:
- `--limit <n>` Limit number of revisions

Output is **newest first** (descending timestamp).

### `lh show <rev_id>`
Show a specific revision by ID.

```
lh show 42
```

Options:
- `--raw` Output raw bytes to stdout (useful for binary)

If the revision is binary and `--raw` is not provided, the command warns and
prints nothing.

### `lh diff <old_rev> <new_rev>`
Show a unified diff between two revisions (old then new).

```
lh diff 40 42
```

Options:
- `--context <n>` Number of context lines (default 3)
- `--allow-cross-file` Allow diffing revisions from different files

Notes:
- Diff is only supported for text revisions.
- Output is colorized when ANSI is enabled.

### `lh restore <rev_id>`
Restore a revision to its original file path.

```
lh restore 42
```

Options:
- `--force` Skip confirmation prompt

The daemon will capture the restore as a new revision.

### `lh search <query>`
Search across historical text revisions.

```
lh search "token" --file lib/main.dart
```

Options:
- `--file <path>` Filter by file path
- `--since <timestamp>` Filter by start time (ms, seconds, or ISO8601)
- `--until <timestamp>` Filter by end time (ms, seconds, or ISO8601)
- `--limit <n>` Limit results (default 200)

Query syntax uses SQLite FTS5. Common patterns:
- `token` (term match)
- `"exact phrase"`
- `token*` (prefix)
- `foo NEAR bar`

Timestamp parsing rules:
- All digits, 10 or fewer -> seconds
- All digits, 11+ -> milliseconds
- ISO8601 strings -> parsed as time

### `lh label <rev_id> "message"`
Label a revision with a message.

```
lh label 42 "pre-refactor"
```

### `lh gc`
Garbage collect old revisions.

```
lh gc
```

Options:
- `--max-days <n>` Override max age in days
- `--max-revisions <n>` Override max revisions per file
- `--vacuum` Run `VACUUM` after cleanup

Defaults come from `.lh/config.yaml`.

### `lh snapshot`
Create a snapshot of all currently watched files.

```
lh snapshot
```

Options:
- `--label <name>` Assign a unique label to the snapshot

Notes:
- Snapshot labels must be unique.
- Snapshot respects include/exclude rules and file size limits.
- A snapshot records the current revision of each included file and links
  them to the snapshot record.

### `lh snapshot-restore`
Restore a snapshot by id or label.

```
# by id
lh snapshot-restore --id 12

# by label
lh snapshot-restore --label nightly-2025-01-01

# by positional (id or label)
lh snapshot-restore 12
lh snapshot-restore nightly-2025-01-01
```

Options:
- `--force` Skip confirmation prompt
- `--id <id>` Snapshot id
- `--label <label>` Snapshot label

Notes:
- Restores all files recorded in the snapshot.
- If a file is unchanged, it is skipped for efficiency.
- Files created after the snapshot are **not deleted**.

### `lh verify`
Verify revision checksums.

```
# single revision
lh verify 42

# verify all revisions
lh verify --all
```

Options:
- `--all` Verify every revision in the database
- `--json` Output JSON
- `--quiet` Suppress human-readable output

Exit codes:
- `0` OK
- `1` Not found
- `2` Missing checksum
- `3` Checksum mismatch

For `--all`, the highest-severity status is returned.

### `lh mcp`
Start the MCP server over stdio (read-only).

```
lh mcp
```

Options:
- `--root <path>` Project root (defaults to current directory)
- `--root-path <path>` Alias for `--root`
- `--protocol-log <path>` Append MCP protocol messages to a file

## Examples

### Basic workflow
```bash
lh init
lh daemon

# edit files in your editor...

lh history lib/main.dart
lh show 42
lh diff 40 42
lh restore 40
```

### Search by date
```bash
# last 24 hours
lh search "token" --since "2025-12-27T00:00:00" --until "2025-12-28T00:00:00"

# using epoch seconds
lh search "token" --since 1735344000
```

### Snapshot and restore
```bash
lh snapshot --label pre-refactor

# make changes...

lh snapshot-restore --label pre-refactor
```

### Verify integrity
```bash
lh verify 120
lh verify --all --json
```

## Sample Output

### `lh history lib/main.dart`
```
+-----+-------------------------+--------+-------+
| REV | TIMESTAMP               | TYPE   | LABEL |
+-----+-------------------------+--------+-------+
| 12  | 2025-12-28T10:39:39.418 | modify |       |
| 11  | 2025-12-28T10:39:27.272 | modify |       |
| 10  | 2025-12-28T10:37:58.313 | create | init  |
+-----+-------------------------+--------+-------+
```

### `lh diff 10 12`
```
--- lib/main.dart@10 2025-12-28T10:37:58.313
+++ lib/main.dart@12 2025-12-28T10:39:39.418
@@ -1,2 +1,3 @@
 hello
+world
```

### `lh search "token" --file lib/main.dart`
```
+-----+-------------------------+---------------+-------+
| REV | TIMESTAMP               | PATH          | LABEL |
+-----+-------------------------+---------------+-------+
| 15  | 2025-12-28T11:12:01.004 | lib/main.dart |       |
+-----+-------------------------+---------------+-------+
```

### `lh verify --all`
```
Verify all: 120 total, 120 ok, 0 missing, 0 mismatched.
```

## MCP Server (read-only)

### Tools exposed
- `lh_history_list`
- `lh_revision_show`
- `lh_revision_diff`
- `lh_history_search`
- `lh_revision_verify`

### Example client config (JSON)
```json
{
  "mcpServers": {
    "local-history": {
      "command": "lh",
      "args": ["mcp", "--root", "/path/to/project"]
    }
  }
}
```

### Protocol logging
Append MCP protocol traffic for debugging:

```bash
lh mcp --protocol-log /tmp/lh-mcp.log
```

This writes protocol messages to the log file (never stdout).

## Troubleshooting

### "Missing config at ... Run `lh init`"
Run `lh init` in the project root to create `.lh/config.yaml` and the database.

### "daemon lock already held"
Another daemon is running for this project.
- Find the process ID in `.lh/lock` and stop it
- Or delete the lock file if the process is gone

### Changes not being recorded
Check:
- The daemon is running
- The path is included by config rules
- The file size is below `max_file_size_mb`
- The file is not hidden or inside excluded directories

### Diff says "only supported for text"
Add the file extension to `text_extensions` in `.lh/config.yaml`.

### Search returns no results
Only text revisions are indexed. Ensure the file is treated as text and that
changes are captured by the daemon.
