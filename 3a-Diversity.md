# Analyze Genetic Diversity

Using the same code as in the [GenErode pipeline](https://github.com/NBISweden/GenErode/blob/main/workflow/rules/7_mlRho.smk), I calculated individual level heterozygosity from the BAM files directly using [mlRho](https://guanine.evolbio.mpg.de/mlRho/) ([Haubold et al., 2010](https://pmc.ncbi.nlm.nih.gov/articles/PMC4870015/)), a maximum likelihood estimator of population mutation rate (θ) from sequencing data of a single individual. Heterozygosity is approximated by θ under the infinite sites model and when the value of θ is small (see [here](https://reich.hms.harvard.edu/sites/reich.hms.harvard.edu/files/inline-files/2013_Nature_AltaiGenome_Supplement.pdf?utm_source=chatgpt.com)).

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

## Step 2. run mlRho to calculate individual heterozygosity

I run mlRho, to get an estimate of θ for each individual:

```
dataset=wp1_final_bal
for sample in $(cat data/bamlists/${dataset}.sample_list.txt); do
    echo "${sample}"
    sbatch \
        --job-name=${sample}.mlrho \
        --output=logs/diversity/${sample}.mlrho.out \
        --error=logs/diversity/${sample}.mlrho.err \
        src/Diversity/run_mlrho_from_bam.sh ${sample}
done
```

This will generate an mlrho file for each individual stored in data/mlrho/output/${sample}.mlrho.txt

## Step 3. calculate population level diversity (π, θw, Tajima's D)

I calculate population-level diversity metrics in [angsd](https://www.popgen.dk/angsd/index.php/Thetas,Tajima,Neutrality_tests), using the using the emperical Bayes (EB) method.

### 3.1 divide by population

I divide individuals in the following populations:

From the Skagerrak and Kattegat:
```
# Masthugget (1747–1805 Sillperiod)
grep "masthugget" data/samples_table.csv | cut -d',' -f1 \
    > data/bamlists/masthugget.sample_list.txt

# Gullholmen (1747–1805 Sillperiod)
grep "gullholmen" data/samples_table.csv | cut -d',' -f1 \
    > data/bamlists/gullholmen.sample_list.txt

# Dynekilen (Between Sillperiods)
grep "dynekilen" data/samples_table.csv | cut -d',' -f1 \
    > data/bamlists/dynekilen.sample_list.txt

# Koster, Kalvsund (1877–1906 Sillperiod)
grep -E "koster|kalvsund" data/samples_table.csv | cut -d',' -f1 \
    > data/bamlists/koster_kalvsund.sample_list.txt

# Risor (Present day)
grep "risor" data/samples_table.csv | cut -d',' -f1 \
    > data/bamlists/risor.sample_list.txt

# Måseskär (Present day)
grep "maseskar" data/samples_table.csv | cut -d',' -f1 \
    > data/bamlists/maseskar.sample_list.txt

# Idefjord (Present day)
grep "idefjord" data/samples_table.csv | cut -d',' -f1 \
    > data/bamlists/idefjord.sample_list.txt
```

From British and Irish waters:
```
# Lyminge (800)
grep "lyminge" data/samples_table.csv | awk -F',' '$9 == "current" || $10 >= 0.1' | cut -d',' -f1 \
    > data/bamlists/lyminge.sample_list.txt

# Scotland (1877–1906 Sillperiod)
grep "scotland" data/samples_table.csv | grep "sill" | cut -d',' -f1 \
    > data/bamlists/scotland_sp.sample_list.txt

# Celtic Sea, Downs, Isle of Man (Present day)
grep -E "celtic|downs|isleofman" data/samples_table.csv | cut -d',' -f1 \
    > data/bamlists/celtic_downs_isleofman.sample_list.txt
```

From Norwegian Sea:
```
# Bergen, Stavanger, Haugesund, Unknown (Between Sillperiods)
grep -E "bergen|stavanger|haugesund|norway|unknown" data/samples_table.csv | grep "18rh" | cut -d',' -f1 \
    > data/bamlists/bergen_stavenger_haugesund_unknown_bs.sample_list.txt

# Foldfjorden (Between Sillperiods)
grep "foldfjorden" data/samples_table.csv | cut -d',' -f1 \
    > data/bamlists/foldfjorden.sample_list.txt

# Stavanger, Haugesund, Norway (1877–1906 Sillperiod)
grep -E "stavanger|haugesund|norway" data/samples_table.csv | grep "18sp" | cut -d',' -f1 \
    > data/bamlists/stavenger_haugesund_norway_sp.sample_list.txt

# Norwegian Sea (Present day)
grep "norwegian" data/samples_table.csv | grep -i "kong" | cut -d',' -f1 \
    > data/bamlists/norwegian_mh.sample_list.txt
```

### 3.2 create bamlists

I make bamlists for angsd from those:
```
for dataset in bergen_stavenger_haugesund_unknown_bs celtic_downs_isleofman dynekilen foldfjorden gullholmen idefjord koster_kalvsund lyminge maseskar masthugget norwegian_mh risor scotland_sp stavenger_haugesund_norway_sp; do
    for sample in $(cat data/bamlists/${dataset}.sample_list.txt); do
        input_bam=data/bams/${sample}.subsampled_3X.noreps_noinvs.bam
        echo ${input_bam}
    done > data/bamlists/${dataset}.bamlist
done
```

### 3.3 estimate a site frequency spectrum

I get an SFS by running `angsd -doSaf 1` on each bamlist (using `-noTrans 1` because of ancient data):
`angsd -bam bam.filelist -doSaf 1 -anc chimpHg19.fa -GL 1 -P 24 -out out`

```
for dataset in bergen_stavenger_haugesund_unknown_bs celtic_downs_isleofman dynekilen foldfjorden gullholmen idefjord koster_kalvsund lyminge maseskar masthugget norwegian_mh risor scotland_sp stavenger_haugesund_norway_sp; do
    echo "${dataset}"
    sbatch \
        --job-name=${dataset}.dosaf \
        --output=logs/diversity/${dataset}.out \
        --error=logs/diversity/${dataset}.err \
        src/Diversity/angsd_dosaf.sh ${dataset}
done
```
