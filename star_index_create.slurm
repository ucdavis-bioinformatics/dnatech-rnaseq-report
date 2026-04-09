#!/bin/bash

#SBATCH --job-name=star_index # Job name
#SBATCH --nodes=1
#SBATCH --cpus-per-task=10
#SBATCH --time=0-3
#SBATCH --mem=70000 # Memory pool for all cores (see also --mem-per-cpu)
#SBATCH --partition=low
#SBATCH --account=publicgrp
#SBATCH --output=slurmout/star_index_%A_%a.out
#SBATCH --error=slurmout/star_index_%A_%a.out

start=`date +%s`
hostname

REF_FASTA=$1
GTF=$2
INDEX_DIR=$3
OVERHANG=$4

source /etc/profile.d/modules.sh
module use /quobyte/bioinfocore-grp/modules

module load bioinfo/star/2.7.11b

call="STAR --runThreadN $SLURM_CPUS_PER_TASK \
--runMode genomeGenerate --genomeDir $INDEX_DIR \
--genomeFastaFiles $REF_FASTA \
--sjdbGTFfile $GTF --sjdbOverhang $OVERHANG" 

echo $call
eval $call

end=`date +%s`
runtime=$((end-start))
echo STAR reference creation runtime: $runtime seconds
