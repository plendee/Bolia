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
  io-threads: 1
  worker-threads: 1
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
