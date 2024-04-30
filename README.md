# nf-methTRAP

#### Trim, Repair, Align and Pileup modBam

<img align="right" src="img/methTRAP_logo.png" width="250px">

From modBAm to methylBed

This pipeline take modification basecalled ONT reads (modBam) as input, process the reads (including adapters & barcodes trimming, MM/ML tags repair), align trimmed repaired reads to assembly and then pileup to methylBed. 

Require inputs:

 * modBam 
 * reference genome for alignment 

# Work flow

1. mod basecall - `dorado basecaller` (not included in this pipeline)
2. sort modBam - `samtools sort`
3. convert modBam to fastq - `samtools fastq`
4. trim barcode and adapters - `porechop`
5. convert trimmed modfastq to modBam - `samtools import`
6. repair MM/ML tags of trimmed modBam - `modkit repair `
7. align to reference (plus sorting and indexing) - `dorado aligner` 
8. check statistics of alignment - `samtools flagstat`
9. create bedMethyl - `modkit pileup`
10. create tables consists of methylation frequencies with >= 5x coverage (for plotting in R) - `frac_bed`
11. create bedgraph from the massive bedMethyl tables as input (chrom, pos1, pos2,meth_perc, mod_cov, canonical_cov) to MethylScore - `bed2bedgraph`

# Usage

To run the pipeline with a samplesheet on biohpc_gen with charliecloud:

```

nextflow run nf-methTRAP --samplesheet 'path/to/sample_sheet.csv' \
                          --out './results' \
                          -profile biohpc_gen,charliecloud
```

> Note: Porechop, Modkit and Dorado containers are hosted at the LRZ gitlab registry. This requires authentication, currently not handled by nextflow. These containers need to be pre-pulled. Example: 


    ch-image pull --auth gitlab.lrz.de:5005/beckerlab/container-playground/porechop_pigz:4ba2bef9

# Parameters

| Parameter | Effect |
| --- | --- |
| `--samplesheet` | Path to samplesheet |
| `--out` | Results directory, default: `'./results'` |

# Samplesheet

Samplesheet `.csv` with header:

```
sample,modBam,ref
```

| Column | Content |
| --- | --- |
| `sample` | Name of the sample |
| `modBam` | Path to basecalled modBam file |
| `ref` | Path to assembly fasta file |


# Outputs

The outputs will be put into `params.out`, defaulting to `./results`. Inside the results folder, the outputs are structured into 4 main branches, `trim_repair`, `align`. `pileup` and `processed_bed` and in each sub directory, according to the different processors. 
All processess will emit their outputs to results.

```bash

├── trim_repair
│   │
│   ├── samtools
│   │   ├── sort_inputBAM
│   │   │   └── sorted_sample.bam
│   │   └── convert2fastq 
│   │       └── sample.fastq.gz
│   │ 
│   ├── porechop
│   │   ├── sample.log
│   │   ├── porechop_sample.fastq.gz
│   │   └── convert2bam
│   │       └── porechop_sample.bam
│   │ 
│   └── modkit_repair
│       ├── sample_repaired.bam
│       └── sample_repair.log
│
├── align
│   │
│   ├── dorado_aligner
│   │   └── sample
│   │       ├── alignment_summary.txt
│   │       ├── sample.bam
│   │       └── sample.bam.bai
│   │    
│   └── samtools_flagstat
│       └── sample.flagstat
│
├── pileup
│   │
│   ├── sample.bed
│   └── pileup.log
│
└── processed_bed
    │ 
    ├── bed2bedgraph
    │   ├── sample_CG_negative.bedgraph
    │   ├── sample_CG_positive.bedgraph
    │   ├── sample_CHG_negative.bedgraph
    │   ├── sample_CHG_positive.bedgraph
    │   ├── sample_CHH_negative.bedgraph
    │   └── sample_CHH_positive.bedgraph
    │
    └── methylation_freq
        └── sample.txt


```

## Output of `processed_bed`

### 1. bed2bedgraph

Convert bedMethyl tables to bedgraphs (compatible with mehtylScore), filter out positions with <5x coverage.

bedgraph format: 

| column | name |
| --- | --- |
| 1   | pos1
| 2   | pos2
| 3   | methylation percentage
| 5   | modified base coverage
| 6   | canonical base coverage

### 2. frac_bed

Convert bedMethyl tables to minimised tables which consist only of methylation frequencies, positions with <5x coverage are filtered out. 
This table is later used to plot methylation frequencies in R.

table format: 

| column | name |
| --- | --- |
| 1   | modification, context
| 2   | methylation percentage 


# Dependencies 

Required version of `nextflow` - v23.10.1 and `charliecloud` - v0.35

currenty (April 2024) still have to pull containers prior to launching the pipeline, below is an example how to do this 

```bash
export CH_IMAGE_STORAGE=/path/to/work/charliecloud
ch-image pull --auth gitlab.lrz.de:5005/beckerlab/container-playground/modkit:923af692
unset CH_IMAGE_STORAGE 
```

Current version of `dorado` - v0.6.1

Current version of `modkit` - v0.2.6

