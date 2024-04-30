params.publishDir = './results'

process MODKIT_PILEUP {
    tag "$meta"
    label 'process_high'
    //publishDir "${params.out}", mode: 'copy', overwrite: false
    publishDir(
        path: "${params.publishDir}/pileup",
        mode: 'copy',
        saveAs: { fn -> fn.substring(fn.lastIndexOf('/')+1) },
    )

    input:
    tuple val(meta), path(in_bam), path(index), path(ref)

    output:
    tuple val(meta), path("*.bed"), emit: bed
    tuple val(meta), path("*.log")     , emit: log
    path "versions.yml"                , emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:

    def args = task.ext.args ?: ''

    """
    modkit pileup \\
    --only-tabs \\
    -t $task.cpus \\
    --log-filepath ${meta}_pileup.log \\
    -r $ref \\
    --motif A 0 --motif CHH 0 --motif CHG 0 --motif CG 0 \\
    $in_bam \\
    ${meta}_6mA_CHH_CG_CHG.bed 
        
        

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        modkit: \$( modkit --version )
    END_VERSIONS
    """
}