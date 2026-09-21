#!/bin/bash -l
#SBATCH -A naiss2025-5-565
#SBATCH -p shared
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=16
#SBATCH -t 0-24:00:00
#SBATCH --mem=64G

# load software
ml angsd

# constants
THREADS=16
REF=Reference/GCF_900700415.2_Ch_v2.0.2_genomic.fna
OUT=data/diversity

# arg
dataset=${1}

# vars
bamlist="data/bamlists/${dataset}.bamlist"
n_ind=$(grep -cve '^[[:space:]]*$' "$bamlist")
min_ind=$(( (n_ind + 1) / 2 ))
minD=$(( n_ind * 2 ))
maxD=$(( n_ind * 8 ))

# run angsd dosaf
angsd -bam ${bamlist} -doSaf 1 -anc ${REF} -GL 1 -P ${THREADS} \
    -out ${OUT}/${dataset} \
    -uniqueOnly 1 -remove_bads 1 -only_proper_pairs 1 -baq 1 -C 50 \
    -minMapQ 30 -minQ 30 -doCounts 1 -noTrans 1 \
    -minInd ${min_ind} -setMaxDepth ${maxD} -setMinDepth ${minD}
