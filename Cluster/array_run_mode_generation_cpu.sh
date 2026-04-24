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
 
# -- END USER DIRECTIVE --
 
# -- BEGIN USER SCRIPT --
module load simnibs/4.1.0
subject=$1
th_hair=$2
workdir=/mnt/munin/Neacsiu/NATURE.01/Analysis/efield_scripts/E-ref/
cd $workdir
matlab -batch "mode_generation_cpu('$workdir', '$subject', $th_hair)"
# -- END USER SCRIPT -- #
 
# **********************************************************
# -- BEGIN POST-USER --
echo "----JOB [$JOB_NAME.$JOB_ID] STOP [`date`]----"
OUTDIR=${OUTDIR:-$HOME/PMD-TMS}
mv $HOME/$JOB_NAME.$JOB_ID.out $OUTDIR/$JOB_NAME.$JOB_ID.out
RETURNCODE=${RETURNCODE:-0}
exit $RETURNCODE
fi
# -- END POST USER--
