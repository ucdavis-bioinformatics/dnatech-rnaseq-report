#!/usr/bin/env python3

# /share/illumina/hiseq/251222_DTSA1203_NovaX25B/Un_DTSA1203/Project_DLNK_Nova1437P_Krishnakumar/
# /quobyte/danikagrp/fastq/DNATechCore_241203/Data/ywsgtue2vu/Un_DTSA1014/Project_DBJV_NovaSeq1194P_Vo

import readline
import os
import re
import sys
import subprocess
import gzip
from config import *

hm_data = {"human" : {"star_index_dir" : STAR_INDEX_HUMAN_DIR,
                      "star_gtf" : STAR_GTF_HUMAN_FILE,
                      "rrna_file" : RRNA_HUMAN_FILE
            },

           "mouse" : {"star_index_dir" : STAR_INDEX_MOUSE_DIR,
                      "star_gtf" : STAR_GTF_MOUSE_FILE,
                      "rrna_file" : RRNA_MOUSE_FILE
            }
} 


readline.set_completer_delims(' \t\n=')
readline.parse_and_bind("tab:complete")

while True:
    tag_or_rna = input("RNA-Seq or TAG-Seq (rna/tag)? ")
    if tag_or_rna == "rna" or tag_or_rna == "tag":
        break
    else:
        print("Invalid input, try again.")


while True:
    inputdir = input("Path to fastq file directory: ")
    if os.access(inputdir, os.R_OK) and os.path.exists(inputdir):
        break
    else:
        print("Path does not exist or you do not have read permission. Try again.")


input_files_R1 = [f for f in os.listdir(inputdir) if re.match(r'^(?!.*Undetermined).*R1.*.fastq.gz', f)]
input_files_R1.sort()

input_files_R2 = [f for f in os.listdir(inputdir) if re.match(r'^(?!.*Undetermined).*R2.*.fastq.gz', f)]
input_files_R2.sort()

print("Input files:\n", input_files_R1, "\n", input_files_R2, "\n")

# find length of reads
with gzip.open(f"{inputdir}/{input_files_R1[0]}", 'rb') as file:
    file.readline() # header line
    readlen = len(file.readline().strip())

print(f"Read Length: {readlen}")


sample_ids = [re.search(r'^(.+)_S\d+_L\d+_R\d_\d+.fastq.gz', s).group(1) for s in input_files_R1]
# get unique ids
sample_ids = list(set(sample_ids))
sample_ids.sort()

print("Sample IDs:\n", sample_ids, "\n")

while True:
    sampidcheck = input("Are these sample IDs correct (y/n)? ")
    if sampidcheck == "y" or sampidcheck == "n":
        break
    else:
        print("Invalid input, try again.")


if sampidcheck == "n":
    print("Exiting.")
    sys.exit(1)


while True:
    outputdir = input("\nPath to new output directory: ")
    if os.access(os.path.dirname(outputdir), os.W_OK) and not os.path.exists(outputdir):
        break
    else:
        print("Path exists or you do not have write access to that path. Choose a new path.")


while True:
    mhcheck = input("\nDo you want to use the mouse/human reference or not (mouse/human/n)? ")
    if mhcheck == "mouse" or mhcheck == "human" or mhcheck == "n":
        break
    else:
        print("Invalid input, try again.")


star_index_dir=""
star_gtf=""
star_fasta=""
if mhcheck=="mouse" or mhcheck=="human":
    star_index_dir = hm_data[mhcheck]["star_index_dir"]
    star_gtf = hm_data[mhcheck]["star_gtf"]
else:
    while True:
        star_fasta = input("\nPath to reference fasta file: ")
        if os.access(star_fasta, os.R_OK) and os.path.exists(star_fasta):
            break
        else:
            print("File does not exist or you do not have read permission. Try again.")

    while True:
        star_gtf = input("\nPath to annotation file (GTF format): ")
        if os.access(star_gtf, os.R_OK) and os.path.exists(star_gtf):
            break
        else:
            print("File does not exist or you do not have read permission. Try again.")


while True:
    rrna_check = input("Find rRNA count (y/n)? ")
    if rrna_check == "y" or rrna_check == "n":
        break
    else:
        print("Invalid input, try again.")


rrna_fasta="NA"
if (rrna_check == "y"):
    if (mhcheck == "mouse" or mhcheck == "human"):
        rrna_fasta = hm_data[mhcheck]["rrna_file"]
    else:
        while True:
            rrna_fasta = input("Path to rRNA FASTA file: ")
            if os.access(rrna_fasta, os.R_OK) and os.path.exists(rrna_fasta):
                break
            else:
                print("File does not exist or you do not have read permission. Try again.")


while True:
    runcheck = input("\nRun (y/n)? ")
    if runcheck == "y" or runcheck == "n":
        break
    else:
        print("Invalid input, try again.")


if runcheck == "n":
    print("Exiting.")
    sys.exit(1)


if not os.path.exists(outputdir):
    print("Creating output directory...")
    os.system(f"mkdir -p {outputdir}")
    os.system(f"mkdir -p {outputdir}/slurmout")
    os.system(f"mkdir -p {outputdir}/report_dir")


print("Copying scripts, templates, and config...")
if tag_or_rna == "rna":

    if mhcheck == "n":
        os.system(f"cp star_index_create.slurm {outputdir}")

    os.system(f"cp rnaseq_pe.slurm htseq_multiqc.slurm mds.R multiqc_config_pdf.yaml {outputdir}")
    os.system(f"cp biocore_banner.png final_report.html mds_plots.html {outputdir}/report_dir/")

print("Creating sample info file...")
if tag_or_rna == "rna":
    with open(f"{outputdir}/{SAMPLE_FILE}", 'w') as file:
        for index,sampid in enumerate(sample_ids):
            file.write(f"{sampid}\t{inputdir}/{input_files_R1[index]}\t{inputdir}/{input_files_R2[index]}\n")

os.chdir(outputdir)

print("Submitting slurm array script for all samples...")
if tag_or_rna == "rna":

    index_dep=""
    # if we need to make a custom star index
    if mhcheck == "n":

        star_index_dir = "star_index"
        os.system(f"mkdir {star_index_dir}")

        print(f"sbatch star_index_create.slurm {star_fasta} {star_gtf} {star_index_dir} {readlen-1}")
        sbatch_output = subprocess.run(f"sbatch star_index_create.slurm {star_fasta} {star_gtf} {star_index_dir} {readlen-1}", shell=True, capture_output=True)
        batch_jobid = re.search(r'^Submitted batch job (\d+)', sbatch_output.stdout.decode('utf-8')).group(1)
        index_dep = f"--dependency=afterok:{batch_jobid}"


    # submit rna seq job
    print(f"sbatch {index_dep} --array=1-{len(sample_ids)} rnaseq_pe.slurm {SAMPLE_FILE} {star_index_dir} {star_gtf} {rrna_check} {rrna_fasta} {FASTP_DIR} {HTS_DIR} {STAR_DIR} {PICARD_DIR}")
    sbatch_output = subprocess.run(f"sbatch {index_dep} --array=1-{len(sample_ids)} rnaseq_pe.slurm {SAMPLE_FILE} {star_index_dir} {star_gtf} {rrna_check} {rrna_fasta} {FASTP_DIR} {HTS_DIR} {STAR_DIR} {PICARD_DIR}", shell=True, capture_output=True)

    #print(sbatch_output.stdout)
    batch_jobid = re.search(r'^Submitted batch job (\d+)', sbatch_output.stdout.decode('utf-8')).group(1)
    print(f"Array Job ID: {batch_jobid}")

    # submit htseq-count and multiqc job to run after array job finishes
    print(f"sbatch --dependency=afterok:{batch_jobid} htseq_multiqc.slurm {SAMPLE_FILE} {star_gtf} {FASTP_DIR} {HTS_DIR} {STAR_DIR} {PICARD_DIR}")
    subprocess.run(f"sbatch --dependency=afterok:{batch_jobid} htseq_multiqc.slurm {SAMPLE_FILE} {star_gtf} {FASTP_DIR} {HTS_DIR} {STAR_DIR} {PICARD_DIR}", shell=True)


print("Done submitting. Now you must wait.")
