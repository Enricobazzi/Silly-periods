# Run PCAngsd to get covariance Matrix

To obtain a covariance matrix of herring individuals I ran [PCAngsd](https://www.popgen.dk/software/index.php/PCAngsd).

## Generate site masking files 

Multiple covariance matrices were obtained by using different sets of SNPs appropriate for different aspects of population structure and ecotype differentiation:

- `supplementary_file_7.v2`: the 794 SNPs under selection that differentiate herring populations (see [Han et al. (2020)](https://elifesciences.org/articles/61076))

- `ns_inversions.chr6`, `ns_inversions.chr12`, `ns_inversions.chr17`, `ns_inversions.chr23`: the 4 inversions associated with North-South population distinctions (see [Jamsandekar et al. 2024](https://www.nature.com/articles/s41467-024-53079-7))

- `sf7_noinv.v2`: to have a less link set of SNPs under selection we take: the SNPs from `supplementary_file_7.v2` not in any of the N-S inversions + one SNP from each of the four N-S inversions = 588 SNPs
```
ml bedtools

cat data/sites/ns_inversions.chr6.bed \
    data/sites/ns_inversions.chr12.bed \
    data/sites/ns_inversions.chr17.bed \
    data/sites/ns_inversions.chr23.bed | \
    sort -k 1,1 -k2,2n -k3,3n > data/sites/ns_inversions.all.bed

bedtools subtract -a data/sites/supplementary_file_7.v2.bed -b data/sites/ns_inversions.all.bed > tmp
bedtools intersect -a data/sites/supplementary_file_7.v2.bed -b data/sites/ns_inversions.chr6.bed | \
    awk '{line[NR]=$0} END {print line[int((NR+1)/2)]}' >> tmp
bedtools intersect -a data/sites/supplementary_file_7.v2.bed -b data/sites/ns_inversions.chr12.bed | \
    awk '{line[NR]=$0} END {print line[int((NR+1)/2)]}' >> tmp
bedtools intersect -a data/sites/supplementary_file_7.v2.bed -b data/sites/ns_inversions.chr17.bed | \
    awk '{line[NR]=$0} END {print line[int((NR+1)/2)]}' >> tmp
bedtools intersect -a data/sites/supplementary_file_7.v2.bed -b data/sites/ns_inversions.chr23.bed | \
    awk '{line[NR]=$0} END {print line[int((NR+1)/2)]}' >> tmp
sort -k 1,1 -k2,2n -k3,3n tmp > data/sites/sf7_noinv.v2.bed
rm tmp
```

- `spring_v_autumn.v2`: 1005 SNPs that best differentiate Spring from Autumn spawning herring (see [Han et al. (2020)](https://elifesciences.org/articles/61076))

- `baltic_v_atlantic.v2`: 2292 SNPs that best differentiate Baltic from Atlantic herring (see [Han et al. (2020)](https://elifesciences.org/articles/61076))

- `salinity_genes.v2`: 3682 SNPs in genes (LRRC8C2, FTG1, FTG2, FTG3, ZPBA1, HEC1C) related to adaptations to lower salinity in the Baltic sea (see [Ma et al. 2026](https://www.pnas.org/doi/10.1073/pnas.2601861123), *Supplementary Table 2*)
```
echo -e "NC_045153.1\t5167659\t5173312" > data/sites/salinity_genes.v2.bed # LRRC8C2
echo -e "NC_045168.1\t25337999\t25346141" >> data/sites/salinity_genes.v2.bed # FTG1
echo -e "NC_045168.1\t25359224\t25369735" >> data/sites/salinity_genes.v2.bed # FTG2
echo -e "NC_045168.1\t25388162\t25401039" >> data/sites/salinity_genes.v2.bed # FTG3
echo -e "NC_045174.1\t20871089\t20873646" >> data/sites/salinity_genes.v2.bed # ZPBA1
echo -e "NC_045177.1\t4974200\t4976139" >> data/sites/salinity_genes.v2.bed # HEC1C
echo -e "NC_045177.1\t4978487\t4980243" >> data/sites/salinity_genes.v2.bed # HEC1C
echo -e "NC_045177.1\t4982567\t4984386" >> data/sites/salinity_genes.v2.bed # HEC1C
```

To choose which genomic positions to include in the PCAngsd analysis, I use the `--filter-sites` flag. This requires a file with one row for each SNP with 0 if it's to be excluded and a 1 if it's included.

I obtain this file for the dataset by intersecting (with [`bedtools intersect -c`](https://bedtools.readthedocs.io/en/latest/content/tools/intersect.html#c-reporting-the-number-of-overlapping-features)) a BED file of the positions included in the ANGSD generated MAF file (see [2a-GenotypeLikelihoods.md](2a-GenotypeLikelihoods.md)) with a BED of the sites to include :

```
ml bedtools

dataset=wp1_final_bal

# transform MAF to BED
zcat data/gtlike/${dataset}.mafs.gz | cut -f1,2 | tail -n +2 | awk '{print $1, $2 - 1, $2}' | tr ' ' '\t' \
    > data/sites/${dataset}.bed

# use intersect to get mask
for sites in sf7_noinv.v2 salinity_genes.v2 spring_v_autumn.v2; do
    bedtools intersect -c \
        -a data/sites/${dataset}.bed \
        -b data/sites/${sites}.bed \
        | cut -f4 > data/sites/${dataset}.${sites}.sitemask
done
```

## Run PCAngsd

To run PCAngsd on the genotype likelihoods of particular sites of a particular dataset I run [run_pcangsd.sh](src/PCAngsd/run_pcangsd.sh) with `dataset` and `sites` name as arguments:

```
dataset=wp1_final_bal

for sites in sf7_noinv.v2 salinity_genes.v2 spring_v_autumn.v2; do
    sbatch \
        --job-name=${dataset}.${sites}.pcangsd \
        --output=logs/PCAngsd/pcangsd.${dataset}.${sites}.out \
        --error=logs/PCAngsd/pcangsd.${dataset}.${sites}.err \
        src/PCAngsd/run_pcangsd.sh ${dataset} ${sites}
done
```

This will calculate a covariance matrix and store it in the file `data/pcangsd/${dataset}.${sites}.pcangsd.cov`, which I can analyze in R.
