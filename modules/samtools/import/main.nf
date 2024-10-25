process SAMTOOLS_IMPORT {
    tag "$meta"
    label 'process_low'
    // publishDir "${params.out}", mode: 'copy', overwrite: false
    publishDir(
        path:  "${params.outdir}/ont/trim/${meta}",
        mode: 'copy',
        saveAs: { fn -> fn.substring(fn.lastIndexOf('/')+1) },
    )

    input:
    tuple val(meta), path(reads)

    output:
    tuple val(meta), path("*.bam") , emit: bam    
    path "versions.yml"                , emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    def args = task.ext.args ?: ''
    def prefix = task.ext.prefix ?: "${meta}"
    def input = reads
    
    """
    samtools \\
        import \\
        $input \\
        $args \\
        -T '*' \\
        -@ $task.cpus \\
        -o trimmed_${prefix}.bam

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        samtools: \$(echo \$(samtools --version 2>&1) | sed 's/^.*samtools //; s/Using.*\$//')
    END_VERSIONS
    """


}