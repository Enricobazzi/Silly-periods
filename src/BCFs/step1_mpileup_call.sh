#!/bin/bash -l
#SBATCH -A naiss2025-5-565
#SBATCH -p shared
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=10
#SBATCH -t 1-00:00:00
#SBATCH --mem=24G

module load bcftools

REF=Reference/GCF_900700415.2_Ch_v2.0.2_genomic.fna
THR=10
BAMS=data/bams
BCFS=data/bcfs

sample=${1}

if [[ -f ${BAMS}/${sample}.merged.rmdup.merged.realn.rescaled.bam ]]; then
  input_bam=${BAMS}/${sample}.merged.rmdup.merged.realn.rescaled.bam
elif [[ -f ${BAMS}/${sample}.merged.rmdup.merged.realn.bam ]]; then
  input_bam=${BAMS}/${sample}.merged.rmdup.merged.realn.bam
else
  echo "BAM file for sample ${sample} not found!"
  exit 1
fi

output_bcf=${BCFS}/${sample}.step1.bcf

bcftools mpileup --threads ${THR} -Ou -Q 30 -q 30 -B -f ${REF} ${input_bam} | \
    bcftools call --threads ${THR} -c -M -Ob  -o ${output_bcf}
bcftools index -o ${output_bcf}.csi ${output_bcf}
bcftools stats ${output_bcf} > ${output_bcf}.stats
