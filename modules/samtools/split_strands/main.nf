process SAMTOOLS_SPLIT_STRAND {
    tag "$meta"
    label 'process_medium'

    input:
    tuple val(meta), path(bam), path(index), path(ref), val(method)

    output:
    tuple val(meta), path("${meta}_forward*.bam")      , emit: forwardbam
    tuple val(meta), path("${meta}_reverse*.bam")      , emit: reversebam
    path "versions.yml"                                , emit: versions


    when:
    task.ext.when == null || task.ext.when

    script:

    """
    samtools view $bam -h -@ $task.cpus -F 20 \\
        | awk 'BEGIN {OFS="\\t"} /^@/ {print \$0; next} {\$0 = \$0 "\\tHP:i:1"; print \$0}' \\
        | samtools view -Sb -@ $task.cpus - -o ${meta}_forward_tagged.bam

    samtools view $bam -h -@ $task.cpus -f 16 \\
        |awk 'BEGIN {OFS="\\t"} /^@/ {print \$0; next} {\$0 = \$0 "\\tHP:i:2"; print \$0}' \\
        | samtools view -Sb -@ $task.cpus - -o ${meta}_reverse_tagged.bam
    

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        samtools: \$(echo \$(samtools --version 2>&1) | sed 's/^.*samtools //; s/Using.*\$//')
    END_VERSIONS
    """

}