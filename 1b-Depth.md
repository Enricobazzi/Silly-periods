# Alignment Depth Calculation and Manipulation

Here I calculate average sequencing depth and subsample high depth individuals to same average depth to avoid major sequencing biases

## Depth Calculation

After obtaining bam files run the [depth_from_bam.sh](src/Depth/depth_from_bam.sh) to extract alignment depth from the bam:
```
for bam in $(ls data/bams/*.bam); do
  sbatch src/Depth/depth_from_bam.sh ${bam}
done
```

### Plotting depth

With this code we I obtain each sample's mean
```
grep "#" data/bams/*.depth | \
    rev | cut -d'/' -f1 | rev | sed 's/.depth:# mean=/ /' | cut -d' ' -f1,2
```

After adding depth values obtained to the wg_depth column of [samples_table.csv](data/samples_table.csv), I plot the mean depth of each sample in a list:
```
# for ND samples:
python src/Depth/plot_depth.py \
    --sfile <(grep "ND" data/samples_table.csv | cut -d',' -f1) \
    --ofile plots/Depth/mean_depth_ND_samples.png
```

## Subsample bams to 3X

Since there are very low depth samples in our dataset (~1X) I will try to avoid batch effects by subsampling all bams to the same target depth. Bams with lower than than target depth will be copied and given the same name as subsampled bams by the script

```
target_dp=3

for sample in $(ls data/bams/*.depth | rev | cut -d'/' -f1 | rev | cut -d'.' -f1); do
    
    # input bam
    if [[ -f data/bams/${sample}.merged.rmdup.merged.realn.rescaled.bam ]]; then
        inbam=data/bams/${sample}.merged.rmdup.merged.realn.rescaled.bam
    elif [[ -f data/bams/${sample}.merged.rmdup.merged.realn.bam ]]; then
        inbam=data/bams/${sample}.merged.rmdup.merged.realn.bam
    else
        echo "BAM file for sample ${sample} not found!"
        continue
    fi

    # output bam
    outbam=data/bams/${sample}.subsampled_${target_dp}X.bam
    
    # fraction of reads to keep
    sample_dp=$(grep "#" data/bams/${sample}.depth | cut -d'=' -f2 | cut -d' ' -f1)
    frac=$(awk -v s=${target_dp} -v d=${sample_dp} "BEGIN {{print s/d}}")
    
    sbatch \
        --job-name=${sample}.subsample \
        --output=logs/Depth/subsample.${sample}.out \
        --error=logs/Depth/subsample.${sample}.err \
        src/Depth/subsample_bam.sh \
        ${inbam} ${outbam} ${frac}
    
done
```
