# ============================================================
# smooth_sleep — add_time (macro)
# Advances time by $(step) ticks.
# Uses a macro so the step is computed on the current tick and never
# overshoots dawn (daytime 0), otherwise datapacks that count days
# miss their trigger.
# ============================================================
$time add $(step)
