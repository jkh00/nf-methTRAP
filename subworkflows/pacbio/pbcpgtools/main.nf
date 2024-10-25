/*
 ===========================================
 * Import processes from modules
 ===========================================
 */

include { PB_CPG_TOOLS } from '../../../modules/pb_cpg_tools/main'

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

  PB_CPG_TOOLS(ch_pileup_in)
  PB_CPG_TOOLS.out.bed
                  .join(method)
                  .set{ pile_out }
  
  emit:
     pile_out

}
