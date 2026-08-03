# ============================================================
# smooth_sleep — load
# MC 26.2 / pack_format 107.1
# Dossiers de registre au SINGULIER depuis 1.21 (function/).
# ============================================================

# Desactive le skip de nuit vanilla (101% = inatteignable)
# MC 26.2 : gamerules dans le registre minecraft: (snake_case)
gamerule minecraft:players_sleeping_percentage 101

# ------------------------------------------------------------
# Scoreboards
# ------------------------------------------------------------
# sleep_timer : SleepTimer NBT (0 = eveille, 1+ = dort dans un lit)
scoreboard objectives add sleep_timer dummy

# sneak_time  : stat vanilla, incremente a chaque tick passe accroupi.
#               Sert a detecter le sneak sans predicate (le format des
#               predicates a change en 26.2 — on l'evite).
# sneak_prev  : valeur au tick precedent
# sneak_delta : sneak_time - sneak_prev ; > 0 = accroupi maintenant
# sneak_init  : 1 une fois que sneak_prev a ete amorce pour ce joueur
#               (sinon le 1er delta = tout le sneak_time cumule)
scoreboard objectives add sneak_time minecraft.custom:minecraft.sneak_time
scoreboard objectives add sneak_prev dummy
scoreboard objectives add sneak_delta dummy
scoreboard objectives add sneak_init dummy

# napping   : 1 = fait la sieste (accroupi sur un lit, de jour)
# resting   : 1 = dort (nuit) OU fait la sieste (jour)
# rest_prev : resting au tick precedent, pour detecter les transitions
scoreboard objectives add napping dummy
scoreboard objectives add resting dummy
scoreboard objectives add rest_prev dummy

# timer : fake players (#daytime, #resting_count, #total_players,
#         #resting_pct, #100, configs #cfg_*)
scoreboard objectives add timer dummy

# Constante pour le calcul de pourcentage
scoreboard players set #100 timer 100

# ------------------------------------------------------------
# CONFIG — vitesses de repos (ticks ajoutes par tick)
# IMPORTANT : ces valeurs sont une REFERENCE. Les `time add` sont
# hardcodes dans tick.mcfunction (pas de macros pour l'instant).
# Si tu modifies une valeur ici, modifie aussi la ligne
# correspondante dans tick.mcfunction.
#   #cfg_sleep_low -> 1-49%  des joueurs se reposent (defaut 40)
#   #cfg_sleep_mid -> 50-99% des joueurs se reposent (defaut 70)
#   #cfg_sleep_max -> 100%   des joueurs se reposent (defaut 110)
# ------------------------------------------------------------
scoreboard players set #cfg_sleep_low timer 40
scoreboard players set #cfg_sleep_mid timer 70
scoreboard players set #cfg_sleep_max timer 110

# ------------------------------------------------------------
# TODO (non implemente) — vitesse jour/nuit personnalisable
# Better Days permet de regler la vitesse du jour et de la nuit
# independamment quand personne ne dort. Valeurs prevues :
#   #cfg_day_speed   = 1  (vanilla ; >1 = jour accelere)
#   #cfg_night_speed = 1  (vanilla ; >1 = nuit acceleree hors sommeil)
# A implementer : quand #resting_count = 0, execute conditionnel
# `time add (speed - 1)`. La vitesse de repos garde la priorite.
# ------------------------------------------------------------
#scoreboard players set #cfg_day_speed timer 1
#scoreboard players set #cfg_night_speed timer 1

tellraw @a {"text":"[smooth_sleep] loaded — sommeil (nuit) + sieste (jour, accroupi sur un lit)","color":"aqua"}
