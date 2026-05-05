# Dataset

## Information regarding samples used

Here I can track information regarding the samples included in the project.

## Public data

In order to download and unpack some of the fastq files I've created a conda environment where I installed the [SRA tools](https://github.com/ncbi/sra-tools) software:  
```
conda create --name sra-tools
conda activate sra-tools
conda install -c bioconda sra-tools
```

Then I can use `fastq-dump` to extract the reads from a SRR file like this:  
```
prefetch -X 104857600 <SRR_code> # 104857600 is 100GB for maximum file size
fastq-dump --split-3 <SRR_code> --outdir <output_directory>
```

The published herring data from:  
- [Han et al. 2020](https://elifesciences.org/articles/61076): 108 individuals
- [Atmore et al. 2022](https://www.pnas.org/doi/10.1073/pnas.2208703119): 92 individuals
- [Atmore et al. 2024](https://onlinelibrary.wiley.com/doi/10.1111/gcb.70010): 33 individuals
- [Lamichhaney et al. 2017](https://doi.org/10.1073/pnas.1617728114): 27 individuals
- [Martinez-Barrio et al. 2016](https://doi.org/10.7554/eLife.12081): 8 individuals
- [Fuentes-Pardo et al. 2024](https://onlinelibrary.wiley.com/doi/10.1111/eva.13675): 34 individuals
- [Kongsstovu et al. 2022](https://doi.org/10.1016/j.fishres.2022.106231): 103 individuals

was downloaded by me and Nic from either the SRA ftp server or using sra-tools. The metadata for their respective projects can be found in the tables of the publications and at:

- Han et al. 2020: [PRJNA642736](https://www.ncbi.nlm.nih.gov/Traces/study/?acc=PRJNA642736&o=acc_s%3Aa)
- Atmore et al. 2022 [PRJEB52723](https://www.ncbi.nlm.nih.gov/Traces/study/?page=2&acc=PRJEB52723&o=acc_s%3Aa)
- Atmore et al. 2024 [PRJEB77597](https://www.ncbi.nlm.nih.gov/Traces/study/?page=2&acc=PRJEB77597&o=acc_s%3Aa)
- Lamichhaney et al. 2017 [PRJNA338612](https://www.ncbi.nlm.nih.gov/Traces/study/?acc=PRJNA338612&o=acc_s%3Aa)
- Martinez et al. 2016 [SRP056617](https://trace.ncbi.nlm.nih.gov/Traces/study/?acc=SRP056617&o=acc_s%3Aa), [SRP017094](https://trace.ncbi.nlm.nih.gov/Traces/study/?acc=SRP017094&o=acc_s%3Aa), [SRP017095](https://trace.ncbi.nlm.nih.gov/Traces/study/?acc=SRP017095&o=acc_s%3Aa)
- Fuentes-Pardo et al. 2024 [PRJNA930418](https://www.ncbi.nlm.nih.gov/Traces/study/?acc=PRJNA930418&o=acc_s%3Aa)
- Kongsstovu et al. 2022 [PRJEB25669](https://www.ncbi.nlm.nih.gov/Traces/study/?acc=PRJEB25669&o=acc_s%3Aa)

As SRR accession codes for each sample in each published study have been saved in files called `SRR_Acc_List.txt` within each folder, I can download and unpack them:
```
cd </path/to/study/folder/>

conda activate sra-tools
for acc in $(cat SRR_Acc_List.txt); do 
    echo $acc
    prefetch -X 104857600 $acc
    fastq-dump --split-3 $acc
    gzip ${acc}_1.fastq
    gzip ${acc}_2.fastq
done
```

## Newly Generated Sequences

We have generated new whole-genome sequences of herring individuals through [SciLife Lab](https://ngisweden.scilifelab.se/) projects:  
- [P21365](data/Dataset/P21365/L.Dalen_21_14_sample_info.txt)
- [P35202](data/Dataset/P35202/N.Dussex_25_01_sample_info.txt)
- [P36109](data/Dataset/P36109/N.Dussex_25_03_sample_info.txt)
- [P37012](data/Dataset/P37012/N.Dussex_25_06_sample_info.txt)

## Sample Table and Additional info

In the [samples_table.csv](data/samples_table.csv) I store metadata regarding the sequences:  
- sample_id: original sample name from publication or lab
- species: *Clupea harengus* or *pallasi*
- region: ...
- location: more specific location
- spawn: spawning season if known
- year: of sampling or dating of remains/site
- x, y: geographical coordinates
- study: when was this sequenced
- wg.depth: sequencing depth
- new.id: new name based on location
- time: modern, historical or sillperioder
- included: yes or no
- cluster: genetic cluster from dapc (maybe add?)

From the downloaded public data and the newly generated sequences we excluded (*included = no*):  
- any *Clupea pallasi*
- herring from the NW-Atlantic
- Lamichhaney et al. (2017) samples, because they have very low depth but metadata says it should be relatively high (not sure what is uploaded)
- Martinez-Barrio et al. (2016) samples, because there are 8 samples but metadata says there are 16, and these 8 don't cluster with the rest of herring (not sure what is uploaded)
- published historical genomes with depth < 0.1
- newly generated and published historical sequences from the Baltic (saving for later paper)

Summary of dataset for WP1 on Sill periods (*included = yes*):
- 287 herring sequences (192 modern, 126 historical)
- 61 Kattegat & Skagerrak herring:
    - 1 from 1500s: Nya Lodose (1)
    - 13 from 1747-1805 sillperiod: Masthugget (8) + Gullholmen (5)
    - 12 from 1874: Dynekilen (12)
    - 7 from 1877-1906 sillperiod: Koster (4) + Kalvsund (3)
    - 28 modern: Idefjord (13) + Maseskar (7) + Risor (8)
- 86 North Sea herring:
    - 9 from 800-1300: York (6) + Lyminge (3)
    - 2 from 1400: Netherlands (2)
    - 21 from 1872-1875: Stavanger (3) + Haugesund (2) + Foldfjorden (15) + Scotland (1)
    - 21 from 1877-1906 sillperiod: Stavanger (7) + Haugesund (3) + Røvær (1) + Scotland (6) + Unknown Norway (4)
    - 33 modern: North-Sea (20) + Celtic Sea (3) + Downs (3) + Isle of Man (3) + Karmoy (4) 
- 30 Baltic herring:
    - 30 modern: Blekinge (6) + Fehmarn (3) + Gavle (3) + Hastkar (8) + Kalix (6) + Kalmarsund (4)
- 101 North-East Atlantic herring:
    - 101 modern: Faroe (27) + Iceland (30) + Norwegian Sea (40) + More (4)
- 9 Other herring:
    - 9 from unknown year: unknown (4) + Bergen (5)

### Notes:

- Gullholmen (1750) and Masthugget (1740) years are approximations - they both belong to the 1747-1805 sillperiod
- Bergen samples have UNKNOWN year - will need to figure out if they are from sillperiod or not
- There are 4 unkown specimens (both time and location): ND168, ND169, ND170, ND171. They cluster with herring from Norway

