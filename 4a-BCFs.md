# Generating and filtering BCF files


## Step 1. Variant calling

I used bcftools `mpileup` and `call` to generate variant files from bam files of each individual.

The individuals I used are from the `wp1_final_bal` dataset (as in [2a-GenotypeLikelihoods.md](2a-GenotypeLikelihoods.md), see  [0-Dataset](0-Dataset.md) for more details)

I ran the [step1_mpileup_call.sh](src/BCFs/step1_mpileup_call.sh) for each individual in the dataset:

```
dataset=wp1_final_bal
for sample in $(cat data/bamlists/${dataset}.sample_list.txt); do
    echo ${sample}
    sbatch \
        --job-name=${sample}.step1 \
        --output=logs/bcfs/step1.${sample}.out \
        --error=logs/bcfs/step1.${sample}.err \
        src/BCFs/step1_mpileup_call.sh ${sample}
done
```