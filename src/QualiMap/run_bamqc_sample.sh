#!/bin/bash -l
#SBATCH -A naiss2025-5-565
#SBATCH -p shared
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=8
#SBATCH -t 0-00:30:00
#SBATCH --mem=64G

## load software
ml PDC/26.03 qualimap

## constants
OUT=data/qualimap

## arguments
sample=${1}

## variables
bam=data/bams/${sample}.subsampled_3X.bam

## run qualimap
qualimap bamqc -bam ${bam} -nt 8 \
    -outdir ${OUT}/${sample}
