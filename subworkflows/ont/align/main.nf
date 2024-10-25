/*
 ===========================================
 * Import processes from modules
 ===========================================
 */


include { DORADO_ALIGNER } from '../../../modules/dorado/aligner/main'
include { SAMTOOLS_FLAGSTAT } from '../../../modules/samtools/flagstat/main'

/*
 ===========================================
 * Workflows
 ===========================================
 */


workflow ALIGN {
  
  take: 
    dorado_in
    refs
    method

  main:

  DORADO_ALIGNER(dorado_in)
  bam_file = DORADO_ALIGNER.out.bam
  bai_file = DORADO_ALIGNER.out.bai
  
  bam_file
        .join(method)
        .map { it + ["alignment"] }
        .set { flagstat_in }

  SAMTOOLS_FLAGSTAT(flagstat_in)
  
  DORADO_ALIGNER.out.bam
                .join(DORADO_ALIGNER.out.bai)
                .join(refs)
                .join(method)
                .set { ch_pileup_in }

  emit:
    ch_pileup_in
    method

}