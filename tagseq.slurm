#!/usr/bin/bash

#SBATCH --job-name=tagseq # Job name
#SBATCH --nodes=1
#SBATCH --cpus-per-task=10
#SBATCH --time=1-0
#SBATCH --mem=50000 # Memory pool for all cores (see also --mem-per-cpu)
#SBATCH --partition=low
#SBATCH --account=publicgrp
#SBATCH --output=slurmout/tagseq_%A_%a.out
#SBATCH --error=slurmout/tagseq_%A_%a.out


hostname
sampfile=$1
starref=$2
stargtf=$3
dorrna=$4
rrnafile=$5
fastpdir=$6
htsdir=$7
stardir=$8
dedupdir=$9


SAMPLE=`head -n ${SLURM_ARRAY_TASK_ID} $sampfile | tail -1 | cut -f1`
R1=`head -n ${SLURM_ARRAY_TASK_ID} $sampfile | tail -1 | cut -f2`

echo "Sample: $SAMPLE"

source /etc/profile.d/modules.sh
module use /quobyte/bioinfocore-grp/modules

############### fastp
start=`date +%s`

mkdir -p $fastpdir/$SAMPLE

echo "Running FastP..."

module load fastp/0.23.4

call="fastp --thread $SLURM_CPUS_PER_TASK -i $R1 -j $fastpdir/$SAMPLE/$SAMPLE.fastp.json -h $fastpdir/$SAMPLE/$SAMPLE.fastp.html"
echo $call
eval $call

end=`date +%s`
runtime=$((end-start))
echo FastP Runtime: $runtime seconds

module unload fastp/0.23.4

#########################

################### htstream
start=`date +%s`

echo "Running HTStream..."

mkdir -p $htsdir/$SAMPLE

module load conda/htstream/1.4.1

if [ $dorrna == "y" ]; then

    call="hts_Stats -L ${htsdir}/${SAMPLE}/${SAMPLE}.stats.json -N 'initial stats' \
          -U $R1 | \
        hts_SeqScreener -A ${htsdir}/${SAMPLE}/${SAMPLE}.stats.json -N 'screen phix' | \
        hts_SeqScreener -A $htsdir/$SAMPLE/$SAMPLE.stats.json -s $rrnafile -N 'screen rRNA' | \
        hts_ExtractUMI -A ${htsdir}/${SAMPLE}/${SAMPLE}.stats.json -N 'extract UMIS' | \
        hts_CutTrim -a 16 -A ${htsdir}/${SAMPLE}/${SAMPLE}.stats.json -N 'trim first 16 bases' | \
        hts_AdapterTrimmer -A ${htsdir}/${SAMPLE}/${SAMPLE}.stats.json -N 'trim adapters' | \
        hts_PolyATTrim --no-left --skip_polyT -A ${htsdir}/${SAMPLE}/${SAMPLE}.stats.json -N 'remove polyA' | \
        hts_QWindowTrim -A ${htsdir}/${SAMPLE}/${SAMPLE}.stats.json -N 'quality trim the ends of reads' | \
        hts_NTrimmer -A ${htsdir}/${SAMPLE}/${SAMPLE}.stats.json -N 'remove any remaining N bases' | \
        hts_LengthFilter -A ${htsdir}/${SAMPLE}/${SAMPLE}.stats.json -N 'remove reads < 30 bp' \
        -n -m 30 | \
        hts_Stats -A ${htsdir}/${SAMPLE}/${SAMPLE}.stats.json -N 'final stats' \
        -f ${htsdir}/${SAMPLE}/${SAMPLE}.cleaned"

else

    call="hts_Stats -L ${htsdir}/${SAMPLE}/${SAMPLE}.stats.json -N 'initial stats' \
          -U $R1 | \
        hts_SeqScreener -A ${htsdir}/${SAMPLE}/${SAMPLE}.stats.json -N 'screen phix' | \
        hts_ExtractUMI -A ${htsdir}/${SAMPLE}/${SAMPLE}.stats.json -N 'extract UMIs' | \
        hts_CutTrim -a 16 -A ${htsdir}/${SAMPLE}/${SAMPLE}.stats.json -N 'trim first 16 bases' | \
        hts_AdapterTrimmer -A ${htsdir}/${SAMPLE}/${SAMPLE}.stats.json -N 'trim adapters' | \
        hts_PolyATTrim --no-left --skip_polyT -A ${htsdir}/${SAMPLE}/${SAMPLE}.stats.json -N 'remove polyA' | \
        hts_QWindowTrim -A ${htsdir}/${SAMPLE}/${SAMPLE}.stats.json -N 'quality trim the ends of reads' | \
        hts_NTrimmer -A ${htsdir}/${SAMPLE}/${SAMPLE}.stats.json -N 'remove any remaining N bases' | \
        hts_LengthFilter -A ${htsdir}/${SAMPLE}/${SAMPLE}.stats.json -N 'remove reads < 30 bp' \
        -n -m 30 | \
        hts_Stats -A ${htsdir}/${SAMPLE}/${SAMPLE}.stats.json -N 'final stats' \
        -f ${htsdir}/${SAMPLE}/${SAMPLE}.cleaned"

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

CLEANED_SE="$htsdir/$SAMPLE/$SAMPLE.cleaned_SE.fastq.gz"

module load bioinfo/star/2.7.11b

call="STAR --runThreadN $SLURM_CPUS_PER_TASK \
--genomeDir $starref \
--sjdbGTFtagExonParentGene gene_id \
--sjdbGTFfile $stargtf \
--quantMode GeneCounts \
--readFilesCommand zcat \
--outSAMtype BAM SortedByCoordinate \
--outFileNamePrefix $stardir/$SAMPLE/${SAMPLE}. \
--readFilesIn $CLEANED_SE"

echo $call
eval $call

module unload star
module load samtools/1.19.2

call="samtools index --threads $SLURM_CPUS_PER_TASK $stardir/$SAMPLE/${SAMPLE}.Aligned.sortedByCoord.out.bam"
echo $call
eval $call

end=`date +%s`
runtime=$((end-start))
echo STAR Runtime: $runtime seconds

module unload samtools
##################################


##################### umitools (remove duplicates)
start=`date +%s`

echo "Running UMI-tools (removing duplicates)..."

mkdir -p $dedupdir/$SAMPLE

BAMFILE="$stardir/$SAMPLE/${SAMPLE}.Aligned.sortedByCoord.out.bam"

module load bioinfo/umitools/1.1.6

call=" umi_tools dedup -I $BAMFILE \
                 --log=$dedupdir/${SAMPLE}/${SAMPLE}.remdup.log \
                 -S $dedupdir/${SAMPLE}/${SAMPLE}.remdup.bam"
echo $call
eval $call

module load samtools/1.19.2
call="samtools index --threads $SLURM_CPUS_PER_TASK $dedupdir/$SAMPLE/$SAMPLE.remdup.bam"
echo $call
eval $call

end=`date +%s`
runtime=$((end-start))
echo UMI-tools Runtime: $runtime seconds

module unload samtools
module unload umtiools
##################################

