#!/bin/bash

#SBATCH --job-name=hts_star # Job name
#SBATCH --nodes=1
#SBATCH --cpus-per-task=10
#SBATCH --time=3-0
#SBATCH --mem=50000 # Memory pool for all cores (see also --mem-per-cpu)
#SBATCH --partition=production


start=`date +%s`
hostname

outdir=$2

htsdir="$outdir/01-HTStream"

sampfile=$1
SAMPLE=`head -n ${SLURM_ARRAY_TASK_ID} $sampfile | tail -1 | cut -f1`
R1=`head -n ${SLURM_ARRAY_TASK_ID} $sampfile | tail -1 | cut -f2`
R2=`head -n ${SLURM_ARRAY_TASK_ID} $sampfile | tail -1 | cut -f3`

echo $SAMPLE

if [ ! -e $outdir ]; then
    mkdir $outdir
fi

if [ ! -e "$outdir/$SAMPLE" ]; then
    mkdir $outdir/$SAMPLE
fi

module load htstream
call="hts_Stats -L $outdir/$SAMPLE/$SAMPLE.stats.log -1 $R1 -2 $R2 | \
      hts_SeqScreener -A $outdir/$SAMPLE/$SAMPLE.stats.log | \
      hts_SuperDeduper -A $outdir/$SAMPLE/$SAMPLE.stats.log | \
      hts_AdapterTrimmer -A $outdir/$SAMPLE/$SAMPLE.stats.log | \
      hts_Overlapper -A $outdir/$SAMPLE/$SAMPLE.stats.log | \
      hts_QWindowTrim -A $outdir/$SAMPLE/$SAMPLE.stats.log | \
      hts_LengthFilter -m 50 -A $outdir/$SAMPLE/$SAMPLE.stats.log | \
      hts_Stats -f $outdir/$SAMPLE/$SAMPLE.cleaned -A $outdir/$SAMPLE/$SAMPLE.stats.log"

echo $call
eval $call

end=`date +%s`
runtime=$((end-start))
echo HTS Runtime: $runtime seconds

start=`date +%s`

outdir="02-STAR"
sampfile="sample_data.txt"
REF=/share/biocore/joshi/projects/Mouse_RNA-Seq_custom_genomes_Oct_2019/ref/STARindex_2.7.0f
GTF=/share/biocore/projects/Bennett_B_USDA/Mouse_RNA-Seq_custom_genomes_Oct_2019/ref/GRCm38.with_extra_genes.gtf

SAMPLE=`head -n ${SLURM_ARRAY_TASK_ID} $sampfile | tail -1`
R1="01-Cleaned/$SAMPLE/$SAMPLE.cleaned_R1.fastq.gz"
R2="01-Cleaned/$SAMPLE/$SAMPLE.cleaned_R2.fastq.gz"

echo $SAMPLE

if [ ! -e $outdir ]; then
    mkdir $outdir
fi

if [ ! -e "$outdir/$SAMPLE" ]; then
    mkdir $outdir/$SAMPLE
fi

module load star

call="STAR --runThreadN 10 \
--genomeDir $REF \
--sjdbGTFtagExonParentGene gene_id \
--sjdbGTFfile $GTF \
--quantMode GeneCounts \
--readFilesCommand zcat \
--outSAMtype BAM SortedByCoordinate \
--outFileNamePrefix $outdir/$SAMPLE/${SAMPLE}.paired. \
--readFilesIn $R1 $R2" 

echo $call
eval $call

end=`date +%s`
runtime=$((end-start))
echo Runtime: $runtime seconds
