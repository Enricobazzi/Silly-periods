# Read Quality Control and Mapping 

I mainly used the [GenErode](https://github.com/NBISweden/GenErode) pipeline ([Kutschera et al. 2022](https://doi.org/10.1186/s12859-022-04757-0)) to perform read quality control, trimming and alignment to a reference genome.

## Reference Genome choice

We align our sequences to [GCF_900700415.2](https://www.ncbi.nlm.nih.gov/datasets/genome/GCF_900700415.2/) which is a chromosome level assembly and version 2 of the Herring reference genome.

We choose this assembly over [version 3](https://www.ncbi.nlm.nih.gov/datasets/genome/GCA_040183275.2/) because it has annotation for the genes and will allow easier use of previously identified loci (e.g., adaptive SNPs, inversions), while also maintaining high contiguity (all 26 chromosomes represented).

## Notes on Generode runs

### Installation

To install the pipeline I clone the github folder:
```
git clone https://github.com/NBISweden/GenErode.git
```
and create a conda environment (called `generode`) using the environment.yml file in the folder:
```
conda env create -n generode -f environment.yml
```

### Configuration files

To run the pipeline two main configuration files need to be modified in the GenErode folder:
- `GenErode/slurm/config.yaml` manages SLURM stuff (e.g. computation project, memory/cpu specifications)
- `GenErode/config/config.yaml` manages what steps of the pipeline will be run

Both of these were copied and modified from the [template slurm file](https://github.com/NBISweden/GenErode/blob/main/config/slurm/profile/config_plugin_dardel.yaml) and the [template config file](https://github.com/NBISweden/GenErode/blob/main/config/config.yaml) available from the GenErode github folder.

I have replicated these here locally to easily modify them, but they should be located in the GenErode folder where the analysis is run on the cluster (usually in Scratch).

### Samples MetaData files

To run alignments on a group of samples I need to create metadata files for both historical and modern samples separately (since they follow distinct pipelines). These are located in `config/historical_samples_paths.txt` and `config/modern_samples_paths.txt`.

Description on how to fill the information in these can be found at:
https://github.com/NBISweden/GenErode/wiki/2.-Requirements-&-pipeline-configuration#1-prepare-metadata-files-of-samples

#### For public data

The metadata file entries for public data was prepared manually.

#### For newly generated sequences

To prepare metadata files for the newly generated sequences I use the [print_metadata_from_folder.py](src/GenErode/print_metadata_from_folder.py) script:

```
# header first
echo "samplename_index_lane readgroup_id readgroup_platform path_to_R1_fastq_file path_to_R2_fastq_file" \
    > historical_samples_paths.txt

# you need pandas - my base env on dardel has it installed
conda activate
pmff=/cfs/klemming/home/e/ebazzica/scripts/print_metadata_from_folder.py

python ${pmff} --idir /cfs/klemming/projects/supr/naiss2024-6-170/raw_data/Herring_DeepSeq_1/P21365 \
    >> historical_samples_paths.txt

python ${pmff} --idir /cfs/klemming/projects/supr/naiss2024-6-170/raw_data/Herring_DeepSeq_2/files/P36109 \
    >> historical_samples_paths.txt

python ${pmff} --idir /cfs/klemming/projects/supr/naiss2024-6-170/raw_data/Herring_DeepSeq_3/files/P37012 \
    >> historical_samples_paths.txt
```

### Run alignments

To align raw reads to the reference genome and make standard filtering of BAM files I set:
```
bam_rmdup_realign_indels: True
```
in the `config/config.yaml` file.

Check the [Snakemake file](https://github.com/NBISweden/GenErode/blob/main/Snakefile) to see which steps will be included.

By default `bam_rmdup_realign_indels: True` will include the following steps of the pipeline automatically if not run already:
```
workflow/rules/0.1_reference_genome_preps.smk
workflow/rules/0.2_repeat_identification.smk
workflow/rules/1.1_fastq_processing.smk
workflow/rules/2_mapping.smk
workflow/rules/3.1_bam_rmdup_realign_indels.smk
```

### Run the pipeline

Once all files are ready (regardless of what steps I want to run) I run the pipeline like this:
```
# create a screen for the run:
screen -S <run>

# in the screen prepare the environment:
module load PDC bioinfo-tools apptainer tmux
conda activate generode

# dry run + main run:
snakemake --profile slurm -n &> <YYMMDD>_dry.out
snakemake --profile slurm &> <YYMMDD>_main.out
```
