# ============================================================
# smooth_sleep — tick
# MC 26.2 / pack_format 107.1
#
# Two ways to advance time:
#   - SLEEP : at night, in a bed (vanilla, SleepTimer > 0)
#   - NAP   : during the day, sneaking on a bed
# No gamerule allows sleeping during the day (the "you can only
# sleep at night" refusal is hardcoded), hence the sneak-based nap.
#
# `time add N` targets the daylight cycle time: no `time of <clock>`,
# <clock> expects a registry world clock, not a dimension.
#
# IMPORTANT — day counter: the step is clamped to never overshoot
# dawn (daytime 0). A raw jump of +110 could skip past daytime==0
# and break datapacks that announce "Day 67" at dawn.
# ============================================================

# ------------------------------------------------------------
# 1. Current time (0..23999 since sunrise)
# ------------------------------------------------------------
execute store result score #daytime timer run time query minecraft:day

# ------------------------------------------------------------
# 2. Sneak detection via the vanilla sneak_time stat, which counts
#    ticks spent sneaking. Delta > 0 vs the previous tick means
#    sneaking right now. (Avoids predicates, whose format changed
#    in 26.2.)
#
#    sneak_init : 0 until the player has been seen once.
#    Without this, on the first tick sneak_prev is 0 and the delta
#    equals the player's whole cumulated sneak_time -> false nap.
# ------------------------------------------------------------
execute as @a unless score @s sneak_init matches 1 run scoreboard players operation @s sneak_prev = @s sneak_time
execute as @a unless score @s sneak_init matches 1 run scoreboard players set @s sneak_init 1

execute as @a run scoreboard players operation @s sneak_delta = @s sneak_time
execute as @a run scoreboard players operation @s sneak_delta -= @s sneak_prev
execute as @a run scoreboard players operation @s sneak_prev = @s sneak_time

# ------------------------------------------------------------
# 3. Vanilla sleep: SleepTimer NBT (0 = awake, 1+ = sleeping)
# ------------------------------------------------------------
execute as @a store result score @s sleep_timer run data get entity @s SleepTimer

# ------------------------------------------------------------
# 4. Nap: during the day (0..12540), sneaking, on a bed.
#    The bed is 9/16 of a block tall: standing on it, the player's
#    origin (their feet) is INSIDE the bed block -> test at ~ ~ ~.
#    ~ ~-1 ~ covers the case where they'd be considered just above.
# ------------------------------------------------------------
scoreboard players set @a napping 0
execute as @a if score #daytime timer matches 0..12540 if score @s sneak_delta matches 1.. at @s if block ~ ~ ~ #minecraft:beds run scoreboard players set @s napping 1
execute as @a if score #daytime timer matches 0..12540 if score @s sneak_delta matches 1.. at @s if block ~ ~-1 ~ #minecraft:beds run scoreboard players set @s napping 1

# ------------------------------------------------------------
# 5. Resting = sleeping (night) OR napping (day)
# ------------------------------------------------------------
scoreboard players set @a resting 0
execute as @a if score @s sleep_timer matches 1.. if score #daytime timer matches 12541.. run scoreboard players set @s resting 1
execute as @a if score @s napping matches 1 run scoreboard players set @s resting 1

# ------------------------------------------------------------
# 5b. Daytime storm: vanilla allows sleeping during a storm even
#     during the day. Since the vanilla skip is disabled (101%), the
#     player would stay stuck in bed. When SleepTimer reaches 100
#     in broad daylight (0..12540), it must be a storm (vanilla
#     refuses daytime sleep otherwise). We clear the weather: vanilla
#     then automatically wakes the player up.
# ------------------------------------------------------------
execute if entity @a[scores={sleep_timer=100..}] if score #daytime timer matches 0..12540 run weather clear

# ------------------------------------------------------------
# 6. Transition notifications (actionbar)
#    Tags for grouping: one title per type = no overwrite.
#    Without this, two players going to bed on the same tick would
#    trigger two `title` calls and the second would overwrite the first.
# ------------------------------------------------------------
tag @a remove ss_nap
tag @a remove ss_sleep
tag @a remove ss_wake

execute as @a if score @s napping matches 1 if score @s rest_prev matches 0 run tag @s add ss_nap
execute as @a if score @s sleep_timer matches 1.. if score #daytime timer matches 12541.. if score @s rest_prev matches 0 run tag @s add ss_sleep
execute as @a if score @s resting matches 0 if score @s rest_prev matches 1 run tag @s add ss_wake

execute if entity @a[tag=ss_nap] run title @a actionbar [{"selector":"@a[tag=ss_nap]","separator":{"text":", ","color":"white"}},{"text":" napping...","color":"gold"}]
execute if entity @a[tag=ss_sleep] run title @a actionbar [{"selector":"@a[tag=ss_sleep]","separator":{"text":", ","color":"white"}},{"text":" sleeping...","color":"aqua"}]
execute if entity @a[tag=ss_wake] run title @a actionbar [{"selector":"@a[tag=ss_wake]","separator":{"text":", ","color":"white"}},{"text":" woke up","color":"yellow"}]

# 7. Remember the state for the next tick
execute as @a run scoreboard players operation @s rest_prev = @s resting

# ------------------------------------------------------------
# 8. Count who's resting, and players online
# ------------------------------------------------------------
execute store result score #resting_count timer if entity @a[scores={resting=1}]
execute store result score #total_players timer if entity @a

# ------------------------------------------------------------
# 9. Percentage (integer division)
#    Reset to 0 first: if nobody is online, division by zero fails
#    silently and the score keeps a sane value.
# ------------------------------------------------------------
scoreboard players set #resting_pct timer 0
scoreboard players operation #resting_pct timer = #resting_count timer
scoreboard players operation #resting_pct timer *= #100 timer
scoreboard players operation #resting_pct timer /= #total_players timer

# ------------------------------------------------------------
# 10. Acceleration step based on the proportion of sleepers
#     100%   -> +110 ticks/tick (near-instant)
#     50-99% -> +70 ticks/tick
#     1-49%  -> +40 ticks/tick
# ------------------------------------------------------------
scoreboard players set #step timer 0
execute if score #resting_pct timer matches 1..49 run scoreboard players set #step timer 40
execute if score #resting_pct timer matches 50..99 run scoreboard players set #step timer 70
execute if score #resting_pct timer matches 100 run scoreboard players set #step timer 110

# ------------------------------------------------------------
# 11. Dawn clamp — DO NOT REMOVE
#     Datapacks that announce the day number trigger on a small
#     window right after dawn. Vanilla Refresh (the most common one)
#     tests `daytime matches 1..20`.
#     A raw jump of 110 would skip past that window: the day
#     announcement would never fire.
#
#     a) #to_dawn = 24000 - daytime: never overshoot dawn.
#     b) Window 0..20: acceleration is cut off. The vanilla cycle
#        still advances 1 tick/tick on its own, so time doesn't
#        freeze; we cross the window at normal speed (~1 real second)
#        and the counter has plenty of time to trigger.
# ------------------------------------------------------------
execute if score #step timer matches 1.. run scoreboard players set #to_dawn timer 24000
execute if score #step timer matches 1.. run scoreboard players operation #to_dawn timer -= #daytime timer
execute if score #step timer matches 1.. if score #step timer > #to_dawn timer run scoreboard players operation #step timer = #to_dawn timer
execute if score #daytime timer matches 0..20 run scoreboard players set #step timer 0

# ------------------------------------------------------------
# 12. Apply the step (macro: the value is computed this tick)
# ------------------------------------------------------------
execute if score #step timer matches 1.. store result storage smooth_sleep:tmp step int 1 run scoreboard players get #step timer
execute if score #step timer matches 1.. run function smooth_sleep:add_time with storage smooth_sleep:tmp
