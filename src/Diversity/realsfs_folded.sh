#!/bin/bash -l
#SBATCH -A naiss2025-5-565
#SBATCH -p main
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=8
#SBATCH -t 0-24:00:00
#SBATCH --mem=64G

# load software
ml angsd

# constants
THREADS=8
REF=Reference/GCF_900700415.2_Ch_v2.0.2_genomic.fna
OUT=data/diversity

# arg
dataset=${1}

# vars
saf=${OUT}/${dataset}.saf.idx

# run realsfs folded
realSFS ${saf} -fold 1 -P ${THREADS} > ${OUT}/${dataset}.sfs
