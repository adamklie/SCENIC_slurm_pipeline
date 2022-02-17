#!/bin/bash
#SBATCH --partition=carter-compute
#SBATCH -o %x.run%a.out
#SBATCH -e %x.run%a.err
##############################################
# USAGE: sbatch --job-name=SCENICprotocol_multirun_test --cpus-per-task=4 --mem-per-cpu=4G --array=1-5%5 SCENICprotocol.sh $loom_in $tf_list $ranking $annotation $method $out_name
# Date 02/17/2022
##############################################

date
echo -e "Job ID: $SLURM_JOB_ID\n"

# Configuring env (choose either singularity or conda)
source activate /cellar/users/aklie/opt/miniconda3/envs/single_cell_py

# Configure input arguments
loom_in=$1
tf_list=$2
ranking=$3
annotation=$4
method=$5
out_name=$6

echo -e "Loading loom file: $loom_in"
echo -e "Using tfs in: $tf_list"
echo -e "Using regulatory feature database: $ranking"
echo -e "Using regulatory feature to TF annotation from: $annotation"
echo -e "Running using the $method algorithm"
echo -e "Outputting with prefix: $out_name\n"

# GRN inference
CMD="pyscenic grn \
$loom_in $tf_list \
-o ${out_name}_run${SLURM_ARRAY_TASK_ID}_adj.tsv \
-m $method \
--num_workers $SLURM_CPUS_PER_TASK"
echo -e "Running:\n $CMD"
$CMD
echo -e ""

# Enrichment and pruning
CMD="pyscenic ctx ${out_name}_adj.tsv \
$ranking \
--annotations_fname $annotation \
--expression_mtx_fname data/pbmc10k_filtered_scenic.loom \
--output ${out_name}_run${SLURM_ARRAY_TASK_ID}_reg.csv  \
--mask_dropouts \
--num_workers $SLURM_CPUS_PER_TASK"
echo -e "Running:\n $CMD"
$CMD
echo -e ""

# AUCell calculation
CMD="pyscenic aucell \
data/pbmc10k_filtered_scenic.loom \
${out_name}_run${SLURM_ARRAY_TASK_ID}_reg.csv  \
--output ${out_name}_run${SLURM_ARRAY_TASK_ID}_pyscenic_output.loom \
--num_workers $SLURM_CPUS_PER_TASK"
echo -e "Running:\n $CMD"
$CMD
echo -e ""

date