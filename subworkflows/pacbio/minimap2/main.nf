/*
 ===========================================
 * Import processes from modules
 ===========================================
 */


include { SAMTOOLS_FASTQ } from '../../../modules/samtools/fastq/main'
include { SAMTOOLS_FLAGSTAT } from '../../../modules/samtools/flagstat/main'
include { MINIMAP2 } from '../../../modules/minimap2/main'

/*
 ===========================================
 * Workflows
 ===========================================
 */


// for PacBio 

workflow MAP_MINI {
  
  take: 
    input

  main:

    input
      .map(row -> [row.sample, row.ref])
      .set{ refs }

    input
      .map(row -> [row.sample, row.method])
      .set{ method }

    input
      .map(row -> [row.sample, row.modBam])
      .set { reads_in }

    SAMTOOLS_FASTQ(reads_in)
    minimap_in = SAMTOOLS_FASTQ.out.fastq.join(refs)
    MINIMAP2(minimap_in)
    MINIMAP2.out.bam
                .join(method)
                .map { it + ["aligned_minimap2"] }
                .set { flagstat_in }

    SAMTOOLS_FLAGSTAT(flagstat_in)                              
    MINIMAP2.out.bam
                  .join(MINIMAP2.out.index)
                  .join(refs)
                  .join(method)
                  .set { mini_out }

  emit:
    mini_out
    method
} 

