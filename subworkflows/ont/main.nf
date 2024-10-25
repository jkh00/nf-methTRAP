
/*
 ===========================================
 * Import subworkflows
 ===========================================
 */

include { TRIM_REPAIR } from './trim_repair/main'
include { ALIGN } from './align/main'
include { PILEUP } from './pileup/main'
include { PROCESS_BED } from './process_bed/main'


/*
 ===========================================
 * Workflows
 ===========================================
 */



// for ONT 

workflow ONT {
  
  take: input

  main:
    if (params.no_trim) {
            input
              .map(row -> [row.sample, row.ref])
              .set{ refs }

            input
              .map(row -> [row.sample, row.method])
              .set{ method }

            input
              .map(row -> [row.sample, row.modBam, row.ref, row.method])
              .set { dorado_in }

              if (params.bedgraph) {

                ALIGN(dorado_in, refs, method) | PILEUP | PROCESS_BED

              } else {

                ALIGN(dorado_in, refs, method) | PILEUP 

              }

      } else {

          if (params.bedgraph) {

        // Run the full workflow starting with TRIM_REPAIR
        input | TRIM_REPAIR | ALIGN | PILEUP | PROCESS_BED

          } else {

            input | TRIM_REPAIR | ALIGN | PILEUP 

          }
      }

}


