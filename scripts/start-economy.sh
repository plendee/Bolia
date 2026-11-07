#!/usr/bin/env bash
# Canvas start script tuned for a 3-thread Ryzen 7 host running an economy server behind Velocity.
# Adjust HEAP to your RAM (leave ~2GB free for the OS and Velocity if they share the box).
set -euo pipefail

JAR="${JAR:-canvas.jar}"
HEAP="${HEAP:-8G}"

exec java \
  -Xms"$HEAP" -Xmx"$HEAP" \
  -XX:+UseG1GC \
  -XX:ParallelGCThreads=2 -XX:ConcGCThreads=1 \
  -XX:+ParallelRefProcEnabled \
  -XX:MaxGCPauseMillis=150 \
  -XX:+UnlockExperimentalVMOptions \
  -XX:+DisableExplicitGC \
  -XX:+AlwaysPreTouch \
  -XX:G1NewSizePercent=30 -XX:G1MaxNewSizePercent=40 \
  -XX:G1HeapRegionSize=16M \
  -XX:G1ReservePercent=15 \
  -XX:G1HeapWastePercent=5 \
  -XX:G1MixedGCCountTarget=4 \
  -XX:InitiatingHeapOccupancyPercent=20 \
  -XX:G1MixedGCLiveThresholdPercent=90 \
  -XX:G1RSetUpdatingPauseTimePercent=5 \
  -XX:SurvivorRatio=32 \
  -XX:+PerfDisableSharedMem \
  -XX:MaxTenuringThreshold=1 \
  -XX:CICompilerCount=2 \
  -XX:+UseStringDeduplication \
  -Dusing.aikars.flags=https://mcflags.emc.gs \
  -Daikars.new.flags=true \
  -jar "$JAR" --nogui
