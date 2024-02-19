params.publishDir = './results'

process SAMTOOLS_SORT_N {
    tag "$meta"
    label 'process_medium'
    publishDir(
        path: "${params.publishDir}/samtools/sort",
        mode: 'copy',
        saveAs: { fn -> fn.substring(fn.lastIndexOf('/')+1) }
    )
    // publishDir "${params.out}", mode: 'copy', overwrite: false
   //  publishDir ( path: "${this.process}".replace(':','/').toLowerCase(), mode: 'copy', saveAs: { fn -> fn.substring(fn.lastIndexOf('/')+1) })
   // publishDir ${task.process}.replace(':','/').toLowerCase(), mode: 'copy', saveAs: { fn -> fn.substring(fn.lastIndexOf('/')+1) }

    conda "${moduleDir}/environment.yml"
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/samtools:1.19.2--h50ea8bc_0' :
        'biocontainers/samtools:1.19.2--h50ea8bc_0' }"

    input:
    tuple val(meta), path(bam)

    output:
    tuple val(meta), path("*.bam")      , emit: bam
    path "versions.yml"                 , emit: versions


    when:
    task.ext.when == null || task.ext.when

    script:
    def args = task.ext.args ?: ''
    def prefix = task.ext.prefix ?: "${meta}"
    if ("$bam" == "${prefix}.bam") error "Input and output names are the same, use \"task.ext.prefix\" to disambiguate!"
    """
    samtools sort \\
        $args \\
        -n \\
        -@ $task.cpus \\
        -o sorted_${bam.baseName}.bam \\
        -T $prefix \\
        $bam

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        samtools: \$(echo \$(samtools --version 2>&1) | sed 's/^.*samtools //; s/Using.*\$//')
    END_VERSIONS
    """

}