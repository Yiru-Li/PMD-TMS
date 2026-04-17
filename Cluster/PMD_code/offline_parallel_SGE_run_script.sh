#!/bin/sh

# --- BEGIN GLOBAL DIRECTIVE --
#$ -S /bin/sh
#$ -o $HOME/$JOB_NAME.$JOB_ID.out
#$ -e $HOME/$JOB_NAME.$JOB_ID.out
#$ -m ea
# -- END GLOBAL DIRECTIVE --
# -- BEGIN USER DIRECTIVE --
#$ -M yl647@duke.edu
# -- END USER DIRECTIVE --

#change the max wall time according to the specific cluster
stage_1_max_walltime=${20}
stage_2_max_walltime=${21}
stage_3_max_walltime=${22}
stage_4_max_walltime=${23}

subj=$(basename $3)
echo "$subj started"

#submit parallel jobs
# while true; do
#     DP=$(sbatch -A ${19} --cpus-per-task=${15} --time=$stage_1_max_walltime $1/offline_parallel_stage_1.sh $1 $2 $3 $4 $5 $6 $7 $8 $9 ${10} ${11} ${12} ${13} ${14} ${24})
#     if [ "$?" = "0" ]; then
# 		break
# 	else
# 		sleep 600
# 	fi
# done
# while true; do
    DP=$(qsub -N S$subj-1.sh -l h_vmem=64G,vf=64G,h_rt=01:00:00 $1/offline_SGE.sh $1 ${24} offline_parallel_stage_1 \'$1\' $2 \'$3\' \'$4\' \'$5\' \'$6\' $7 \'$8\' \'$9\' ${10} \'${11}\' ${12} ${13} \'${14}\')
#     if [ "$?" = "0" ]; then
# 		break
# 	else
# 		sleep 600
# 	fi
# done
# while true; do
#     CR=$(sbatch -A ${19} --dependency=afterany:${DP##* } --array=[1-$2] --cpus-per-task=${16} --time=$stage_2_max_walltime $1/offline_parallel_stage_2.sh $2 $7 $8 $1 ${24})
#     if [ "$?" = "0" ]; then
# 		break
# 	else
# 		sleep 600
# 	fi
# done
# while true; do
    CR=$(qsub -N S$subj-2.sh -hold_jid S$subj-1.sh -t 1-$2 -l h_vmem=80G,vf=80G,h_rt=02:00:00 $1/offline_parallel_SGE.sh $1 ${24} offline_parallel_stage_2 $2 $7 SGE_TASK_ID \'$8\')
#     if [ "$?" = "0" ]; then
# 		break
# 	else
# 		sleep 600
# 	fi
# done
# while true; do
#     CC=$(sbatch -A ${19} --dependency=afterany:${CR##* } --cpus-per-task=${17} --time=$stage_3_max_walltime $1/offline_parallel_stage_3.sh $2 $7 $8 $1 ${24})
#     if [ "$?" = "0" ]; then
# 		break
# 	else
# 		sleep 600
# 	fi
# done
# while true; do
    CC=$(qsub -N S$subj-3.sh -hold_jid S$subj-2.sh -l h_vmem=32G,vf=32G,h_rt=01:00:00 $1/offline_SGE.sh $1 ${24} offline_parallel_stage_3 $2 $7 \'$8\')
#     if [ "$?" = "0" ]; then
# 		break
# 	else
# 		sleep 600
# 	fi
# done
# while true; do
#     RC=$(sbatch -A ${19} --dependency=afterany:${CC##* } --cpus-per-task=${18} --time=$stage_4_max_walltime --array=[1-$2] $1/offline_parallel_stage_4.sh $2 $7 $8 $1 ${24})
#     if [ "$?" = "0" ]; then
# 		break
# 	else
# 		sleep 600
# 	fi
# done
# while true; do
    RC=$(qsub -N S$subj-4.sh -hold_jid S$subj-3.sh -t 1-$2 -l h_vmem=32G,vf=32G,h_rt=01:00:00 $1/offline_parallel_SGE.sh $1 ${24} offline_parallel_stage_4 $2 $7 SGE_TASK_ID \'$8\')
#     if [ "$?" = "0" ]; then
# 		break
# 	else
# 		sleep 600
# 	fi
# done
echo "Parallel jobs submitted"

# **********************************************************
# -- BEGIN POST-USER --
echo "----JOB [$JOB_NAME.$JOB_ID] STOP [`date`]----"
OUTDIR=$(dirname $1)
mv $HOME/$JOB_NAME.$JOB_ID.out $OUTDIR/$JOB_NAME.$JOB_ID.out
RETURNCODE=${RETURNCODE:-0}
exit $RETURNCODE
fi
# -- END POST USER--