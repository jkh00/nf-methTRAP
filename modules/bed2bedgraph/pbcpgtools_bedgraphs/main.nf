process PBCPG_BEDGRAPHS {
    tag "$meta"
    label 'process_medium'
    publishDir(
        path: "${params.outdir}/${method}/pbcpg_bedgraph",
        mode: 'copy',
        saveAs: { fn -> fn.substring(fn.lastIndexOf('/')+1) },
    )

    input:
    tuple val(meta), path(forwardbed), path(reversebed), val(method)

    output:
    tuple val(meta), path("*.bedgraph"), emit: bedgraph


    when:
    task.ext.when == null || task.ext.when

    script:
    """
    set -eu

    awk 'BEGIN {OFS="\\t"} {print \$1, \$2, \$3, \$4, \$6}' ${forwardbed} > ${meta}.model.forward.bedgraph
    awk 'BEGIN {OFS="\\t"} {print \$1, \$2+1, \$3+1, \$4, \$6}' ${reversebed} > ${meta}.model.reverse.bedgraph

    cat ${meta}.model.forward.bedgraph ${meta}.model.reverse.bedgraph > ${meta}_CG_model.merged.bedgraph
    
    """
}
