cluster_loc = 'yl647@cluster.biac.duke.edu';
subj = 'q005';
system(['rsync -rv --size-only --delete ../Cluster/ ' cluster_loc ':PMD-TMS/']);
system(['ssh ' cluster_loc ' qsub PMD-TMS/array_run_mode_generation_cpu.sh']);
%%
system(['rsync -rv --size-only ' cluster_loc ':PMD-TMS/ ../Cluster/']);