params.publishDir = './results'

// preprocess beds (cuz its huge) > filter out reads with less than 5x coverage, select only 6mA and the three C contexts and the fractions of the methylation for each genomic position 
// convert bed to bedgraphs, prepared as input to methylScore
// split into strands (+/ -) and contexts (CG, CHG, CHH) specific 
// filter out positions with less than 5x coverage 
// remove positions with no coverage - reason why this exist is because col 5 (the total coverage) also contained read counts from Nother_mod - see definition from modkit pileup, 
// thats why is still important to remove out these calls, or else it gives problem when input to methylScore 


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
            out_file=\$(echo "\$mod" | sed 's/m,//' | sed 's/,0//')_positive.bedgraph
            ;;
          "-")
            out_file=\$(echo "\$mod" | sed 's/m,//' | sed 's/,0//')_negative.bedgraph
            ;;
          *)
            echo "> not a strand"
            exit 1
            ;;
        esac
        echo "File Path: ${in_bed}"
        awk -v strand=\$strand -v mod=\$mod 'BEGIN{OFS="\t"} ((\$4==mod) && (\$6==strand)) && (\$5 >= 5) && !(\$12 == 0 && \$13 == 0) {print \$1,\$2,\$3,\$11,\$12,\$13}' ${in_bed} > ${meta}_\${out_file}
      done
    done
    """
}

// can do something like this before the final `awk` to remove m,0, parts in the name - 
//# Modify the output file name using parameter expansion
//# Remove 'm,' and ',0' from the 'mod' part of the output file name
//        out_file=\${out_file//m,}
//        out_file=\${out_file//,0/}
