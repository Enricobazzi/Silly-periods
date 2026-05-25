# Genotype Likelihoods with ANGSD

I used [ANGSD](https://www.popgen.dk/angsd/index.php/ANGSD) to obtain genotype likelihoods from the BAM files of herring individuals.

## Selecting individuals

The following datasets have been created to include samples for different objectives:
- `wp1_final_bal` (n=287) includes all atlantic herring samples for WP1 on Sillperiods (see [0-Dataset](0-Dataset.md))

These are stored in the `data/bamlists/` folder where `${dataset}.sample_list.txt` has the list of individual names and `${dataset}.bamlist` has the list of bam files. They can be written from the [samples table](data/samples_table.csv) with the following code:

```
dataset=wp1_final_bal
grep "yes" data/samples_table.csv | cut -d',' -f1 > data/bamlists/${dataset}.sample_list.txt
```

```
dataset=wp1_final_bal
for sample in $(cat data/bamlists/${dataset}.sample_list.txt); do
    if [[ -f data/bams/${sample}.subsampled_3X.bam ]]; then
      input_bam=data/bams/${sample}.subsampled_3X.bam
    else
      echo "error: bam file of ${sample} not found!"
    fi
    echo ${input_bam}
done > data/bamlists/${dataset}.bamlist
```

*NOTE: The `${dataset}` scheme might not be really useful in this case where I will only focus on using one `${dataset}`. Still, the code is best kept flexible always including the `${dataset}` part if future implementations need different subsets of individuals*

## Run ANGSD

Using the `dataset` name, I run the [calculate_gtlike_angsd.sh](src/GenotypeLikelihoods/calculate_gtlike_angsd.sh) script to calculate genotype likelihoods of all the individuals in the dataset, which will be stored in `data/gtlike/${dataset}.beagle.gz`. This will include only biallelic SNPs with a minimum p-value of 1E-6, mapping quality above 30, base quality above 20, ignoring failed, duplicate, improperly paired and multi-hit reads, storing their position and allele frequencies in the `data/gtlike/${dataset}.mafs.gz` file.

```
dataset=wp1_final_bal

sbatch \
    --job-name=${dataset}.gtlike \
    --output=logs/GenotypeLikelihoods/gtlike.${dataset}.out \
    --error=logs/GenotypeLikelihoods/gtlike.${dataset}.err \
    src/GenotypeLikelihoods/calculate_gtlike_angsd.sh ${dataset}

# or by chromosome
chrs=($(grep NC_04 Reference/GCF_900700415.2_Ch_v2.0.2_genomic.fna.fai | cut -f1 | grep -v "NC_045174"))

for chr in $(grep NC_04 Reference/GCF_900700415.2_Ch_v2.0.2_genomic.fna.fai | cut -f1); do
    sbatch \
        --job-name=${chr}.${dataset}.gtlike \
        --output=logs/GenotypeLikelihoods/gtlike.${dataset}.${chr}.out \
        --error=logs/GenotypeLikelihoods/gtlike.${dataset}.${chr}.err \
        -p main --mem=512G \
        src/GenotypeLikelihoods/calculate_gtlike_angsd_bychr.sh ${dataset} ${chr}
done

# concatenate chromosome beagles
zcat data/gtlike/${dataset}.${chrs[0]}.beagle.gz > data/gtlike/${dataset}.beagle
for chr in ${chrs[@]:1}; do
    echo "${chr}"
    zcat data/gtlike/${dataset}.${chr}.beagle.gz | tail -n +2 >> data/gtlike/${dataset}.beagle
done
gzip data/gtlike/${dataset}.beagle
```