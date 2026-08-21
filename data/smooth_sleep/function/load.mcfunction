# ============================================================
# smooth_sleep — load
# MC 26.2 / pack_format 107.1
# Registry folders are SINGULAR since 1.21 (function/).
# ============================================================

# Disable vanilla night skip (101% = unreachable)
# MC 26.2: gamerules live in the minecraft: registry (snake_case)
gamerule minecraft:players_sleeping_percentage 101

# ------------------------------------------------------------
# Scoreboards
# ------------------------------------------------------------
# sleep_timer : SleepTimer NBT (0 = awake, 1+ = sleeping in a bed)
scoreboard objectives add sleep_timer dummy

# sneak_time  : vanilla stat, incremented every tick spent sneaking.
#               Used to detect sneaking without a predicate (the
#               predicate format changed in 26.2 — we avoid it).
# sneak_prev  : value on the previous tick
# sneak_delta : sneak_time - sneak_prev ; > 0 = sneaking right now
# sneak_init  : 1 once sneak_prev has been seeded for this player
#               (otherwise the 1st delta = the whole cumulated sneak_time)
scoreboard objectives add sneak_time minecraft.custom:minecraft.sneak_time
scoreboard objectives add sneak_prev dummy
scoreboard objectives add sneak_delta dummy
scoreboard objectives add sneak_init dummy

# napping   : 1 = napping (sneaking on a bed, during the day)
# resting   : 1 = sleeping (night) OR napping (day)
# rest_prev : resting on the previous tick, to detect transitions
scoreboard objectives add napping dummy
scoreboard objectives add resting dummy
scoreboard objectives add rest_prev dummy

# timer : fake players (#daytime, #resting_count, #total_players,
#         #resting_pct, #100, #cfg_* configs)
scoreboard objectives add timer dummy

# Constant for percentage calculation
scoreboard players set #100 timer 100

# ------------------------------------------------------------
# CONFIG — resting speeds (ticks added per tick)
# IMPORTANT: these values are a REFERENCE. The `time add` calls are
# hardcoded in tick.mcfunction (no macros for now).
# If you change a value here, also update the matching line in
# tick.mcfunction.
#   #cfg_sleep_low -> 1-49%  of players resting (default 40)
#   #cfg_sleep_mid -> 50-99% of players resting (default 70)
#   #cfg_sleep_max -> 100%   of players resting (default 110)
# ------------------------------------------------------------
scoreboard players set #cfg_sleep_low timer 40
scoreboard players set #cfg_sleep_mid timer 70
scoreboard players set #cfg_sleep_max timer 110

# ------------------------------------------------------------
# TODO (not implemented) — configurable day/night speed
# Better Days lets you set day and night speed independently when
# nobody is sleeping. Planned values:
#   #cfg_day_speed   = 1  (vanilla; >1 = accelerated day)
#   #cfg_night_speed = 1  (vanilla; >1 = accelerated night outside sleep)
# To implement: when #resting_count = 0, conditional execute of
# `time add (speed - 1)`. Resting speed keeps priority.
# ------------------------------------------------------------
#scoreboard players set #cfg_day_speed timer 1
#scoreboard players set #cfg_night_speed timer 1

tellraw @a {"text":"[smooth_sleep] loaded — sleep (night) + nap (day, sneak on a bed)","color":"aqua"}
