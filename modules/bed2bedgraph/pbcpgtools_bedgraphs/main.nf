process PBCPG_BEDGRAPHS {
    tag "$meta"
    label 'process_medium'
    publishDir(
        path: "${params.outdir}/${method}/pbcpg_bedgraph",
        mode: 'copy',
        saveAs: { fn -> fn.substring(fn.lastIndexOf('/')+1) },
    )

    input:
    tuple val(meta), path(in_bed), val(method)

    output:
    tuple val(meta), path("*.bedgraph"), emit: bedgraph


    when:
    task.ext.when == null || task.ext.when

    script:
    """
    set -eu

    awk -F'\\t' '\$6 >= 5 {print \$1,\$2,\$3,\$4,\$7,\$8}' ${in_bed} > ${meta}_CG.bedgraph
    
    """
}
