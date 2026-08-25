# Run Alignment QC using QualiMap

Run the BAMQC module of QualiMap for each sample:

```
for sample in $(cat data/bamlists/full_herr.sample_list.txt); do
    sbatch \
        --job-name=${sample}.qualimap \
        --output=logs/QualiMap/${sample}.bamqc.out \
        --error=logs/QualiMap/${sample}.bamqc.err \
        src/QualiMap/run_bamqc_sample.sh ${sample}
done
```

To run the MULTI BAM QC module I prepare the input file:

```
paste \
    <(ls data/qualimap/ | grep -v "multiqc") \
    <(ls -d data/qualimap/* | grep -v "multiqc") \
    <(grep -f data/bamlists/full_herr.sample_list.txt data/samples_table.csv | cut -d',' -f 12) \
> data/qualimap/multiqc_config.txt
```

The I can run in an interactive window:

```
ml PDC/26.03 qualimap

qualimap multi-bamqc \
    -d data/qualimap/multiqc_config.txt \
    -outdir data/qualimap/multiqc
```