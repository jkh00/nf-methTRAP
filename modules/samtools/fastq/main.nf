

process SAMTOOLS_FASTQ {
    
    tag "$meta"
    label 'process_high'
    // publishDir "${params.out}", mode: 'copy', overwrite: false
   /* publishDir(
        path:  "${params.publishDir}/trim_repair/samtools/convert2fastq",
        mode: 'copy',
        saveAs: { fn -> fn.substring(fn.lastIndexOf('/')+1) },
    )
*/

    input:
    tuple val(meta), path(input)

    output:
    tuple val(meta), path("*.fastq.gz"), optional:true, emit: fastq
    path "versions.yml"                , emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:

    """
    samtools \\
        fastq \\
        -T "*" \\
        -c 9 \\
        --threads ${task.cpus-1} \\
        $input \\
        -0 ${meta}.fastq.gz 

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        samtools: \$(echo \$(samtools --version 2>&1) | sed 's/^.*samtools //; s/Using.*\$//')
    END_VERSIONS
    """
}