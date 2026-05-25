#!/bin/bash -l
#SBATCH -A naiss2025-5-565
#SBATCH -p shared
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=8
#SBATCH -t 0-12:00:00
#SBATCH --mem=128G

## load software
ml angsd

## constants
BAMLIST=data/bamlists
OUTDIR=data/gtlike

## arguments
dataset=${1}
chr=${2}

angsd -GL 2 -nThreads 8 -doGlf 2 -doMajorMinor 1 -doMaf 2 -SNP_pval 1e-6 \
    -minMapQ 30 -minQ 30 -remove_bads 1 -only_proper_pairs 1 -uniqueOnly 1 -skipTriallelic 1 \
    -r ${chr} \
    -bam ${BAMLIST}/${dataset}.bamlist \
    -out ${OUTDIR}/${dataset}.${chr}
