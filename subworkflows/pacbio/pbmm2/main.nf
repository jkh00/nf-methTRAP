/*
 ===========================================
 * Import processes from modules
 ===========================================
 */



include { SAMTOOLS_FLAGSTAT } from '../../../modules/samtools/flagstat/main'
include { SAMTOOLS_INDEX } from '../../../modules/samtools/index/main'
include { PBMM2 } from '../../../modules/pbmm2/main'

/*
 ===========================================
 * Workflows
 ===========================================
 */


// for PacBio 

workflow MAP_PBMM2 {
  
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
      .map(row -> [row.sample, row.modBam, row.ref, row.method])
      .set { reads_in }


    PBMM2(reads_in)
    SAMTOOLS_INDEX(PBMM2.out.bam)
    SAMTOOLS_FLAGSTAT(PBMM2.out.bam
                                  .join(method)
                                  .map { it + ["aligned_pbmm2"] })
                                  
    PBMM2.out.bam
                    .join(SAMTOOLS_INDEX.out.bai)
                    .join(refs)
                    .join(method)
                    .set { output }
  
  emit:
    output
    method

 } 

