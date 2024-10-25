/*
 ===========================================
 * Import processes from modules
 ===========================================
 */

include { MODKIT_BEDGRAPH } from '../../modules/bed2bedgraph/modkit_bedgraphs/main'
include { PBCPG_BEDGRAPHS } from '../../modules/bed2bedgraph/pbcpgtools_bedgraphs/main'


include { MINI_MODKIT_BEDGRAPH } from '../../modules/bed2bedgraph/mini_modkit_bedgraphs/main'
include { MINI_PBCPG_BEDGRAPHS } from '../../modules/bed2bedgraph/mini_pbcpgtools_bedgraphs/main'
include { PBMM_MODKIT_BEDGRAPH } from '../../modules/bed2bedgraph/pbmm_modkit_bedgraphs/main'
include { PBMM_PBCPG_BEDGRAPHS } from '../../modules/bed2bedgraph/pbmm_pbcpgtools_bedgraphs/main'

/*
 ===========================================
 * Import subworkflows
 ===========================================
 */

include { MAP_MINI } from './minimap2/main'
include { MODK_PILEUP } from './modkit_pile/main'
include { CPG_PILEUP } from './pbcpgtools/main'
include { MAP_PBMM2 } from './pbmm2/main'


/*
 ===========================================
 * Workflows
 ===========================================
 */

workflow PACBIO {
  take:
    input

  main:

  if (params.pb_all) {
      // Run all combinations in parallel if pb_all is true
      input | MAP_MINI | CPG_PILEUP | MINI_PBCPG_BEDGRAPHS
      input | MAP_MINI | MODK_PILEUP | MINI_MODKIT_BEDGRAPH
      input | MAP_PBMM2 | MODK_PILEUP | PBMM_MODKIT_BEDGRAPH
      input | MAP_PBMM2 | CPG_PILEUP | PBMM_PBCPG_BEDGRAPHS


  } else {

    if (params.aligner == "minimap2" && params.pileup_method == "pbcpgtools") {
      if (params.bedgraph) {
        input | MAP_MINI | CPG_PILEUP | PBCPG_BEDGRAPHS
      } else {
        input | MAP_MINI | CPG_PILEUP
      }
    } else if (!params.aligner && params.pileup_method == "pbcpgtools") {

      if (params.bedgraph) {
          input | MAP_PBMM2 | CPG_PILEUP | PBCPG_BEDGRAPHS
        } else {
          input | MAP_PBMM2 | CPG_PILEUP
        }
    } else if (params.aligner == "minimap2" && !params.pileup_method) {
      
      if (params.bedgraph) {
          input | MAP_MINI | MODK_PILEUP | MODKIT_BEDGRAPH
        } else {
          input | MAP_MINI | MODK_PILEUP
        }
    } else {

      // default setting
      if (params.bedgraph) {
          input | MAP_PBMM2 | MODK_PILEUP | MODKIT_BEDGRAPH
        } else {
          input | MAP_PBMM2 | MODK_PILEUP
        }
    }
  }
}