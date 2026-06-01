# Analyze Genetic Diversity

I calculated individual level heterozygosity from the BAM files directly using an [angsd-based pipeline](https://www.popgen.dk/angsd/index.php/Heterozygosity)

## Step 1. filter out repeats and inversions from BAM files

To generate a BED file of the whole genome except inversions and repeats:

```
ml bedtools

awk '{print $1, 0, $2}' Reference/GCF_900700415.2_Ch_v2.0.2_genomic.fna.fai | tr ' ' '\t' \
    > Reference/GCF_900700415.2_Ch_v2.0.2_genomic.whole_genome.bed

bedtools merge -i <(cat Reference/GCF_900700415.2_Ch_v2.0.2_genomic.repeats.sorted.bed \
    data/sites/ns_inversions.*.bed | \
    sort -k1,1 -k2,2n -k3,3n) \
    > Reference/GCF_900700415.2_Ch_v2.0.2_genomic.repeats.inversions.sorted.bed

bedtools subtract \
    -a Reference/GCF_900700415.2_Ch_v2.0.2_genomic.whole_genome.bed \
    -b Reference/GCF_900700415.2_Ch_v2.0.2_genomic.repeats.inversions.sorted.bed \
    > Reference/GCF_900700415.2_Ch_v2.0.2_genomic.noreps_noinvs.bed
```

To remove inversions and repeats from the BAM file I used the [bam_filter_reps_invs.sh](src/Diversity/bam_filter_reps_invs.sh):

```
dataset=wp1_final_bal
for sample in $(cat data/bamlists/${dataset}.sample_list.txt); do
    echo "${sample}"
    sbatch \
        --job-name=${sample}.norepnoinv \
        --output=logs/diversity/norepnoinv.${sample}.out \
        --error=logs/diversity/norepnoinv.${sample}.err \
        src/diversity/bam_filter_reps_invs.sh ${sample}
done
```

## Step 2. run ANGSD to calculate individual SFS

To calculate individual level heterozygosity as in [Funk et al. (2025)](https://academic.oup.com/jhered/advance-article-abstract/doi/10.1093/jhered/esaf092/8313325), following [the provided script](https://github.com/erikrfunk/PPM_env-correlates), we run `angsd -doSAF` and then `realSFS` for each individual:

```
dataset=wp1_final_bal
for sample in $(cat data/bamlists/${dataset}.sample_list.txt); do
    echo "${sample}"
    sbatch \
        --job-name=${sample}.indhet \
        --output=logs/diversity/indhet.${sample}.out \
        --error=logs/diversity/indhet.${sample}.err \
        src/Diversity/angsd_saf_het.sh ${sample}
done
```

```
dataset=wp1_final_bal
for sample in $(cat data/bamlists/${dataset}.sample_list.txt); do
    echo "${sample}"
    awk '{for(i=1;i<=NF;i++){n++; if(n==2) second=$i; sum+=$i}} END{print second/sum}' data/diversity/output/${sample}.het_notrans.ml
done
```