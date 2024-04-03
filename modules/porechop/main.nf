params.publishDir = './results'

process PORECHOP {
    tag "$meta"
    label 'process_medium'
    //publishDir "${params.out}", mode: 'copy', overwrite: false
    publishDir(
        path:  "${params.publishDir}/trim_repair/porechop",
        mode: 'copy',
        saveAs: { fn -> fn.substring(fn.lastIndexOf('/')+1) },
    )

    conda "${moduleDir}/environment.yml"




    input:
    tuple val(meta), path(reads)

    output:
    tuple val(meta), path("*.fastq.gz"), emit: reads
    tuple val(meta), path("*.log")     , emit: log
    path "versions.yml"                , emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    def args = task.ext.args ?: ''

    """
    micromamba run -n base porechop \\
        -i $reads \\
        -t $task.cpus \\
        $args \\
        --no_split \\
        --format fastq.gz \\
        -o porechop_${meta}.fastq.gz \\
        > ${meta}.log
    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        porechop: \$( porechop --version )
    END_VERSIONS
    """
}