# Run PCAngsd to get covariance Matrix

To obtain a covariance matrix of herring individuals I ran [PCAngsd](https://www.popgen.dk/software/index.php/PCAngsd).

## Generate site masking files 

Multiple covariance matrices were obtained by using different sets of SNPs appropriate for different aspects of population structure and ecotype differentiation:
- `supplementary_file_7.v2`: the 794 SNPs under selection that differentiate herring populations (see [Han et al. (2020)](https://elifesciences.org/articles/61076))
- `ns_inversions.chr6`, `ns_inversions.chr12`, `ns_inversions.chr17`, `ns_inversions.chr23`: the 4 inversions associated with North-South population distinctions (see [Jamsandekar et al. 2024](https://www.nature.com/articles/s41467-024-53079-7))
- `spring_v_autumn.v2`: 1005 SNPs that best differentiate Spring from Autumn spawning herring (see [Han et al. (2020)](https://elifesciences.org/articles/61076))
- `baltic_v_atlantic.v2`: 2292 SNPs that best differentiate Baltic from Atlantic herring (see [Han et al. (2020)](https://elifesciences.org/articles/61076))

To choose which genomic positions to include in the PCAngsd analysis, I use the `--filter-sites` flag. This requires a file with one row for each SNP with 0 if it's to be excluded and a 1 if it's included.

I obtain this file for the dataset by intersecting (with [`bedtools intersect -c`](https://bedtools.readthedocs.io/en/latest/content/tools/intersect.html#c-reporting-the-number-of-overlapping-features)) a BED file of the positions included in the ANGSD generated MAF file (see [2a-GenotypeLikelihoods.md](2a-GenotypeLikelihoods.md)) with a BED of the sites to include :

```
ml bedtools

dataset=wp1_final_bal
sites=supplementary_file_7.v2

# transform MAF to BED
zcat data/gtlike/${dataset}.mafs.gz | cut -f1,2 | tail -n +2 | awk '{print $1, $2 - 1, $2}' | tr ' ' '\t' \
    > data/sites/${dataset}.bed

# use intersect to get mask
bedtools intersect -c \
    -a data/sites/${dataset}.bed \
    -b data/sites/${sites}.bed \
    | cut -f4 > data/sites/${dataset}.${sites}.sitemask
```

## Run PCAngsd

To run PCAngsd on the genotype likelihoods of particular sites of a particular dataset I run [run_pcangsd.sh](src/PCAngsd/run_pcangsd.sh) with `dataset` and `sites` name as arguments:

```
dataset=wp1_final_bal
sites=supplementary_file_7.v2

sbatch \
    --job-name=${dataset}.${sites}.pcangsd \
    --output=logs/angsd_matrix/pcangsd.${dataset}.${sites}.out \
    --error=logs/angsd_matrix/pcangsd.${dataset}.${sites}.err \
    src/angsd_matrix/pcangsd_sbatch.sh ${dataset} ${sites}
```

This will calculate a covariance matrix and store it in the file `data/pcangsd/${dataset}.${sites}.pcangsd.cov`, which I can analyze in R.
