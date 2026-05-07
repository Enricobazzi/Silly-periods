#!/bin/bash -l
#SBATCH -A naiss2025-5-565
#SBATCH -p shared
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=1
#SBATCH -t 0-12:00:00
#SBATCH --mem=128G

ml pcangsd

dataset=${1}
sites=${2}

pcangsd \
    -b data/gtlike/${dataset}.beagle.gz \
    --iter 10000 \
    --filter-sites data/sites/${dataset}.${sites}.sitemask \
    -o data/pcangsd/${dataset}.${sites}.pcangsd
