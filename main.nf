#!/usr/bin/env nextflow

nextflow.enable.dsl = 2 
params.publish_dir_mode = 'copy'
params.samplesheet = true
params.enable_conda = true
params.no_trim = false
params.out = './results'

/*
 * Print very cool text and parameter info to log. 

 */

log.info """\
==============================================================================================================================================
==============================================================================================================================================

 ,---.   .--. ________               ,---.    ,---.    .-''-. ,---------. .---.  .---.,---------. .-------.       ____    .-------.  
|    \\  |  ||        |              |    \\  /    |  .'_ _   \\\\          \\|   |  |_ _|\\          \\|  _ _   \\    .'  __ `. \\  _(`)_ \\ 
|  ,  \\ |  ||   .----'              |  ,  \\/  ,  | / ( ` )   '`--.  ,---'|   |  ( ' ) `--.  ,---'| ( ' )  |   /   '  \\  \\| (_ o._)| 
|  |\\_ \\|  ||  _|____   _ _    _ _  |  |\\_   /|  |. (_ o _)  |   |   \\   |   '-(_{;}_)   |   \\   |(_ o _) /   |___|  /  ||  (_,_) / 
|  _( )_\\  ||_( )_   | ( ' )--( ' ) |  _( )_/ |  ||  (_,_)___|   :_ _:   |      (_,_)    :_ _:   | (_,_).' __    _.-`   ||   '-.-'  
| (_ o _)  |(_ o._)__|(_{;}_)(_{;}_)| (_ o _) |  |'  \\   .---.   (_I_)   | _ _--.   |    (_I_)   |  |\\ \\  |  |.'   _    ||   |      
|  (_,_)\\  ||(_,_)     (_,_)--(_,_) |  (_,_)  |  | \\  `-'    /  (_(=)_)  |( ' ) |   |   (_(=)_)  |  | \\ `'   /|  _( )_  ||   |      
|  |    |  ||   |                   |  |      |  |  \\       /    (_I_)   (_{;}_)|   |    (_I_)   |  |  \\    / \\ (_ o _) //   )      
'--'    '--''---'                   '--'      '--'   `'-..-'     '---'   '(_,_) '---'    '---'   ''-'   `'-'   '.(_,_).' `---'     

----------------------------------------------------------------------------------------------------------------------------------------------
Jin Yan Khoo                                       
----------------------------------------------------------------------------------------------------------------------------------------------

  Parameters:
     samplesheet     : ${params.samplesheet}
     outdir            : ${params.out}

==============================================================================================================================================
==============================================================================================================================================
"""
    .stripIndent(false)

/*
 ===========================================
 * Import processes from modules
 ===========================================
 */

include { SAMTOOLS_SORT} from './modules/samtools/sort/main'
include { SAMTOOLS_SORT_N} from './modules/samtools/sort_n/main'
include { SAMTOOLS_FASTQ } from './modules/samtools/fastq/main'
include { PORECHOP } from './modules/porechop/main'
include { SAMTOOLS_IMPORT } from './modules/samtools/import/main'
include { MODKIT_REPAIR } from './modules/modkit/repair/main'
include { DORADO_ALIGNER } from './modules/dorado/aligner/main'
include { SAMTOOLS_INDEX } from './modules/samtools/index/main'
include { MODKIT_PILEUP } from './modules/modkit/pileup/main'
include { SAMTOOLS_FLAGSTAT } from './modules/samtools/flagstat/main'
include { FRAC_BED } from './modules/preprocess_bed/frac_bed//main'
include { BED2BEDGRAPH } from './modules/preprocess_bed/bed2bedgraph//main'
/*
 ===========================================
 * Workflows
 ===========================================
 */


workflow TRIM_REPAIR {

 ch_input = Channel.empty()

  /*
  Check samplesheet
  */

  if(params.samplesheet) {
    ch_input = Channel.fromPath(params.samplesheet) 
                      .splitCsv(header:true) 
    reads_in = ch_input.map(row -> [row.sample, file("${row.modBam}")])
    refs = ch_input.map(row -> [row.sample, file("${row.ref}")])
  } else {
    exit 1, 'Input samplesheet not specified!'
  }

  /*
  Sort modBam, convert to fastq, trim adapters and barcode, then convert back to bam and repair the MM/ML tags using modkit repair 
  then align to reference assembly, and pileup to create bedMethyl using modkit pileup
  */

  SAMTOOLS_SORT_N(reads_in)
  SAMTOOLS_FASTQ(SAMTOOLS_SORT_N.out.bam)
  PORECHOP(SAMTOOLS_FASTQ.out.fastq)
  SAMTOOLS_IMPORT(PORECHOP.out.reads)
  ch_modkit_in = SAMTOOLS_SORT_N.out.bam.join(SAMTOOLS_IMPORT.out.bam) 
  MODKIT_REPAIR(ch_modkit_in)
  ch_dorado_in = MODKIT_REPAIR.out.bam.join(refs)

  emit: 
    ch_dorado_in  
    refs
} 


workflow ALIGN {
  
  take: 
    ch_dorado_in
    refs

  main:

  DORADO_ALIGNER(ch_dorado_in)
  bam_file = DORADO_ALIGNER.out.bam
  bai_file = DORADO_ALIGNER.out.bai
  SAMTOOLS_FLAGSTAT(bam_file)
  
  ch_pileup_in = DORADO_ALIGNER.out.bam
                .join(DORADO_ALIGNER.out.bai)
                .join(refs)

  emit:
    ch_pileup_in

}

workflow PILEUP {  
  
  take: 
    ch_pileup_in
  
  main: 
    MODKIT_PILEUP(ch_pileup_in)
    modkit_out = MODKIT_PILEUP.out.bed
  
  emit: 
    modkit_out

}


workflow PROCESS_BED {  
  
  take: 
    modkit_out
  
  main: 
    FRAC_BED(modkit_out)
    BED2BEDGRAPH(modkit_out)

}


/* workflow {
  TRIM_REPAIR() | ALIGN | PILEUP | PROCESS_BED
}*/


workflow {


    if (params.no_trim) {
        // If skipping TRIM_REPAIR, process the samplesheet for direct input to ALIGN
        if (params.samplesheet) {
          ch_input = Channel.empty()
            ch_input = Channel.fromPath(params.samplesheet)
                              .splitCsv(header: true)
            ch_input_modBam = ch_input.map(row -> [row.sample, file("${row.modBam}")])
            refs = ch_input.map(row -> [row.sample, file("${row.ref}")])
            ch_dorado_in = ch_input_modBam.join(refs)
        } else {
            exit 1, 'Input samplesheet not specified!'
        }
        ALIGN(ch_dorado_in, refs) | PILEUP | PROCESS_BED
    } else {
        // Run the full workflow starting with TRIM_REPAIR
        TRIM_REPAIR() | ALIGN | PILEUP | PROCESS_BED
    }
}

 