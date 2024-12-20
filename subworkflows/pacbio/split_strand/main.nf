/*
 ===========================================
 * Import processes from modules
 ===========================================
 */

include { SAMTOOLS_SPLIT_STRAND } from '../../../modules/samtools/split_strands/main'
include { SAMTOOLS_MERGE } from '../../../modules/samtools/merge/main'

/*
 ===========================================
 * Workflows
 ===========================================
 */


// for PacBio 

workflow SPLIT_STRAND {
  
  take:
    ch_pileup_in
    method
  
  main:



  SAMTOOLS_SPLIT_STRAND(ch_pileup_in) 
  SAMTOOLS_SPLIT_STRAND.out.forwardbam
                           .join(SAMTOOLS_SPLIT_STRAND.out.reversebam)
                           .set{ stranded_out }
  SAMTOOLS_MERGE(stranded_out)
  SAMTOOLS_MERGE.out.bam
                    .join(SAMTOOLS_MERGE.out.index)
                    .join(ch_pileup_in.map { it -> [it[0], it[3]] })
                    .join(method)
                    .set{ merged_bam }

   
  
  emit:
     merged_bam
     method

}
