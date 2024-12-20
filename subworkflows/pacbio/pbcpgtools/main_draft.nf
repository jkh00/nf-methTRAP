/*
 ===========================================
 * Import processes from modules
 ===========================================
 */

include { PB_CPG_TOOLS } from '../../../modules/pb_cpg_tools/main'
include { SAMTOOLS_SPLIT_STRAND } from '../../../modules/samtools/split_strands/main'
include { SAMTOOLS_MERGE } from '../../../modules/samtools/merge/main'

/*
 ===========================================
 * Workflows
 ===========================================
 */


// for PacBio 

workflow CPG_PILEUP {
  
  take:
    ch_pileup_in
    method
  
  main:
  SAMTOOLS_SPLIT_STRAND(inbam) 
  SAMTOOLS_SPLIT_STRAND.out.forwardbam
                           .join(SAMTOOLS_SPLIT_STRAND.out.reversebam)
                           .set{ stranded_out }
  SAMTOOLS_MERGE(stranded_out)
  SAMTOOLS_MERGE.out.bam
                    .set{ merged_bam }

  PB_CPG_TOOLS(ch_pileup_in)
  PB_CPG_TOOLS.out.bed
                  .join(method)
                  .set{ pile_out }
  
  emit:
     pile_out

}
