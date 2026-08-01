# Refactor signals

A small pipeline that measures code metrics on CI and surfaces likely refactor
hotspots as a job summary plus a few PR annotations. Signals are advisory only —
nothing here fails the build.

This document records **what the ranking measures and why it is designed the
way it is**, so the design intent survives beyond the original PR. The tooling
is intended to be generalized to other apps/libraries later, so the reasoning
below is written with portability in mind rather than for this repo specifically.

## Pipeline

| Step | Produces | Notes |
|---|---|---|
| `.rubocop_metrics.yml` (RuboCop) | `rubocop.json` | ABC size, method/class/module length |
| `script/refactor_signals.rb` (Prism AST + git) | `deps.json` | dependency graph, file length, churn, per-module ivar writes |
| `script/mixin_dump.rb` (boot + reflection) | `mixins.json` | composed-object mixin lists & method counts (optional) |
| `script/build_summary.rb` | job summary + annotations | ranking and per-signal breakdown |

The workflow is `.github/workflows/refactor-signals.yml`.

## The combined ranking score

The headline ranking is per **file** and computed as:

```
badness      = norm(lines) + norm(fan_in * fan_out) + norm(peak ABC)
churn_factor = CHURN_FLOOR + (1 - CHURN_FLOOR) * norm(churn)   # 0.25 .. 1.0
score        = badness * churn_factor
```

- `norm(x)` normalizes to `0..1` by the max across files.
- Churn **modulates** rather than adds, because a hotspot is complexity that
  actually changes often (`badness × churn`), following the "complexity ×
  change frequency" hotspot model. A pure summand would let a file that never
  changes climb on size alone.
- `CHURN_FLOOR` (0.25) keeps complex-but-stable files visible instead of
  zeroing them, and makes the score degrade gracefully to pure complexity when
  churn data is absent (e.g. a shallow checkout with no history).

## The core design principle: rank drivers vs. diagnostic lenses

Not every useful signal belongs in the single scalar ranking. We separate two
kinds, and only the first drives the score.

A signal may drive the rank only if it meets all of:

1. **Portability** — it exists and means the same thing in any codebase, not
   only in a particular architectural style.
2. **Directionality** — higher reliably means worse, and the remedy is local
   and known (extract method, split file, …).
3. **Granularity match** — it attributes naturally to the ranking unit (a file).
4. **Orthogonality** — it adds information the other signals don't.

**Rank drivers** (portable, directional, per-file, computable from git + a
parser): ABC size, file length, fan-in × fan-out coupling, churn. Churn is the
most portable and most directional of all — any git repo, no language or
architecture assumptions.

**Diagnostic lenses** (architectural, contextual, need configuration or a
running process): mixin composition size and shared mutable state. These are
valuable to *look at*, but they must **not** be folded into the ranking score.
They are shown as a separate section.

### Why the mixin / shared-state signal is a lens, not a rank driver

We built a runtime signal that boots the app, reflects on the composed classes,
and reports (a) how many first-party mixins pile onto each object, and (b) which
instance variables are written by ≥2 composed modules (shared mutable state).
It is deliberately kept **out** of the ranking score. Scored against the four
criteria:

| Criterion | Verdict | Reason |
|---|---|---|
| Portability | ✗ | Tracks architectural *style*, not refactoring *need*. It inflates in mixin/concern-heavy codebases and reads ~0 in composition/PORO-heavy ones — even if the latter has god objects by other means. |
| Directionality | ✗ | "More = worse" doesn't hold. Many cohesive behavior mixins are fine; shared lifecycle state (an ORM's `@new_record`-style flags) is often the *intended* coordination point, not a fixable defect. Unlike ABC/length, the "fix" may require rearchitecting or may not be desirable. |
| Granularity | ✗ | It's a property of the *composed object*, not of a file; it doesn't drop into a per-file score without extra attribution. |
| Orthogonality | ✓ | This is its real value: shared mutable state is a coupling axis the other signals miss. |

It fails 3 of 4 as a rank driver. It also has a **measurement-portability**
cost: `mixin_dump.rb` currently hardcodes the composition entry points
(`include MongoMapper::Document`) and needs a booting environment with
dependencies installed. Generalizing it means letting a project configure its
root composed classes, not adding it to the score.

So: keep it as an **opt-in diagnostic lens**, surfaced separately, consulted
when the project uses heavy mixin composition — not as a component of the rank.

## Decision log

- **Constant-based dependency graph, not a require-line scan.** Ruby mixes
  `require` / `require_relative` / `autoload` (with `$LOAD_PATH`-relative string
  paths), so scanning require lines leaves holes. We map constant
  definitions/autoloads to references instead. Resolution uses "enclosing
  namespaces first, then a suffix-match fallback" — good enough for a ranking,
  not sound lexical scoping.

- **Dropped the Law of Demeter (deep method chain) signal.** It is a low-to-
  medium severity smell, largely redundant with ABC (a chain inflates ABC), and
  Ruby has no static return-type information, so a depth-based approximation
  can't distinguish real train wrecks from Enumerable pipelines / value
  conversions and is noisy. Removed in favor of churn.

- **Churn over the last N commits, not all history.** Full-history scans are
  slow; `CHURN_COMMITS` (default 200) bounds it. CI checkout uses
  `fetch-depth: 300` so the window has history.

- **A dedicated `.rubocop_metrics.yml` with `Max: 0`.** RuboCop only emits a
  metric value inside an *offense* message, so a high `Max` yields no data.
  `Max: 0` makes every method/class an offense; we parse the real value from the
  message. This is unusable as a normal lint config, so it lives in a separate
  file rather than occupying `.rubocop.yml`.

- **RuboCop via `gem install`, but the mixin dump uses Bundler.** Static
  analysis (Prism + RuboCop) is decoupled from the gem's Bundler environment and
  supported-Ruby range. The mixin dump must actually boot the library, so that
  step (and only that step) installs dependencies.

## Generalizing later

- The **rank-driver core** (ABC + length + coupling + churn) already generalizes:
  it needs only git and a parser. The constant-graph mechanics are Ruby-specific
  but the concept ports.
- The **mixin lens** needs project configuration (which classes are the root
  composed objects) and a working runtime before it can run on an arbitrary
  project. The next step for it is configurability, not inclusion in the score.
