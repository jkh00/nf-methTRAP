params.publishDir = './results'

// preprocess beds (cuz its huge) > filter out reads with less than 5x coverage, select only 6mA and the three C contexts and the fractions of the methylation for each genomic position 

process BED2BEDGRAPH {
    tag "$meta"
    label 'process_medium'
    //publishDir "${params.out}", mode: 'copy', overwrite: false
    publishDir(
        path: "${params.publishDir}/processed_bed/bed2bedgraph",
        mode: 'copy',
        saveAs: { fn -> fn.substring(fn.lastIndexOf('/')+1) },
    )

    input:
    tuple val(meta), path(in_bed)

    output:
    tuple val(meta), path("*.bedgraph"), emit: bedgraph


    when:
    task.ext.when == null || task.ext.when

    script:
    """
    set -eu

    for strand in "+" "-"
    do
      for mod in "m,CHH,0" "m,CHG,0" "m,CG,0"
      do
        case \$strand in 
          "+")
            out_file=\${mod}_positive.bedgraph
            ;;
          "-")
            out_file=\${mod}_negative.bedgraph
            ;;
          *)
            echo "> not a strand"
            exit 1
            ;;
        esac
        echo "File Path: ${in_bed}"
        awk -v strand=\$strand -v mod=\$mod 'BEGIN{OFS="\t"} ((\$4==mod) && (\$6==strand)) && (\$5 >= 5) {print \$1,\$2,\$3,\$12,\$13}' ${in_bed} > ${meta}_\${out_file}
      done
    done
    """
}