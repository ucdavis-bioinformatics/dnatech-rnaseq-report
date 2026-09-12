# dnatech-rnaseq-report

# DNA Technologies RNA-Seq / Tag-Seq Report Pipeline

This repository contains a Slurm-based pipeline for processing **RNA-Seq** and **Tag-Seq** sequencing data and generating QC reports, alignment results, gene-level count matrices, and MDS plots.

The pipeline is designed for the **UC Davis Bioinformatics Core / DNA Technologies HPC environment** and contains paths, modules, Slurm settings, and reference genomes specific to that environment.

The primary entry point is:

```bash
./generate_tag_or_rna_report.py
```

The Python script interactively collects information about the sequencing run, determines the appropriate workflow, creates the analysis directory and sample table, and submits the required Slurm jobs.

---

# Overview

Two workflows are supported:

## RNA-Seq

For paired-end RNA-Seq data, the general workflow is:

```text
FASTQ files
    |
    v
fastp QC
    |
    v
HTStream preprocessing
    |
    +-- PhiX screening
    +-- optional rRNA screening
    +-- adapter trimming
    +-- quality trimming
    +-- minimum-length filtering
    |
    v
STAR alignment
    |
    v
Picard MarkDuplicates
    |
    +---------------------+
    |                     |
    v                     v
All aligned BAM       Deduplicated BAM
    |                     |
    +----------+----------+
               |
               v
          HTSeq-count
               |
               v
        Gene count matrices
               |
               v
            MDS plots
               |
               v
         MultiQC reports
```

## Tag-Seq

For Tag-Seq data, the general workflow is:

```text
FASTQ files
    |
    v
fastp QC
    |
    v
HTStream preprocessing
    |
    +-- UMI extraction
    +-- 5' trimming
    +-- PhiX screening
    +-- optional rRNA screening
    +-- adapter trimming
    +-- poly-A trimming
    +-- quality trimming
    +-- N filtering
    +-- minimum-length filtering
    |
    v
STAR alignment
    |
    v
UMI-tools dedup
    |
    +---------------------+
    |                     |
    v                     v
All aligned BAM       UMI-deduplicated BAM
    |                     |
    +----------+----------+
               |
               v
          HTSeq-count
               |
               v
        Gene count matrices
               |
               v
            MDS plots
               |
               v
         MultiQC reports
```

---

# Quick Start

Clone the repository:

```bash
git clone https://github.com/ucdavis-bioinformatics/dnatech-rnaseq-report.git
cd dnatech-rnaseq-report
```

Run the pipeline interactively:

```bash
./generate_tag_or_rna_report.py
```

Alternatively:

```bash
python3 generate_tag_or_rna_report.py
```

The Python script handles creation and submission of the Slurm jobs. Normally, the individual `.slurm` scripts should **not** be submitted manually.

---

# Input FASTQ Files

The pipeline expects demultiplexed, gzip-compressed FASTQ files.

## Paired-end RNA-Seq

RNA-Seq files are expected to follow an Illumina-style naming convention similar to:

```text
sample1_S1_L001_R1_001.fastq.gz
sample1_S1_L001_R2_001.fastq.gz

sample2_S2_L001_R1_001.fastq.gz
sample2_S2_L001_R2_001.fastq.gz
```

The pipeline identifies the sample name from the FASTQ filename and pairs R1 and R2 files.

Files containing:

```text
Undetermined
```

are ignored.

### Important

R1 and R2 files are collected and sorted before pairing. Carefully inspect the sample/file list displayed by the program before confirming the run.

Incorrect or inconsistent FASTQ filenames can result in incorrect R1/R2 pairing.

---

## Tag-Seq

Tag-Seq files are single-end and are expected to follow the naming convention recognized by the pipeline, for example:

```text
sample1_TAG1_R1.fastq.gz
sample2_TAG1_R1.fastq.gz
```

The sample ID is extracted from the filename.

---

# Running the Pipeline

Start the pipeline with:

```bash
./generate_tag_or_rna_report.py
```

The program will interactively request the information required for the analysis.

---

## 1. Select RNA-Seq or Tag-Seq

The program asks:

```text
RNA-Seq or TAG-Seq (rna/tag)?
```

For paired-end RNA-Seq:

```text
rna
```

For Tag-Seq:

```text
tag
```

---

## 2. Specify the FASTQ Directory

The program asks:

```text
Path to fastq file directory:
```

For example:

```text
/quobyte/some-project/my_project/
```

The program scans this directory for FASTQ files.

The basename of this directory is also used as the **project name**.

For example:

```text
/quobyte/some-project/my_project/
```

results in:

```text
project = my_project
```

---

## 3. Verify Samples

The program displays the FASTQ files and sample IDs it detected.

It then asks:

```text
Are these sample IDs, files, and project name correct (y/n)?
```

Carefully check:

* sample names
* R1 files
* R2 files
* R1/R2 pairing
* project name

If everything is correct:

```text
y
```

---

# Reference Genome Selection

The program asks:

```text
Do you want to use the mouse/human reference or not (mouse/human/n)?
```

Three choices are available.

## Human

Enter:

```text
human
```

The pipeline uses the preconfigured human reference genome, annotation, STAR index, and related files defined in:

```text
config.py
```

The current configuration uses a GRCh38-based human reference.

---

## Mouse

Enter:

```text
mouse
```

The pipeline uses the preconfigured mouse reference genome, annotation, STAR index, and related files defined in:

```text
config.py
```

The current configuration uses a GRCm39-based mouse reference.

---

## Other Species

Enter:

```text
n
```

The program then asks for:

```text
Path to reference fasta file:
```

and:

```text
Path to annotation file (GTF format):
```

The annotation must be supplied in **GTF format**.

If a custom genome is supplied, the pipeline builds a STAR genome index before starting the alignment jobs.

---

# STAR Index Generation

For a custom reference genome, the pipeline determines the sequencing read length and calculates:

```text
sjdbOverhang = read length - 1
```

For example, for 150-bp reads:

```text
sjdbOverhang = 149
```

The STAR genome index is then generated using the supplied:

```text
reference FASTA
GTF annotation
```

The RNA-Seq/Tag-Seq jobs are submitted with a Slurm dependency so that they begin only after the STAR index has been successfully generated.

---

# rRNA Screening

The program asks:

```text
Find rRNA count (y/n)?
```

If:

```text
y
```

is selected, HTStream screens reads against an rRNA reference.

For the preconfigured human and mouse genomes, the pipeline uses the rRNA reference configured for those organisms.

For another species, the program requests:

```text
Path to rRNA FASTA file:
```

This FASTA is supplied to the HTStream screening step.

If rRNA analysis is not required, enter:

```text
n
```

---

# Starting the Analysis

After configuration is complete, the program asks:

```text
Run (y/n)?
```

Enter:

```text
y
```

to create the analysis directory and submit the workflow.

---

# Analysis Directory

The pipeline creates a temporary working directory under the configured report temporary directory.

The directory name contains the project name and timestamp, for example:

```text
PROJECT.2026-09-11_175200
```

The analysis directory contains files and directories similar to:

```text
PROJECT.TIMESTAMP/
|
|-- sample_data.txt
|-- slurmout/
|-- report_dir/
|
|-- 00-FastP/
|-- 01-HTStream/
|-- 02-STAR/
|-- 03-dedup/
|
|-- *.slurm
|-- *.R
|-- MultiQC configuration files
```

The exact contents depend on whether RNA-Seq or Tag-Seq is being processed.

---

# Sample Table

The pipeline automatically creates:

```text
sample_data.txt
```

For paired-end RNA-Seq, the table contains approximately:

```text
sample1    /path/sample1_R1.fastq.gz    /path/sample1_R2.fastq.gz
sample2    /path/sample2_R1.fastq.gz    /path/sample2_R2.fastq.gz
sample3    /path/sample3_R1.fastq.gz    /path/sample3_R2.fastq.gz
```

Each row corresponds to one Slurm array task.

---

# Slurm Job Structure

The main processing workflow is submitted as a **Slurm job array**.

For `N` samples, the job is submitted approximately as:

```text
--array=1-N
```

Therefore:

```text
array task 1 -> sample 1
array task 2 -> sample 2
array task 3 -> sample 3
...
array task N -> sample N
```

This allows samples to be processed independently and in parallel.

After the array completes successfully, a dependent job performs the project-level tasks:

```text
HTSeq-count
MDS analysis
MultiQC report generation
final report assembly
```

For custom genomes, the dependency structure is approximately:

```text
STAR genome generation
        |
        v
RNA-Seq/Tag-Seq Slurm array
        |
        v
HTSeq + MDS + MultiQC
```

---

# RNA-Seq Workflow in Detail

## Step 1: fastp

Each FASTQ pair is first examined using `fastp`.

This produces per-sample QC information, including HTML and JSON output.

Typical information includes:

* total reads
* read quality
* base quality
* GC content
* adapter content
* read length
* duplication information

The fastp results are later summarized by MultiQC.

The pipeline primarily uses fastp here for QC/reporting. Read preprocessing for downstream alignment is performed with HTStream.

Output is written under:

```text
00-FastP/
```

---

# Step 2: HTStream Preprocessing

HTStream performs the main FASTQ preprocessing.

For RNA-Seq, the processing chain includes operations such as:

```text
raw FASTQ
    |
    v
read statistics
    |
    v
PhiX screening
    |
    v
optional rRNA screening
    |
    v
adapter trimming
    |
    v
quality-window trimming
    |
    v
minimum-length filtering
    |
    v
clean FASTQ
```

Reads shorter than the configured minimum length are removed.

The resulting cleaned reads are written under:

```text
01-HTStream/
```

For paired-end samples, cleaned files are similar to:

```text
01-HTStream/sample1/sample1.cleaned_R1.fastq.gz
01-HTStream/sample1/sample1.cleaned_R2.fastq.gz
```

These cleaned FASTQ files are used for alignment.

---

# Step 3: STAR Alignment

Cleaned reads are aligned to the selected reference genome using STAR.

STAR is run with gene counting enabled:

```text
--quantMode GeneCounts
```

and produces a coordinate-sorted BAM:

```text
--outSAMtype BAM SortedByCoordinate
```

Typical STAR outputs include:

```text
Aligned.sortedByCoord.out.bam
ReadsPerGene.out.tab
Log.final.out
Log.out
Log.progress.out
SJ.out.tab
```

The BAM is indexed with `samtools`.

STAR output is stored under:

```text
02-STAR/
```

The STAR logs are later incorporated into the MultiQC alignment report.

---

# Step 4: Duplicate Removal

For standard RNA-Seq, duplicate reads are removed using:

```text
Picard MarkDuplicates
```

with duplicate removal enabled.

The resulting BAM is stored under:

```text
03-dedup/
```

For example:

```text
03-dedup/sample1/sample1.remdup.bam
```

Picard also generates duplication metrics.

These metrics are included in the QC reporting.

---

# Tag-Seq Workflow in Detail

The Tag-Seq workflow follows the same general structure but contains preprocessing specific to Tag-Seq libraries.

---

## Step 1: fastp

As with RNA-Seq, fastp generates initial QC statistics and reports.

Output is stored under:

```text
00-FastP/
```

---

# Step 2: HTStream Tag-Seq Processing

Tag-Seq preprocessing includes additional operations related to the Tag-Seq library structure.

The workflow includes:

```text
raw FASTQ
    |
    v
UMI extraction
    |
    v
5' trimming
    |
    v
PhiX screening
    |
    v
optional rRNA screening
    |
    v
adapter trimming
    |
    v
poly-A trimming
    |
    v
quality trimming
    |
    v
N filtering
    |
    v
minimum-length filtering
    |
    v
clean FASTQ
```

The workflow extracts the UMI before trimming the sequence required by the library structure.

The cleaned FASTQ is then passed to STAR.

---

# Step 3: STAR Alignment

Tag-Seq reads are aligned using STAR.

As with RNA-Seq, STAR generates:

```text
coordinate-sorted BAM
gene count information
alignment logs
splice-junction information
```

Output is stored under:

```text
02-STAR/
```

---

# Step 4: UMI Deduplication

Unlike standard RNA-Seq, Tag-Seq does not use Picard duplicate removal.

Instead, duplicates are identified using:

```text
umi_tools dedup
```

UMI information is used to identify reads originating from the same original molecule.

The deduplicated BAM is stored under:

```text
03-dedup/
```

---

# Determining Library Strandedness

After all samples have been aligned, the project-level reporting job examines STAR's:

```text
ReadsPerGene.out.tab
```

output.

STAR provides counts corresponding to different strandedness assumptions.

The pipeline examines these values to determine whether the experiment appears to be:

```text
unstranded
forward stranded
reverse stranded
```

The resulting strandedness setting is then supplied to:

```text
htseq-count
```

using its:

```text
-s
```

option.

The determination is based on the STAR results from the first sample and is then applied to the project.

---

# Gene-Level Counting

Gene-level counts are generated with:

```text
htseq-count
```

using the selected GTF annotation.

The pipeline generates count matrices from both:

1. all aligned reads
2. deduplicated aligned reads

The final report directory contains files similar to:

```text
htseq.ALL.counts.tsv
htseq.dedup.counts.tsv
```

These matrices contain genes as rows and samples as columns.

The two matrices allow the effect of duplicate removal to be evaluated.

---

# MDS Analysis

The pipeline runs an R script on the count data to generate **multidimensional scaling (MDS)** plots.

MDS provides a project-level overview of the similarity between samples based on gene-expression profiles.

Samples with similar expression profiles should generally cluster near one another, while strongly different samples appear farther apart.

The MDS plots are useful for identifying:

* biological separation
* experimental groups
* possible outliers
* sample swaps
* batch effects
* unusually different samples

---

# MultiQC Reports

MultiQC is used to aggregate QC information generated throughout the workflow.

The pipeline produces reports covering major stages of the analysis.

Depending on the workflow, these include information from:

```text
fastp
HTStream
STAR
Picard
UMI-tools
```

Conceptually, the reports correspond to:

```text
RAW READS
HTSTREAM PREPROCESSING
STAR ALIGNMENT
DEDUPLICATION
```

For standard RNA-Seq, duplicate metrics are generated with Picard.

For Tag-Seq, deduplication is performed with UMI-tools.

MultiQC collects metrics across all samples, allowing the entire sequencing project to be inspected in a single HTML report.

---

# Final Output

When processing and reporting have completed, the final:

```text
report_dir/
```

is copied back to the original FASTQ/project directory supplied when the pipeline was started.

For example, if the original input directory was:

```text
/quobyte/project123/
```

then the final result will be available under:

```text
/quobyte/project123/report_dir/
```

The report directory contains the primary deliverables from the pipeline, including:

```text
gene count matrices
MDS plots
MultiQC HTML reports
QC/reporting files
```

---

# Intermediate Output

Intermediate processing occurs in directories such as:

```text
00-FastP/
01-HTStream/
02-STAR/
03-dedup/
```

These directories contain useful diagnostic and intermediate files but are not necessarily intended to be the primary project deliverables.

---

# Directory Summary

| Directory      | Description                                                          |
| -------------- | -------------------------------------------------------------------- |
| `00-FastP/`    | Initial FASTQ QC generated by fastp                                  |
| `01-HTStream/` | FASTQ preprocessing and cleaned reads                                |
| `02-STAR/`     | STAR alignments, BAMs, counts, and alignment logs                    |
| `03-dedup/`    | Picard- or UMI-deduplicated BAMs and metrics                         |
| `slurmout/`    | Slurm stdout/stderr files                                            |
| `report_dir/`  | Final count matrices, MDS results, MultiQC reports, and deliverables |

---

# File-by-File Description

The repository contains scripts for orchestration, per-sample processing, project-level reporting, plotting, and configuration.

## `generate_tag_or_rna_report.py`

This is the **main entry point and workflow controller**.

Run it with:

```bash
./generate_tag_or_rna_report.py
```

Its responsibilities include:

1. asking whether the project is RNA-Seq or Tag-Seq
2. requesting the FASTQ directory
3. finding FASTQ files
4. determining sample IDs
5. pairing RNA-Seq R1/R2 FASTQs
6. determining the project name
7. asking the user to verify the detected samples
8. selecting human, mouse, or a custom genome
9. collecting custom FASTA/GTF paths when required
10. configuring optional rRNA screening
11. determining read length when necessary
12. calculating the appropriate STAR `sjdbOverhang`
13. creating the temporary project analysis directory
14. generating `sample_data.txt`
15. copying required workflow files into the analysis directory
16. submitting STAR index generation when required
17. submitting the RNA-Seq or Tag-Seq Slurm array
18. setting Slurm job dependencies
19. submitting the final HTSeq/MDS/MultiQC job

In normal use, **this is the only script the user needs to run directly**.

---

## `config.py`

Contains shared configuration used by the workflow.

This includes settings such as:

* temporary report directory
* human reference files
* mouse reference files
* STAR genome index locations
* GTF annotation locations
* rRNA reference locations
* workflow output directory names
* other paths used by the pipeline

Many paths in this file are specific to the UC Davis Bioinformatics Core/DNA Technologies environment.

This file is the primary place to update paths if reference genomes or storage locations change.

---

## `rnaseq_pe.slurm`

Runs the **per-sample paired-end RNA-Seq workflow**.

This script is normally submitted as a Slurm array by:

```text
generate_tag_or_rna_report.py
```

Each Slurm array task reads one row from:

```text
sample_data.txt
```

and processes one sample.

Major operations include:

```text
fastp
  |
HTStream
  |
STAR
  |
samtools index
  |
Picard MarkDuplicates
```

The script creates the per-sample intermediate data used by the later project-level reporting job.

It also loads the required software modules and defines the CPU, memory, runtime, partition, and account requirements for the job.

---

## `tagseq.slurm`

Runs the **per-sample Tag-Seq workflow**.

Like `rnaseq_pe.slurm`, this is normally submitted as a Slurm array.

Each array task processes one sample from:

```text
sample_data.txt
```

The major processing stages are:

```text
fastp
  |
HTStream
  |
UMI extraction / Tag-Seq trimming
  |
STAR
  |
samtools
  |
UMI-tools dedup
```

This script contains the Tag-Seq-specific preprocessing logic, including UMI handling and library-specific trimming.

---

## `htseq_multiqc.slurm`

Runs the **project-level analysis after all sample jobs have completed**.

This job is submitted with a dependency on the RNA-Seq or Tag-Seq Slurm array.

Its responsibilities include:

1. examining STAR gene-count output
2. determining library strandedness
3. selecting the appropriate HTSeq strandedness option
4. running HTSeq-count
5. generating counts from all aligned BAMs
6. generating counts from deduplicated BAMs
7. assembling project-wide count matrices
8. running the MDS analysis
9. running MultiQC
10. creating final QC reports
11. assembling `report_dir`
12. copying the final report directory back to the original project/FASTQ directory

This script converts the individual sample results into the final project-level deliverables.

---

## STAR Genome Generation Slurm Script

The repository includes a Slurm workflow for generating a STAR genome index when a custom genome is supplied.

This step uses:

```text
reference FASTA
GTF annotation
sjdbOverhang
```

to generate the STAR genome directory.

The job requests more memory than an ordinary sample processing job because STAR genome generation can require substantial RAM.

The sample-processing Slurm array is submitted with a dependency on successful completion of this job.

Human and mouse analyses normally use prebuilt STAR indices and therefore do not require this step.

---

## MDS R Script

The repository includes an R script used to create MDS plots from the project count matrices.

The script reads gene-level count data and calculates sample-to-sample relationships based on expression profiles.

Its output is incorporated into the final report.

The MDS plot provides a rapid way to evaluate whether samples cluster according to expected biological or experimental groups.

---

## MultiQC Configuration Files

The repository contains configuration used to customize MultiQC reports.

These files control aspects of the final reports such as:

* report organization
* module ordering
* section names
* display options
* custom QC information

The pipeline generates separate QC summaries for different stages of the workflow rather than relying on a single unstructured scan of all intermediate files.

---

# Software Used

The pipeline uses several bioinformatics tools.

The versions are defined by the modules loaded by the Slurm scripts.

Tools include:

| Tool        | Purpose                                                 |
| ----------- | ------------------------------------------------------- |
| `fastp`     | Initial FASTQ quality assessment                        |
| `HTStream`  | FASTQ preprocessing, screening, trimming, and filtering |
| `STAR`      | RNA read alignment and initial gene counts              |
| `samtools`  | BAM manipulation and indexing                           |
| `Picard`    | Duplicate identification/removal for RNA-Seq            |
| `UMI-tools` | UMI-aware duplicate removal for Tag-Seq                 |
| `HTSeq`     | Gene-level read counting                                |
| `R`         | MDS analysis and report-related processing              |
| `MultiQC`   | Aggregation of QC metrics into HTML reports             |

---

# Current HPC Configuration

The workflow is written for Slurm and currently assumes UC Davis-specific resources.

Typical per-sample RNA-Seq/Tag-Seq jobs request approximately:

```text
CPUs:       10
Memory:     50 GB
Time:       1 day
```

STAR genome generation requests approximately:

```text
CPUs:       10
Memory:     70 GB
Time:       3 hours
```

The scripts also contain UC Davis-specific Slurm settings such as:

```text
partition
account
module paths
Quobyte paths
```

Therefore, the repository should not be expected to run unchanged on an unrelated HPC system.

---

# Monitoring a Run

After the workflow is submitted, jobs can be monitored with:

```bash
squeue -u $USER
```

A more compact display can be useful:

```bash
squeue -u $USER -o "%.18i %.9P %.30j %.8T %.10M %.6D %R"
```

Slurm output and error logs are stored under:

```text
slurmout/
```

These files should be checked first if a sample or project-level job fails.

---

# Troubleshooting

## No FASTQ files are detected

Check the FASTQ filenames.

The pipeline expects particular Illumina/Tag-Seq filename patterns. Files with unusual naming conventions may not be recognized.

---

## R1 and R2 files are paired incorrectly

The script collects and sorts the FASTQ filenames before pairing them.

Check the file list displayed by:

```text
generate_tag_or_rna_report.py
```

before answering:

```text
Are these sample IDs, files, and project name correct?
```

Do not continue if R1 and R2 samples do not correspond correctly.

---

## `Undetermined` reads are missing

This is expected.

FASTQ files containing:

```text
Undetermined
```

are intentionally excluded from the sample analysis.

---

## STAR index generation fails

Check:

```text
slurmout/
```

and verify:

* reference FASTA exists
* GTF exists
* FASTA and GTF use compatible chromosome/contig names
* sufficient memory is available
* files are readable from the compute nodes

---

## STAR alignment fails

Check the sample's STAR log files under:

```text
02-STAR/
```

and the corresponding Slurm log under:

```text
slurmout/
```

Common problems include:

* incompatible STAR index
* malformed FASTQ
* truncated FASTQ
* inaccessible files
* insufficient memory
* reference/annotation mismatch

---

## HTSeq-count produces unexpected counts

Check:

* GTF annotation
* gene attributes
* strandedness
* STAR alignment rate
* whether chromosome names in the BAM and GTF match

Also inspect:

```text
ReadsPerGene.out.tab
```

from STAR to confirm the inferred strandedness is reasonable.

---

## MultiQC report is incomplete

Check that the expected upstream output files exist.

MultiQC works by scanning analysis outputs for recognized files. Missing or failed upstream steps can therefore cause sections or samples to be absent from the report.

---

# Restarting Failed Analyses

The workflow does not function like a workflow manager such as Nextflow or Snakemake with automatic task caching/resumption.

Before restarting a failed analysis:

1. identify the failed Slurm job
2. inspect `slurmout/`
3. determine which processing stage failed
4. check whether intermediate output is complete
5. remove or preserve partial output as appropriate
6. resubmit the required processing step

Care should be taken not to mistake incomplete intermediate files for successfully completed results.

---

# Primary Deliverables

For most projects, the most important final files are located in:

```text
report_dir/
```

The main deliverables are:

### Gene count matrices

```text
htseq.ALL.counts.tsv
htseq.dedup.counts.tsv
```

### MDS plots

Used to assess relationships among samples based on gene-expression profiles.

### MultiQC reports

HTML reports summarizing sequencing QC, preprocessing, alignment, and duplication metrics across all samples.

These files provide the primary QC and gene-expression data for downstream RNA-Seq analysis.

---

# Recommended Usage

The intended workflow is:

```bash
git clone https://github.com/ucdavis-bioinformatics/dnatech-rnaseq-report.git

cd dnatech-rnaseq-report

./generate_tag_or_rna_report.py
```

Answer the interactive prompts, verify the detected samples carefully, and allow the Python program to submit and manage the Slurm dependency chain.

Do **not** normally submit:

```text
rnaseq_pe.slurm
tagseq.slurm
htseq_multiqc.slurm
```

directly.

These scripts expect variables, files, directory structures, and dependencies prepared by:

```text
generate_tag_or_rna_report.py
```

---

# Pipeline Summary

For paired-end RNA-Seq:

```text
generate_tag_or_rna_report.py
          |
          v
     sample_data.txt
          |
          v
   rnaseq_pe.slurm
     [job array]
          |
          +--> fastp
          +--> HTStream
          +--> STAR
          +--> Picard
          |
          v
 htseq_multiqc.slurm
          |
          +--> strandedness detection
          +--> HTSeq-count
          +--> count matrices
          +--> MDS
          +--> MultiQC
          |
          v
      report_dir/
          |
          v
 Original FASTQ directory
```

For Tag-Seq:

```text
generate_tag_or_rna_report.py
          |
          v
     sample_data.txt
          |
          v
      tagseq.slurm
       [job array]
          |
          +--> fastp
          +--> HTStream
          +--> UMI processing
          +--> STAR
          +--> UMI-tools dedup
          |
          v
 htseq_multiqc.slurm
          |
          +--> strandedness detection
          +--> HTSeq-count
          +--> count matrices
          +--> MDS
          +--> MultiQC
          |
          v
      report_dir/
          |
          v
 Original FASTQ directory
```

For a custom genome, an additional dependency is inserted:

```text
STAR genome generation
          |
          v
 RNA-Seq / Tag-Seq array
          |
          v
 HTSeq / MDS / MultiQC
          |
          v
      report_dir/
```

---

# Notes

This pipeline was developed for routine RNA-Seq and Tag-Seq processing in the UC Davis Bioinformatics Core/DNA Technologies computing environment.

Because reference locations, module paths, Slurm configuration, and storage paths are environment-specific, review:

```text
config.py
*.slurm
```

before attempting to use the pipeline on another HPC system.

