#!/bin/sh
 
# --- BEGIN GLOBAL DIRECTIVE --
#$ -S /bin/sh
#$ -o $HOME/$JOB_NAME.$JOB_ID.out
#$ -e $HOME/$JOB_NAME.$JOB_ID.out
#$ -m ea
# -- END GLOBAL DIRECTIVE --
 
# **********************************************************
 
# -- BEGIN USER DIRECTIVE --
# Send notifications to the following address
#$ -M yl647@duke.edu
#$ -l h_vmem=64G,vf=64G
 
# -- END USER DIRECTIVE --
 
# -- BEGIN USER SCRIPT --
workdir=/mnt/munin/Neacsiu/NATURE.01/Analysis/efield_scripts/E-ref/
cd $workdir
matlab -batch "cluster_optimize"
# -- END USER SCRIPT -- #
 
# **********************************************************
# -- BEGIN POST-USER --
echo "----JOB [$JOB_NAME.$JOB_ID] STOP [`date`]----"
OUTDIR=$workdir
mv $HOME/$JOB_NAME.$JOB_ID.out $OUTDIR/$JOB_NAME.$JOB_ID.out
RETURNCODE=${RETURNCODE:-0}
exit $RETURNCODE
fi
# -- END POST USER--
