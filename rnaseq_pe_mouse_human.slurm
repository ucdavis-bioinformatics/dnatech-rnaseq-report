#!/bin/bash

#SBATCH --job-name=rnaseq_mh # Job name
#SBATCH --nodes=1
#SBATCH --cpus-per-task=10
#SBATCH --time=3-0
#SBATCH --mem=50000 # Memory pool for all cores (see also --mem-per-cpu)
#SBATCH --partition=production


hostname
sampfile=$1
outdir=$2
starref=$3
stargtf=$4
dorrna=$5
rrnafile=$6

if [ ! -e $outdir ]; then
    mkdir $outdir
fi


SAMPLE=`head -n ${SLURM_ARRAY_TASK_ID} $sampfile | tail -1 | cut -f1`
R1=`head -n ${SLURM_ARRAY_TASK_ID} $sampfile | tail -1 | cut -f2`
R2=`head -n ${SLURM_ARRAY_TASK_ID} $sampfile | tail -1 | cut -f3`

echo "Sample: $SAMPLE"

############### fastqc
start=`date +%s`

fastqcdir="$outdir/00-FastQC"
mkdir -p $fastqcdir/$SAMPLE

echo "Running FastQC..."

module load fastqc/0.12.1

call="fastqc --threads 10 -o $fastqcdir/$SAMPLE $R1 $R2"
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

htsdir="$outdir/01-HTStream"
mkdir -p $htsdir/$SAMPLE

module load htstream/1.4.1

if [ $dorrna == "y" ]; then

    call="hts_Stats -L $htsdir/$SAMPLE/$SAMPLE.stats.log -1 $R1 -2 $R2 | \
      hts_SeqScreener -A $htsdir/$SAMPLE/$SAMPLE.stats.log | \
      hts_SeqScreener -A $htsdir/$SAMPLE/$SAMPLE.stats.log -s $rrnafile | \
      hts_AdapterTrimmer -A $htsdir/$SAMPLE/$SAMPLE.stats.log | \
      hts_QWindowTrim -A $htsdir/$SAMPLE/$SAMPLE.stats.log | \
      hts_LengthFilter -m 50 -A $htsdir/$SAMPLE/$SAMPLE.stats.log | \
      hts_Stats -f $htsdir/$SAMPLE/$SAMPLE.cleaned -A $htsdir/$SAMPLE/$SAMPLE.stats.log"
else

    call="hts_Stats -L $htsdir/$SAMPLE/$SAMPLE.stats.log -1 $R1 -2 $R2 | \
      hts_SeqScreener -A $htsdir/$SAMPLE/$SAMPLE.stats.log | \
      hts_AdapterTrimmer -A $htsdir/$SAMPLE/$SAMPLE.stats.log | \
      hts_QWindowTrim -A $htsdir/$SAMPLE/$SAMPLE.stats.log | \
      hts_LengthFilter -m 50 -A $htsdir/$SAMPLE/$SAMPLE.stats.log | \
      hts_Stats -f $htsdir/$SAMPLE/$SAMPLE.cleaned -A $htsdir/$SAMPLE/$SAMPLE.stats.log"
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

stardir="$outdir/02-STAR"
mkdir -p $stardir/$SAMPLE
sampfile="sample_data.txt"

CLEANED_R1="01-HTStream/$SAMPLE/$SAMPLE.cleaned_R1.fastq.gz"
CLEANED_R2="01-HTStream/$SAMPLE/$SAMPLE.cleaned_R2.fastq.gz"

module load star/2.7.11b

call="STAR --runThreadN 10 \
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

end=`date +%s`
runtime=$((end-start))
echo STAR Runtime: $runtime seconds

module unload star
##################################
