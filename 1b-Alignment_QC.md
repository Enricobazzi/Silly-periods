# Alignment QC

## Depth Calculation

After obtaining bam files run the [depth_from_bam.sh](src/Alignment_QC/depth_from_bam.sh) to extract alignment depth from the bam:
```
for bam in $(ls data/bams/*.bam); do
  sbatch src/Alignment_QC/depth_from_bam.sh ${bam}
done
```

## Plotting depth

With this code we I obtain each sample's mean
```
grep "#" data/bams/*.depth | \
    rev | cut -d'/' -f1 | rev | sed 's/.depth:# mean=/ /' | cut -d' ' -f1,2
```

After adding depth values obtained to the wg_depth column of [samples_table.csv](data/samples_table.csv), I plot the mean depth of each sample in a list:
```
# for ND samples:
python src/mapping/plot_depth.py \
    --sfile <(grep "ND" data/samples_table.csv | cut -d',' -f1) \
    --ofile plots/mapping/mean_depth_ND_samples.png
```