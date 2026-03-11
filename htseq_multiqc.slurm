#!/usr/bin/bash

#SBATCH --job-name=htseq_multiqc # Job name
#SBATCH --nodes=1
#SBATCH --cpus-per-task=10
#SBATCH --time=0-3
#SBATCH --mem=20000 # Memory pool for all cores (see also --mem-per-cpu)
#SBATCH --partition=low
#SBATCH --account=publicgrp
#SBATCH --output=slurmout/htseq_%A_%a.out
#SBATCH --error=slurmout/htseq_%A_%a.out


sampfile=$1
stargtf=$2
fastqcdir=$3
htsdir=$4
stardir=$5
picarddir=$6


source /etc/profile.d/modules.sh
module use /quobyte/bioinfocore-grp/modules

############################ htseq-count
start=`date +%s`

echo "Running htseq-count..."

# get first sample id
SAMPLE=`head -n 1 $sampfile | tail -1 | cut -f1`

# find strandedness using STAR output
stranded=`tail -n +5 $stardir/$SAMPLE/$SAMPLE.paired.ReadsPerGene.out.tab | perl -ane '$u+=$F[1]; $f+=$F[2]; $r+=$F[3]; }{ if ($u>$f && $u>$r) {print "no";} elsif ($f>$u && $f>$r) {print "yes";} elsif ($r>$u && $r>$f) {print "reverse";} else {print "ERROR WITH STRAND CALC";}'`

echo "Is it stranded? $stranded"

module load htseq/2.0.3

# get sample names for header
\ls -1 $stardir | paste -s -d$'\t' > htseq.dedup.counts.tsv

call="htseq-count -n $SLURM_CPUS_PER_TASK --append-output -r pos -s $stranded -c htseq.dedup.counts.tsv $picarddir/*/*.remdup.bam $stargtf"

echo $call
eval $call

# get sample names for header
\ls -1 $stardir | paste -s -d$'\t' > htseq.ALL.counts.tsv

call="htseq-count -n $SLURM_CPUS_PER_TASK --append-output -r pos -s $stranded -c htseq.ALL.counts.tsv $stardir/*/*.paired.Aligned.sortedByCoord.out.bam $stargtf"

echo $call
eval $call

end=`date +%s`
runtime=$((end-start))
echo htseq-count Runtime: $runtime seconds

module unload htseq
##################################

########################## multiqc
start=`date +%s`

echo "Running multiqc..."
mkdir -p multiqc_reports

module load bioinfo/multiqc/1.33

call="multiqc --pdf --filename multiqc_report.html --outdir multiqc_reports $fastqcdir"
echo $call
eval $call

end=`date +%s`
runtime=$((end-start))
echo multiqc runtime: $runtime seconds

module unload bioinfo/multiqc/1.33
##################################

