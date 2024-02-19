params.publishDir = './results'

process DORADO_ALIGNER {
    tag "$meta"
    label 'process_medium'
    //publishDir "${params.out}", mode: 'copy', overwrite: false
    publishDir(
        path:  "${params.publishDir}/dorado/aligner",
        mode: 'copy',
        saveAs: { fn -> fn.substring(fn.lastIndexOf('/')+1) },
    )

    input:
    tuple val(meta), path(reads), path(ref)

    output:
    tuple val(meta), path("*.bam"), emit: bam
    path "versions.yml"                , emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:

    """
    dorado aligner \\
        -t $task.cpus \\
        $ref \\
        $reads \\
        > ${meta}_aligned.bam 
    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        dorado: \$( dorado --version )
    END_VERSIONS
    """
}