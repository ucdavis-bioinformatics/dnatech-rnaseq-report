#!/usr/bin/env python3

# /share/illumina/hiseq/251222_DTSA1203_NovaX25B/Un_DTSA1203/Project_DLNK_Nova1437P_Krishnakumar/
# /quobyte/danikagrp/fastq/DNATechCore_241203/Data/ywsgtue2vu/Un_DTSA1014/Project_DBJV_NovaSeq1194P_Vo

import readline
import os
import re
import sys
import subprocess
from config import *

hm_data = {"human" : {"star_ref_dir" : STAR_REF_HUMAN_DIR,
                      "star_gtf" : STAR_GTF_HUMAN_FILE,
                      "rrna_file" : RRNA_HUMAN_FILE
            },

           "mouse" : {"star_ref_dir" : STAR_REF_MOUSE_DIR,
                      "star_gtf" : STAR_GTF_MOUSE_FILE,
                      "rrna_file" : RRNA_MOUSE_FILE
            }
} 


readline.set_completer_delims(' \t\n=')
readline.parse_and_bind("tab:complete")

tag_or_rna = input("RNA-Seq or TAG-Seq (rna/tag)? ")

inputdir = input("Path to fastq file directory: ")
input_files_R1 = [f for f in os.listdir(inputdir) if re.match(r'^(?!.*Undetermined).*R1.*.fastq.gz', f)]
input_files_R1.sort()

input_files_R2 = [f for f in os.listdir(inputdir) if re.match(r'^(?!.*Undetermined).*R2.*.fastq.gz', f)]
input_files_R2.sort()


print("Input files:\n", input_files_R1, "\n", input_files_R2, "\n")

sample_ids = [re.search(r'^(.+)_S\d+_L\d+_R\d_\d+.fastq.gz', s).group(1) for s in input_files_R1]
# get unique ids
sample_ids = list(set(sample_ids))
sample_ids.sort()

print("Sample IDs:\n", sample_ids, "\n")
sampidcheck = input("Are these sample IDs correct (y/n)? ")

if sampidcheck != "y" and sampidcheck != "Y":
    print("Exiting.")
    sys.exit(1)

outputdir = input("\nPath to output directory: ")


mhcheck = input("\nDo you want to use the mouse/human reference or not (mouse/human/n)? ")

star_ref_dir=""
star_gtf=""
star_fasta=""
if mhcheck=="mouse" or mhcheck=="human":
    star_ref_dir = hm_data[mhcheck]["star_ref_dir"]
    star_gtf = hm_data[mhcheck]["star_gtf"]
else:
    star_fasta = input("\nPath to reference fasta file: ")
    star_gtf = input("\nPath to annotation file (GTF format): ")


rrna_check = input("Find rRNA count (y/n)? ")
rrna_fasta=""
if (rrna_check == "y" or rrna_check == "Y"):
    if (mhcheck == "mouse" or mhcheck == "human"):
        rrna_fasta = hm_data[mhcheck]["rrna_file"]
    else:
        rrna_fasta = input("Path to rRNA FASTA file: ")


runcheck = input("\nRun (y/n)? ")
if runcheck != "y" and runcheck != "Y":
    print("Exiting.")
    sys.exit(1)


if not os.path.exists(outputdir):
    print("Creating output directory...")
    os.system(f"mkdir -p {outputdir}")
    os.system(f"mkdir -p {outputdir}/slurmout")

print("Copying slurm script...")
if tag_or_rna == "rna":
    if mhcheck=="mouse" or mhcheck=="human":
        os.system(f"cp rnaseq_pe_mouse_human.slurm {outputdir}")

print("Creating sample info file...")
if tag_or_rna == "rna":
    with open(f"{outputdir}/sample_data.txt", 'w') as file:
        for index, sampid in enumerate(sample_ids):
            file.write(f"{sampid}\t{inputdir}/{input_files_R1[index]}\t{inputdir}/{input_files_R2[index]}\n")

print("Submitting slurm array script for all samples...")
if tag_or_rna == "rna":
    if mhcheck=="mouse" or mhcheck=="human":
        print(f"cd {outputdir}; sbatch --array=1-{len(sample_ids)} {outputdir}/rnaseq_pe_mouse_human.slurm {outputdir}/sample_data.txt {outputdir} {star_ref_dir} {star_gtf} {rrna_check.lower()} {rrna_fasta}")
        #os.system(f"cd {outputdir}; sbatch --array=1-{len(sample_ids)} {outputdir}/rnaseq_pe_mouse_human.slurm {outputdir}/sample_data.txt {outputdir} {star_ref_dir} {star_gtf} {rrna_check} {rrna_fasta}")
        subprocess.run(f"cd {outputdir}; sbatch --array=1-{len(sample_ids)} {outputdir}/rnaseq_pe_mouse_human.slurm {outputdir}/sample_data.txt {outputdir} {star_ref_dir} {star_gtf} {rrna_check} {rrna_fasta}", shell=True)

print("Done submitting. Now you must wait.")
