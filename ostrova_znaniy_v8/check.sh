#!/bin/bash
# Проверка разбора всех скриптов
G=/home/claude/tools/Godot_v4.6.2-stable_linux.x86_64
cd /home/claude/game/project
for f in $(find scripts tests -name "*.gd" 2>/dev/null | sort); do
  out=$(timeout 60 $G --headless --path . --check-only --script "res://$f" 2>&1 | grep -E "SCRIPT ERROR|Parse Error|at: " | grep -v "Failed to compile depended" | head -6)
  if [ -n "$out" ]; then echo "== $f"; echo "$out"; fi
done
