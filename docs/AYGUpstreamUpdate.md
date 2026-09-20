# Updating to a new Telegram-iOS release

AyuGram is a fork of `TelegramMessenger/Telegram-iOS`. Telegram ships a release
roughly every few weeks and rewrites a lot of code in each one — the
12.8 → 12.9.2 cycle changed **994 files and 104 014 lines**. This document is
the procedure for taking such a release without re-doing the fork by hand.

## How the repository is arranged

```
upstream   0d90f03b ── (next release) ── (the one after) ──   ← vendor branch: one
              │                                                 snapshot commit per
              │                                                 Telegram release
              ▼
master     5eab5f33 AyuGram: fork baseline ── … ── HEAD        ← our work
```

`upstream` is a **vendor branch**: each commit is a plain snapshot of one
Telegram-iOS release tree, parented on the previous snapshot. Telegram's own
commit history is deliberately *not* imported — a full clone is several
gigabytes, and a merge needs nothing from it except a common ancestor, which the
previous snapshot already is.

The first snapshot is `release-12.9.2`. Because `master` descends from it,
`git merge upstream` is an ordinary three-way merge with a real base, and git
only has to reconcile what *both* sides changed.

> Before September 2026 this repository was a single squashed commit with no
> relationship to Telegram's tree at all, which is why updating used to look
> like rewriting the fork. The pre-rewrite history is kept as the tag
> `backup/pre-reparent-2026-09-20`.

## Why this works: our patch surface is small

The fork is built so that almost all AyuGram code lives in files Telegram will
never touch:

| | |
|---|---|
| Files owned entirely by us (`AYG*`, `submodules/AyuGramUI/`) | ~28 000 lines |
| Lines we add *inside* files Telegram owns | **1 906 across 98 files** |

Those 1 906 lines are short hooks — a call into an `AYG*` manager, with a
comment explaining why it sits at that exact chokepoint. Measured on the
12.8 → 12.9.2 cycle, a full release produces **3 conflicting files**.

**Keep it that way.** When a feature needs upstream code to behave differently,
add a one-line call to an `AYG*` entry point and put the logic in our own file.
Do not restructure upstream functions, do not reformat their whitespace, and do
not delete their files — a deleted file turns every future upstream edit to it
into a modify/delete conflict.

## The procedure

### 1. Import the release

```bash
tools/ayg-upstream/import-release.sh 13.0
```

It fetches `release-13.0` at depth 1, appends it to `upstream`, and prints both
the size of the release and the list of files we patch that it also touched.

### 2. Merge

```bash
git switch -c update/13.0
git merge upstream
```

Resolve conflicts by **keeping upstream's version and re-planting our hook into
it**. Never resolve a conflict by keeping our whole side of the file: that
silently reverts upstream's change for that region.

### 3. Verify the hooks survived

```bash
python3 tools/ayg-upstream/ayg_hooks.py check
```

This is the step that catches what neither git nor the compiler can. Our hooks
are *calls*; their definitions live in our own files. When upstream rewrites a
function, the merge can drop a call site cleanly, the project still compiles,
and the feature is simply dead. `hooks.json` records all **347 references across
76 upstream-owned files**, and `check` reports any that vanished.

Once the diff is reviewed and correct, re-record it:

```bash
python3 tools/ayg-upstream/ayg_hooks.py snapshot
```

### 4. Re-apply the generated rebranding

The Telegram → AyuGram renaming in `Localizable.strings` is **generated**, not
hand-written. Re-run it after every import:

```bash
python3 build-system/AYGRenameStrings.py
```

It only rewrites values of an explicit key list, and only where "Telegram" means
*this app on this device* — statements about the Telegram service, company or
products stay as they are. It is idempotent, and it prints any listed key it
could not find, which is how you learn upstream renamed or dropped a string.

### 5. Version and submodules

```bash
git diff upstream~1 upstream -- versions.json .gitmodules
git submodule update --init --recursive
```

`versions.json` carries the app version, the Xcode version and the Bazel pin;
the merge brings all three over. Check that the Xcode and Bazel versions on the
CI runner (`.github/workflows/build.yml`) still exist.

### 6. Build, then check the semantics

```bash
python3 build-system/Make/Make.py --overrideXcodeVersion --cacheDir ~/telegram-bazel-cache \
  build --configurationPath build-system/ayugram-configuration.json \
  --buildNumber=1 --configuration=debug_sim_arm64 --continueOnError
```

`--continueOnError` surfaces every broken call site in one pass instead of
stopping at the first.

A green build is necessary but not sufficient. Walk the features whose hooks sit
in files this release rewrote — the import script printed that list — and
confirm each one still *does* something: send and delete a message, flip Ghost
Mode, open a story, forward from a copy-protected chat.

## Things that will bite

- **Deleted upstream files.** We currently delete `Telegram.icon/Assets/Oval.svg`
  and `Plane.svg`. Each will conflict the moment upstream edits them. Prefer
  overriding a file's *use* to deleting the file.
- **`.gitignore`** conflicts every cycle because our block sits at the end of the
  file, exactly where upstream appends too.
- **`bazel-Ayugram`** is a committed symlink pointing at somebody else's machine
  (`/private/var/tmp/_bazel_ichmagmaus/…`). It is build junk that arrived with an
  earlier import and should be removed and ignored.
- **Hooks that upstream routes around.** The dangerous change is not a renamed
  function — the compiler catches that — but a *new code path* that reaches the
  same outcome without passing our hook. This is why hooks belong at the lowest
  chokepoint available, and why each one carries a comment saying which callers
  it is guarding.
