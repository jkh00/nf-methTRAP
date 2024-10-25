process PBMM2 {
    tag "$meta"
    label 'process_medium'

    publishDir(
        path:  "${params.outdir}/${method}/aligned_pbmm2/${meta}",
        mode: 'copy',
        saveAs: { fn -> fn.substring(fn.lastIndexOf('/')+1) },
    )

    input:
    tuple val(meta), path(reads), path(ref), val(method)

    output:
    tuple val(meta), path("*.bam"), emit: bam
    path "versions.yml"       , emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:

    """

    pbmm2 align \\
        --sort --preset HiFi \\
        -j ${task.cpus / 2} -J ${task.cpus / 2} \\
        $ref $reads > ${meta}_pacbio_aligned.bam 



    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        pbmm2: \$( pbmm2 --version )
    END_VERSIONS
    """
}