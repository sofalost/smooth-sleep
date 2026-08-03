# ============================================================
# smooth_sleep — add_time (macro)
# Avance le temps de $(step) ticks.
# Passe par une macro pour que le pas soit calcule au tick courant
# et n'enjambe jamais l'aube (daytime 0), sinon les datapacks qui
# comptent les jours ratent leur declencheur.
# ============================================================
$time add $(step)
