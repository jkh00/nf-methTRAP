params.publishDir = './results'

// preprocess beds (cuz its huge) > filter out reads with less than 5x coverage, select only 6mA and the three C contexts and the fractions of the methylation for each genomic position 

process FRAC_BED {
    tag "$meta"
    label 'process_medium'
    //publishDir "${params.out}", mode: 'copy', overwrite: false
    publishDir(
        path: "${params.publishDir}/processed_bed/frac_bed",
        mode: 'copy',
        saveAs: { fn -> fn.substring(fn.lastIndexOf('/')+1) },
    )

    input:
    tuple val(meta), path(in_bed)

    output:
    tuple val(meta), path("*.txt"), emit: txt


    when:
    task.ext.when == null || task.ext.when

    script:

    def args = task.ext.args ?: ''

    """
    cat $in_bed \\
    | cut -f4,5,11 | awk '(\$2 >= 5)' \\
    | grep -E  'h,CHH,0|m,CHH,0|h,CHG,0|m,CHG,0|h,CG,0|m,CG,0|a,A,0' \\
    |  cut -f1,3 > "${meta}_6mA_CHH_CHG_CG.txt"
        
    """

    
}