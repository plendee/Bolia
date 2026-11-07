# Economy server tuning (3 threads, behind Velocity)

This fork ships with performance-first defaults (see `GlobalConfiguration` / `WorldConfig`).
The settings below live in runtime config files and cannot be changed from Java defaults.

## What changed in the fork defaults

Global (`canvas` config):
- `networking.filterVelocityPacket`, `stripLoreFromEntityItems`, `alternativePlayerListTick`,
  `purpurAlternativeKeepalive`: on (less packet traffic and smoother playerlist ticking at high player counts)
- `chunkSystem.fluidPostProcessingAlgorithm`: `FILTERED`, `optimizeTreasureMapLocating`: on
- `cacheMinecraft2BukkitEntityTypeConversion`: on
- `regionScheduler.guardSeverity`: `LOG` (was `THROW`, so a misbehaving economy/shop plugin warns instead of crashing)

World config:
- Region TPS/RAM boss bars off (they cost per-player updates); sprint/death/effect/splash/bubble particles off
- `cactusCheckSurvivalBeforeGrowth`, `enableSuffocationOptimization`: on

Gameplay-affecting options (`entityCollisionMode`, `fastOrbs`, `disableCriterionTrigger`, light-check
options) were deliberately left at vanilla. Enable them only if you accept the behaviour change.

## paper-global.yml (3 threads)

```yaml
threaded-regions:
  threads: 2          # leave 1 thread for netty, GC and the OS
  scheduler: AFFINITY # enables Canvas' affinity scheduler
chunk-system:
  io-threads: 1       # NVMe: 1 is enough; raise to 2 only if IO wait shows in spark
  worker-threads: 1   # chunk gen/light; on 3 threads this is the one you share with regions
  gen-parallelism: default
```

Canvas affinity options: leave `enableAffinitySchedulerCpuAffinity: false` unless the host
guarantees dedicated cores; pinning on a shared host can make things worse.

## server.properties (backend behind Velocity)

```
network-compression-threshold=-1   # only if proxy and backend share a machine/trusted LAN
view-distance=6
simulation-distance=4
```

## Velocity (velocity.toml)

- `player-info-forwarding-mode = "modern"` with a forwarding secret on every backend
- Keep `compression-threshold = 256`, `compression-level = -1` for the client side
- Use `ping-passthrough = "DISABLED"` and `tcp-fast-open = true` where the OS supports it

## Economy plugin notes

- Keep balance reads cached and writes batched/async; never hit the database on the region thread.
- Use a Folia-aware economy (Vault provider that does not touch the world from async threads).

## JVM

Use `scripts/start-economy.sh` (G1 with 2 parallel / 1 concurrent GC thread to fit 3 threads).

## Chunk loading

On 3 threads the biggest win is not generating chunks live. In order of impact:

1. **Pregenerate** the world with Chunky out to the world border and set a border. Live generation
   is by far the most expensive thing a small host does.
2. **Cap per-player load rates** so one player exploring cannot starve everyone else
   (`paper-global.yml`, keys under `chunk-loading-basic` / `chunk-loading-advanced`):
   `player-max-chunk-load-rate`, `player-max-chunk-generate-rate`, `player-max-chunk-send-rate`,
   `player-max-concurrent-chunk-loads`, `player-max-concurrent-chunk-generates`.
   Start with load around 20, generate around 4, send around 40 and tune from spark.
3. **View/simulation distance**: view 6-8, simulation 4. Each step costs roughly quadratic chunks per player.
4. **Per-world** (`paper-world-defaults.yml`, `chunks`): keep `delay-chunk-unloads-by` at 10s or lower and
   keep `max-auto-save-chunks-per-tick` low so autosaves do not spike a region tick.
5. **Storage**: put the world on NVMe. `region-file-compression=lz4` in `server.properties` loads faster
   than deflate at the cost of larger files (gameplay stays vanilla).
6. Fork defaults already enable `FILTERED` fluid post-processing, which removes most of the stutter
   when new chunks generate.

Verify exact key names against the config files your build generates, since upstream Paper renames them
occasionally.
