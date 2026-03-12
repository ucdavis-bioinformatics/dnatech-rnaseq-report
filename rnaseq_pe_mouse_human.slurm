#!/usr/bin/bash

#SBATCH --job-name=rnaseq_mh # Job name
#SBATCH --nodes=1
#SBATCH --cpus-per-task=10
#SBATCH --time=3-0
#SBATCH --mem=50000 # Memory pool for all cores (see also --mem-per-cpu)
#SBATCH --partition=low
#SBATCH --account=publicgrp
#SBATCH --output=slurmout/rnaseq_mh_%A_%a.out
#SBATCH --error=slurmout/rnaseq_mh_%A_%a.out


hostname
sampfile=$1
starref=$2
stargtf=$3
dorrna=$4
rrnafile=$5
fastqcdir=$6
htsdir=$7
stardir=$8
picarddir=$9


SAMPLE=`head -n ${SLURM_ARRAY_TASK_ID} $sampfile | tail -1 | cut -f1`
R1=`head -n ${SLURM_ARRAY_TASK_ID} $sampfile | tail -1 | cut -f2`
R2=`head -n ${SLURM_ARRAY_TASK_ID} $sampfile | tail -1 | cut -f3`

echo "Sample: $SAMPLE"

source /etc/profile.d/modules.sh

############### fastqc
start=`date +%s`

mkdir -p $fastqcdir/$SAMPLE

echo "Running FastQC..."

module load fastqc/0.12.1

call="fastqc --threads $SLURM_CPUS_PER_TASK -o $fastqcdir/$SAMPLE $R1 $R2"
echo $call
eval $call

end=`date +%s`
runtime=$((end-start))
echo FastQC Runtime: $runtime seconds

module unload fastqc

#########################

################### htstream
start=`date +%s`

echo "Running HTStream..."

mkdir -p $htsdir/$SAMPLE

#module load htstream/1.3.3
module load conda/htstream/1.4.1

if [ $dorrna == "y" ]; then

    call="hts_Stats -L $htsdir/$SAMPLE/$SAMPLE.stats.log -1 $R1 -2 $R2 | \
      hts_SeqScreener -A $htsdir/$SAMPLE/$SAMPLE.stats.log | \
      hts_SeqScreener -A $htsdir/$SAMPLE/$SAMPLE.stats.log -s $rrnafile | \
      hts_AdapterTrimmer -A $htsdir/$SAMPLE/$SAMPLE.stats.log | \
      hts_QWindowTrim -A $htsdir/$SAMPLE/$SAMPLE.stats.log | \
      hts_LengthFilter -m 50 -A $htsdir/$SAMPLE/$SAMPLE.stats.log | \
      hts_Stats -F -f $htsdir/$SAMPLE/$SAMPLE.cleaned -A $htsdir/$SAMPLE/$SAMPLE.stats.log"
else

    call="hts_Stats -L $htsdir/$SAMPLE/$SAMPLE.stats.log -1 $R1 -2 $R2 | \
      hts_SeqScreener -A $htsdir/$SAMPLE/$SAMPLE.stats.log | \
      hts_AdapterTrimmer -A $htsdir/$SAMPLE/$SAMPLE.stats.log | \
      hts_QWindowTrim -A $htsdir/$SAMPLE/$SAMPLE.stats.log | \
      hts_LengthFilter -m 50 -A $htsdir/$SAMPLE/$SAMPLE.stats.log | \
      hts_Stats -F -f $htsdir/$SAMPLE/$SAMPLE.cleaned -A $htsdir/$SAMPLE/$SAMPLE.stats.log"
fi

echo $call
eval $call

end=`date +%s`
runtime=$((end-start))
echo HTStream Runtime: $runtime seconds

module unload htstream
##########################


######################### STAR
start=`date +%s`

echo "Running STAR..."

mkdir -p $stardir/$SAMPLE

CLEANED_R1="$htsdir/$SAMPLE/$SAMPLE.cleaned_R1.fastq.gz"
CLEANED_R2="$htsdir/$SAMPLE/$SAMPLE.cleaned_R2.fastq.gz"

module load star/2.7.11a

call="STAR --runThreadN $SLURM_CPUS_PER_TASK \
--genomeDir $starref \
--sjdbGTFtagExonParentGene gene_id \
--sjdbGTFfile $stargtf \
--quantMode GeneCounts \
--readFilesCommand zcat \
--outSAMtype BAM SortedByCoordinate \
--outFileNamePrefix $stardir/$SAMPLE/${SAMPLE}.paired. \
--readFilesIn $CLEANED_R1 $CLEANED_R2"

echo $call
eval $call

module unload star
module load samtools/1.19.2

call="samtools index --threads $SLURM_CPUS_PER_TASK $stardir/$SAMPLE/${SAMPLE}.paired.Aligned.sortedByCoord.out.bam"
echo $call
eval $call

end=`date +%s`
runtime=$((end-start))
echo STAR Runtime: $runtime seconds

module unload samtools
##################################


##################### picard (remove duplicates)
start=`date +%s`

echo "Running picard (removing duplicates)..."

mkdir -p $picarddir/$SAMPLE

BAMFILE="$stardir/$SAMPLE/${SAMPLE}.paired.Aligned.sortedByCoord.out.bam"

module load picard/3.1.1

call="picard MarkDuplicates --REMOVE_DUPLICATES true --INPUT $BAMFILE --METRICS_FILE $picarddir/$SAMPLE/$SAMPLE.picard.metrics --OUTPUT $picarddir/$SAMPLE/$SAMPLE.remdup.bam"

echo $call
eval $call

module load samtools/1.19.2
call="samtools index --threads $SLURM_CPUS_PER_TASK $picarddir/$SAMPLE/$SAMPLE.remdup.bam"
echo $call
eval $call

end=`date +%s`
runtime=$((end-start))
echo Picard Runtime: $runtime seconds

module unload samtools
module unload picard
##################################

