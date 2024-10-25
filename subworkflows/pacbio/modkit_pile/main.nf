/*
 ===========================================
 * Import processes from modules
 ===========================================
 */


include { MODKIT_PILEUP } from '../../../modules/modkit/pileup/main'
include { MODKIT_BEDGRAPH } from '../../../modules/bed2bedgraph/modkit_bedgraphs'

/*
 ===========================================
 * Workflows
 ===========================================
 */


// for PacBio 


workflow MODK_PILEUP {  
  
  take: 
    ch_pileup_in
    method
  
  main: 
    MODKIT_PILEUP(ch_pileup_in)
    MODKIT_PILEUP.out.bed
                     .join(method)
                     .set{ modkit_out }
    
  emit: 
    modkit_out

}

