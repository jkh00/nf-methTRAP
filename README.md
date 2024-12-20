# nf-methTRAP

This pipeline is primarily developed to extract methylation data from ONT reads. Recently we added support to process PacBio data too. 

### Trim, Repair, Align and Pileup modBam

<img align="right" src="img/methTRAP_logo.png" width="250px">

From modBAM to methylBed


This pipeline takes modification basecalled ONT reads or PacBio HiFi reads predicted with 5mC (modBam) as input, align to assembly provided and then  extract methylation calls into .bed format. 


Require inputs:

 * ONT/ PacBio modBAM
 * reference genome for alignment 

# Work flow

## ONT workflow: 

1. trim and repair tags of input modBam (optional)

    - trim and repair workflow:
        1. sort modBam - `samtools sort`
        2. convert modBam to fastq - `samtools fastq`
        3. trim barcode and adapters - `porechop`
        4. convert trimmed modfastq to modBam - `samtools import`
        5. repair MM/ML tags of trimmed modBam - `modkit repair`

2. align to reference (plus sorting and indexing) - `dorado aligner` 
    - include alignment summary - `samtools flagstat`

3. create bedMethyl - `modkit pileup`
4. create bedgraphs (optional)


## PacBio workflow: 

1. align to reference - `minimap2` or `pbmm2` (default)

    - minimap workflow: 
        1. convert modBam to fastq - `samtools convert`
        2. alignment - `minimap2`
        3. sort and index - `samtools sort`
        4. alignment summary - `samtools flagstat`

    - pbmm2 workflow: 
        1. alignment and sorting - `pbmm2`
        2. index - `samtools index`
        3. alignment summary - `samtools flagstat`

2. create bedMethyl - `modkit pileup` (default) or `pb-CpG-tools` 
    - pileup with `modkit pileup` is default setting
    - 2 options for `pb-CpG-tools`:
        1. default using `count` (no need to give any parameters)
        2. or can set to using `model` (parameter settings check next section)


3. create bedgraph (optional)


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
| `--no_trim` | skip trim |
| `--aligner` | `minimap2`, default: pbmm2 |
| `--pileup_method` | `pbcpgtools`, default: modkit |
| `--model` | parse `--pileup-mode model` to pb-CpG-tools, default: `--pileup-mode count` |
| `--bedgraph` | convert bed to bedgraph, compatible to methylScore input |

# Samplesheet

Samplesheet `.csv` with header:

```
sample,modBam,ref,method
```

| Column | Content |
| --- | --- |
| `sample` | Name of the sample |
| `modBam` | Path to basecalled modBam file |
| `ref` | Path to assembly fasta file |
| `method` | specify ont / pacbio |


# Outputs

The outputs will be put into `params.out`, defaulting to `./results`.

```bash

├── ont
│   │
│   ├── trim
│   │   ├── trimmed.fastq.gz
│   │   ├── trimmed.bam
│   │   └── trimmed.log
│   │
│   ├── repair
│   │   ├── repaired.bam
│   │   └── repaired.log
│   │
│   ├── alignment
│   │   ├── aligned.bam
│   │   ├── aligned.bai
│   │   ├── summary.txt
│   │   └── aligned.flagstat
│   │
│   ├── pileup/modkit
│   │   ├── pileup.bed
│   │   └── pileup.log
│   │
│   └── bedgraph
│       └── bedgraphs
│ 
│  
└── pacbio   
    │
    ├── aligned_minimap2/ aligned_pbmm2
    │   ├── aligned.bam
    │   ├── aligned.bai/csi
    │   └── aligned.flagstat
    │
    ├── pileup: modkit/pb_cpg_tools
    │   ├── pileup.bed
    │   ├── pileup.log
    │   └── pileup.bw (only pb_cpg_tools)
    │
    └── bedgraph
        └── bedgraphs

```

## Output of `bedgraph`

### 1. bed2bedgraph

Convert bedMethyl tables to bedgraphs (compatible with mehtylScore), filter out positions with <5x coverage.

bedgraph format: 

| column | name |
| --- | --- |
| 1   | chrom
| 2   | pos1
| 3   | pos2
| 4   | methylation percentage
| 5   | modified base coverage
| 6   | canonical base coverage


# Changes to be made 

1. default pacbio pileup tool -> pbcpgtool (model)
2. document which parameters & versions used for some tools 
    - minimap 
    - pileup settings (modkit & pbcpgtools)



# Dependencies 

Required version of `nextflow` - v23.10.1 and `charliecloud` - v0.35

currenty (April 2024) still have to pull containers prior to launching the pipeline, below is an example how to do this 

```bash
export CH_IMAGE_STORAGE=/path/to/work/charliecloud
ch-image pull --auth gitlab.lrz.de:5005/beckerlab/container-playground/modkit:923af692
unset CH_IMAGE_STORAGE 
```

Update (Oct 2024) 

nextflow version: nextflow/24.09.0-edge-gcc12

charliecloud version: charliecloud/0.37

> only containers build in our playground need to be pulled prior to launching the pipeline

Current version of `dorado` - v0.7.3

Current version of `modkit` - v0.3.2



Gone: 

2. frac_bed

Convert bedMethyl tables to minimised tables which consist only of methylation frequencies, positions with <5x coverage are filtered out. 
This table is later used to plot methylation frequencies in R.

table format: 

| column | name |
| --- | --- |
| 1   | modification, context type
| 2   | methylation percentage 


test run with small dataset

try all the combinations: 
pacbio = 12n; ont = 4n 

default: 


| pacbio | parameters combinaition | test | 
| --- | --- | --- |
|  pbmm2 + modkit  | null |completed
|  pbmm2 + modkit + bedgraph  |  --bedgraph | completed
|  pbmm2 + pbcpg (count)  | --pileup_method pbcpgtools | completed
|  pbmm2 + pbcpg (count) + bedgraph | --pileup_method pbcpgtools --bedgraph|  completed
|  pbmm2 + pbcpg (model)  |  --pileup_method pbcpgtools --model | completed
|  pbmm2 + pbcpg (model) + bedgraph | --pileup_method pbcpgtools --bedgraph --model | completed
|  minimap2 + modkit | --aligner minimap2 | completed
|  minimap2 + modkit + bedgraph  | --aligner minimap2 --bedgraph | completed
|  minimap2 + pbcpg (count)  | --aligner minimap2 --pileup_method pbcpgtools |completed
|  minimap2 + pbcpg (count) + bedgraph | --aligner minimap2 --pileup_method pbcpgtools --bedgraph | completed 
|  minimap2 + pbcpg (model)  | --aligner minimap2 --pileup_method pbcpgtools --model | completed
|  minimap2 + pbcpg (model) + bedgraph | --aligner minimap2 --pileup_method pbcpgtools --model --bedgraph | completed
| all options (pbmm2 + modkit + bedgraph & pbmm2 + pbcpg (count) + bedgraph & minimap2 + modkit + bedgraph & minimap2 + pbcpg (count) + bedgraph) | --pb_all | completed




| ont | parameters combinaition| test |
| --- | --- | --- |
|  trim + align   | null | completed
|  trim + align + bedgraph | --bedgraph | completed 
|  align + bedgraph  |  --no_trim --bedgraph | completed
|  align | --no_trim | completed


### Updates 

31.10.24

update `modkit pileup` 
- use `--combine-mod` command, which combined cytosine mods (mC and hmC) counts as one 
    - reasoning behind this is cuz for current analyses we are not interested in hmC, so will just buckled them all in one 