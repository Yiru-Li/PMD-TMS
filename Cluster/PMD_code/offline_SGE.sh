#!/bin/sh
 
# --- BEGIN GLOBAL DIRECTIVE --
#$ -S /bin/sh
#$ -o $HOME/$JOB_NAME.$JOB_ID.out
#$ -e $HOME/$JOB_NAME.$JOB_ID.out
#$ -m ea
# -- END GLOBAL DIRECTIVE --
 
# -- BEGIN USER SCRIPT --
module load $2
cd $1
MATLAB_script_name=$3
MATLAB_script_vars=$4
shift 4
sep=", "
for arg in "$@"; do
  MATLAB_script_vars="${MATLAB_script_vars}${sep}${arg}"
  sep=","
done
# cd $HOME/PMD-TMS
matlab -batch "$MATLAB_script_name($MATLAB_script_vars)"
wait
echo "All Processess are Complete"
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