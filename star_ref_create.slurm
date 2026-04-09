#!/bin/bash

#SBATCH --job-name=star_ref # Job name
#SBATCH --nodes=1
#SBATCH --cpus-per-task=10
#SBATCH --time=2-0
#SBATCH --mem=70000 # Memory pool for all cores (see also --mem-per-cpu)
#SBATCH --partition=low
#SBATCH --account=publicgrp
#SBATCH --output=slurmout/star_ref_%A_%a.out
#SBATCH --error=slurmout/star_ref_%A_%a.out

start=`date +%s`
hostname

REF_FASTA=$1
GTF=$2
REF_DIR=$3


module load bioinfo/star/2.7.11b

call="STAR --runThreadN $SLURM_CPUS_PER_TASK \
--runMode genomeGenerate --genomeDir $REF_DIR \
--genomeFastaFiles $REF_FASTA \
--sjdbGTFfile $GTF --sjdbOverhang ReadLength-1" 

echo $call
eval $call

end=`date +%s`
runtime=$((end-start))
echo STAR reference creation runtime: $runtime seconds
