/*
 ===========================================
 * Import processes from modules
 ===========================================
 */


include { MODKIT_PILEUP } from '../../../modules/modkit/pileup/main'

/*
 ===========================================
 * Workflows
 ===========================================
 */


workflow PILEUP {  
  
  take: 
    ch_pileup_in
    method
  
  main: 

    MODKIT_PILEUP(ch_pileup_in)
    MODKIT_PILEUP.out.bed
                     .join(method)
                     .set { modkit_out }


  emit: 
    modkit_out

}