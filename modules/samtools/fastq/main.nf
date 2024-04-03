params.publishDir = './results'

process SAMTOOLS_FASTQ {
    
    tag "$meta"
    label 'process_low'
    // publishDir "${params.out}", mode: 'copy', overwrite: false
    publishDir(
        path:  "${params.publishDir}/trim_repair/samtools/fastq",
        mode: 'copy',
        saveAs: { fn -> fn.substring(fn.lastIndexOf('/')+1) },
    )


    conda "${moduleDir}/environment.yml"
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/samtools:1.19.2--h50ea8bc_0' :
        'biocontainers/samtools:1.19.2--h50ea8bc_0' }"

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