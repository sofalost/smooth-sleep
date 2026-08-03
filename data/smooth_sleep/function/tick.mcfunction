# ============================================================
# smooth_sleep — tick
# MC 26.2 / pack_format 107.1
#
# Deux facons de faire passer le temps :
#   - DORMIR : la nuit, dans un lit (vanilla, SleepTimer > 0)
#   - SIESTE : le jour, accroupi sur un lit
# Aucune gamerule ne permet de dormir le jour (le refus "you can only
# sleep at night" est code en dur), d'ou la sieste par accroupissement.
#
# `time add N` cible la daylight cycle time : pas de `time of <clock>`,
# <clock> attend une world clock du registre, pas une dimension.
#
# IMPORTANT — compteur de jours : le pas est clampe pour ne jamais
# depasser l'aube (daytime 0). Un saut brut de +110 enjambe l'instant
# daytime==0 et casse les datapacks qui annoncent "Day 67" a l'aube.
# ============================================================

# ------------------------------------------------------------
# 1. Heure courante (0..23999 depuis le lever du soleil)
# ------------------------------------------------------------
execute store result score #daytime timer run time query minecraft:day

# ------------------------------------------------------------
# 2. Detection du sneak via la stat vanilla sneak_time, qui compte
#    les ticks passes accroupi. Delta > 0 avec le tick precedent
#    = accroupi maintenant. (Evite les predicates, dont le format
#    a change en 26.2.)
#
#    sneak_init : 0 tant que le joueur n'a pas ete vu une fois.
#    Sans ca, au premier tick sneak_prev vaut 0 et le delta vaut
#    tout le sneak_time cumule du joueur -> fausse sieste.
# ------------------------------------------------------------
execute as @a unless score @s sneak_init matches 1 run scoreboard players operation @s sneak_prev = @s sneak_time
execute as @a unless score @s sneak_init matches 1 run scoreboard players set @s sneak_init 1

execute as @a run scoreboard players operation @s sneak_delta = @s sneak_time
execute as @a run scoreboard players operation @s sneak_delta -= @s sneak_prev
execute as @a run scoreboard players operation @s sneak_prev = @s sneak_time

# ------------------------------------------------------------
# 3. Sommeil vanilla : SleepTimer NBT (0 = eveille, 1+ = dort)
# ------------------------------------------------------------
execute as @a store result score @s sleep_timer run data get entity @s SleepTimer

# ------------------------------------------------------------
# 4. Sieste : de jour (0..12540), accroupi, sur un lit.
#    Le lit fait 9/16 de bloc de haut : debout dessus, l'origine du
#    joueur (ses pieds) est DANS le bloc du lit -> test a ~ ~ ~.
#    ~ ~-1 ~ couvre le cas ou il serait considere juste au-dessus.
# ------------------------------------------------------------
scoreboard players set @a napping 0
execute as @a if score #daytime timer matches 0..12540 if score @s sneak_delta matches 1.. at @s if block ~ ~ ~ #minecraft:beds run scoreboard players set @s napping 1
execute as @a if score #daytime timer matches 0..12540 if score @s sneak_delta matches 1.. at @s if block ~ ~-1 ~ #minecraft:beds run scoreboard players set @s napping 1

# ------------------------------------------------------------
# 5. Se repose = dort (nuit) OU fait la sieste (jour)
# ------------------------------------------------------------
scoreboard players set @a resting 0
execute as @a if score @s sleep_timer matches 1.. if score #daytime timer matches 12541.. run scoreboard players set @s resting 1
execute as @a if score @s napping matches 1 run scoreboard players set @s resting 1

# ------------------------------------------------------------
# 5b. Orage de jour : vanilla permet de dormir pendant un orage meme
#     de jour. Comme le skip vanilla est desactive (101%), le joueur
#     resterait coince dans le lit. Quand SleepTimer atteint 100 en
#     pleine journee (0..12540), c'est forcement un orage (vanilla
#     refuse le sommeil de jour sinon). On clear la meteo : vanilla
#     reveille alors automatiquement le joueur.
# ------------------------------------------------------------
execute if entity @a[scores={sleep_timer=100..}] if score #daytime timer matches 0..12540 run weather clear

# ------------------------------------------------------------
# 6. Notifications de transition (actionbar)
#    Tags pour grouper : un seul title par type = pas d'ecrasement.
#    Sans ca, deux joueurs qui se couchent au meme tick declenchent
#    deux `title` et le second ecrase le premier.
# ------------------------------------------------------------
tag @a remove ss_nap
tag @a remove ss_sleep
tag @a remove ss_wake

execute as @a if score @s napping matches 1 if score @s rest_prev matches 0 run tag @s add ss_nap
execute as @a if score @s sleep_timer matches 1.. if score #daytime timer matches 12541.. if score @s rest_prev matches 0 run tag @s add ss_sleep
execute as @a if score @s resting matches 0 if score @s rest_prev matches 1 run tag @s add ss_wake

execute if entity @a[tag=ss_nap] run title @a actionbar [{"selector":"@a[tag=ss_nap]","separator":{"text":", ","color":"white"}},{"text":" fait la sieste...","color":"gold"}]
execute if entity @a[tag=ss_sleep] run title @a actionbar [{"selector":"@a[tag=ss_sleep]","separator":{"text":", ","color":"white"}},{"text":" dort...","color":"aqua"}]
execute if entity @a[tag=ss_wake] run title @a actionbar [{"selector":"@a[tag=ss_wake]","separator":{"text":", ","color":"white"}},{"text":" s'est reveille","color":"yellow"}]

# 7. Memoriser l'etat pour le prochain tick
execute as @a run scoreboard players operation @s rest_prev = @s resting

# ------------------------------------------------------------
# 8. Compter ceux qui se reposent, et les joueurs en ligne
# ------------------------------------------------------------
execute store result score #resting_count timer if entity @a[scores={resting=1}]
execute store result score #total_players timer if entity @a

# ------------------------------------------------------------
# 9. Pourcentage (division entiere)
#    Reset a 0 d'abord : si personne n'est en ligne, la division par
#    zero echoue silencieusement et le score garde une valeur saine.
# ------------------------------------------------------------
scoreboard players set #resting_pct timer 0
scoreboard players operation #resting_pct timer = #resting_count timer
scoreboard players operation #resting_pct timer *= #100 timer
scoreboard players operation #resting_pct timer /= #total_players timer

# ------------------------------------------------------------
# 10. Pas d'acceleration selon la proportion de dormeurs
#     100%   -> +110 ticks/tick (quasi-instantane)
#     50-99% -> +70 ticks/tick
#     1-49%  -> +40 ticks/tick
# ------------------------------------------------------------
scoreboard players set #step timer 0
execute if score #resting_pct timer matches 1..49 run scoreboard players set #step timer 40
execute if score #resting_pct timer matches 50..99 run scoreboard players set #step timer 70
execute if score #resting_pct timer matches 100 run scoreboard players set #step timer 110

# ------------------------------------------------------------
# 11. Clamp sur l'aube — NE PAS SUPPRIMER
#     Les datapacks qui annoncent le numero du jour se declenchent
#     sur une petite fenetre juste apres l'aube. Vanilla Refresh
#     (le plus courant) teste `daytime matches 1..20`.
#     Un saut brut de 110 enjambe cette fenetre : l'annonce du jour
#     ne se produit jamais.
#
#     a) #to_dawn = 24000 - daytime : ne jamais depasser l'aube.
#     b) Fenetre 0..20 : on coupe l'acceleration. Le cycle vanilla
#        avance seul de 1 tick/tick, donc le temps ne se bloque pas ;
#        on traverse la fenetre a vitesse normale (~1 seconde reelle)
#        et le compteur a tout le temps de se declencher.
# ------------------------------------------------------------
execute if score #step timer matches 1.. run scoreboard players set #to_dawn timer 24000
execute if score #step timer matches 1.. run scoreboard players operation #to_dawn timer -= #daytime timer
execute if score #step timer matches 1.. if score #step timer > #to_dawn timer run scoreboard players operation #step timer = #to_dawn timer
execute if score #daytime timer matches 0..20 run scoreboard players set #step timer 0

# ------------------------------------------------------------
# 12. Appliquer le pas (macro : la valeur est calculee ce tick)
# ------------------------------------------------------------
execute if score #step timer matches 1.. store result storage smooth_sleep:tmp step int 1 run scoreboard players get #step timer
execute if score #step timer matches 1.. run function smooth_sleep:add_time with storage smooth_sleep:tmp
