set global_verbose_level 0
run_synthesis
run_floorplan
manual_macro_placement
detailed_placement_or -def $::env(placement_results)/$::env(DESIGN_NAME).def -log $::env(placement_logs)/detailed.log
run_cts
run_routing
run_parasitics_sta
run_magic
run_magic_spice_export
run_magic_drc
run_lvs
run_antenna_check
save_final_views
calc_total_runtime
generate_final_summary_report
check_timing_violations
