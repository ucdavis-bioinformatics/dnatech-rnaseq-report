#!/usr/bin/env python3

# /share/illumina/hiseq/251222_DTSA1203_NovaX25B/Un_DTSA1203/Project_DLNK_Nova1437P_Krishnakumar/

import readline
import os
import re
import sys

readline.set_completer_delims(' \t\n=')
readline.parse_and_bind("tab:complete")
inputdir = input("Path to fastq file directory: ")
input_files = [f for f in os.listdir(inputdir) if re.match(r'^(?!.*Undetermined).*.fastq.gz', f)]
input_files.sort()

print("Input files:\n", input_files, "\n")

sample_ids = [re.search(r'^(.+)_S\d+_L\d+_R\d_\d+.fastq.gz', s).group(1) for s in input_files]
# get unique ids
sample_ids = list(set(sample_ids))
sample_ids.sort()

print("Sample IDs:\n", sample_ids, "\n")
sampidcheck = input("Are these sample IDs correct (y/n)? ")

if sampidcheck != "y" and sampidcheck != "Y":
    print("Exiting.")
    sys.exit(1)

outputdir = input("\nPath to output directory: ")
star_ref = input("\nPath to STAR reference directory: ")
star_gtf = input("\nPath to STAR annotation file (GTF format): ")

runcheck = input("\nRun (y/n)? ")
if runcheck != "y" and runcheck != "Y":
    print("Exiting.")
    sys.exit(1)


if not os.path.exists(outputdir):
    print("Creating output directory...")
    os.system(f"mkdir -p {outputdir}")

print("Copying slurm script...")
os.system(f"cp hts_star.slurm {outputdir}")

print("Creating sample info file...")

