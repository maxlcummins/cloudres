/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    IMPORT MODULES / SUBWORKFLOWS / FUNCTIONS
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/
include { FASTQC                 } from '../modules/nf-core/fastqc/main'
include { MULTIQC                } from '../modules/nf-core/multiqc/main'
include { FASTP } from '../modules/nf-core/fastp/main' 
include { SPADES } from '../modules/nf-core/spades/main'
include { HOSTILE_FETCH } from '../modules/nf-core/hostile/fetch/main'
include { HOSTILE_CLEAN } from '../modules/nf-core/hostile/clean/main' 
include { RASUSA } from '../modules/nf-core/rasusa/main'
include { QUAST } from '../modules/nf-core/quast/main'
include { MLST } from '../modules/nf-core/mlst/main'
include { ABRITAMR_RUN } from '../modules/nf-core/abritamr/run/main'
include { paramsSummaryMap       } from 'plugin/nf-schema'
include { paramsSummaryMultiqc   } from '../subworkflows/nf-core/utils_nfcore_pipeline'
include { softwareVersionsToYAML } from '../subworkflows/nf-core/utils_nfcore_pipeline'
include { methodsDescriptionText } from '../subworkflows/local/utils_nfcore_cloudres_pipeline'

//include { FASTQ_TRIM_FASTP_FASTQC } from '../subworkflows/nf-core/fastq_trim_fastp_fastqc' 

/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    RUN MAIN WORKFLOW
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/

workflow CLOUDRES {

    take:
    ch_samplesheet // channel: samplesheet read in from --input
    main:
   
    ch_versions = Channel.empty()
    ch_multiqc_files = Channel.empty()
    
    // Run Fastp
    FASTP(
        ch_samplesheet,
        [],
        [],
        [],
        [])

    updated_reads_ch = FASTP.out.reads

    ch_multiqc_files = ch_multiqc_files.mix(FASTP.out.json.collect{it[1]})
    ch_versions = ch_versions.mix(FASTP.out.versions.first())

    if (!params.skip_rasusa) {
        if (!params.hostile_db) {
            error "Parameter 'hostile_db' is required but was not specified"
        }
        
        hostile_db_ch = file(params.hostile_db).exists() ? 
                    Channel.value(file(params.hostile_db)) : 
                    { error "Hostile database file not found: ${params.hostile_db}" }

        // Dehosting
        HOSTILE_CLEAN(updated_reads_ch, hostile_db_ch, 'human-t2t-hla.argos-bacteria-985_rs-viral-202401_ml-phage-202401')

        updated_reads_ch = HOSTILE_CLEAN.out.fastq

        ch_multiqc_files = ch_multiqc_files.mix(HOSTILE_CLEAN.out.json.collect{it[1]})
        ch_versions = ch_versions.mix(HOSTILE_CLEAN.out.versions.first())
        }

    

    // RASUSA subsampling
    if (!params.skip_rasusa) {
        // Create proper input format for RASUSA
        ch_rasusa_input = updated_reads_ch.map { meta, reads -> 
            // Add genome_size from params
            [ meta, reads, params.genome_size ]
        }
        RASUSA ( 
            ch_rasusa_input,
            params.depth_cutoff ?: 100 // Default depth cutoff if not specified
        )
        updated_reads_ch = RASUSA.out.reads

        ch_versions = ch_versions.mix(RASUSA.out.versions.first())
    }

    ch_reads_to_assemble = updated_reads_ch
    .map { meta, fastq -> [ meta, fastq, [], [] ] }

    // Genome assembly
    SPADES(
        ch_reads_to_assemble,
        [],
        [])

    ch_versions = ch_versions.mix(SPADES.out.versions.first())

    // QUAST
    QUAST(
        SPADES.out.contigs,
        [[],[]],
        [[],[]])

    ch_multiqc_files = ch_multiqc_files.mix(QUAST.out.tsv.collect{it[1]})
    ch_versions = ch_versions.mix(QUAST.out.versions.first())

    // MLST
    MLST(SPADES.out.contigs)

    ch_versions = ch_versions.mix(MLST.out.versions.first())

    // ABRITAMR
    ABRITAMR_RUN(SPADES.out.contigs)

    ch_versions = ch_versions.mix(ABRITAMR_RUN.out.versions.first())

    //
    // MODULE: Run FastQC
    //
    FASTQC (
        ch_samplesheet
    )
    ch_multiqc_files = ch_multiqc_files.mix(FASTQC.out.zip.collect{it[1]})
    ch_versions = ch_versions.mix(FASTQC.out.versions.first())

    //
    // Collate and save software versions
    //
    softwareVersionsToYAML(ch_versions)
        .collectFile(
            storeDir: "${params.outdir}/pipeline_info",
            name:  'cloudres_software_'  + 'mqc_'  + 'versions.yml',
            sort: true,
            newLine: true
        ).set { ch_collated_versions }


    //
    // MODULE: MultiQC
    //
    ch_multiqc_config        = Channel.fromPath(
        "$projectDir/assets/multiqc_config.yml", checkIfExists: true)
    ch_multiqc_custom_config = params.multiqc_config ?
        Channel.fromPath(params.multiqc_config, checkIfExists: true) :
        Channel.empty()
    ch_multiqc_logo          = params.multiqc_logo ?
        Channel.fromPath(params.multiqc_logo, checkIfExists: true) :
        Channel.empty()

    summary_params      = paramsSummaryMap(
        workflow, parameters_schema: "nextflow_schema.json")
    ch_workflow_summary = Channel.value(paramsSummaryMultiqc(summary_params))
    ch_multiqc_files = ch_multiqc_files.mix(
        ch_workflow_summary.collectFile(name: 'workflow_summary_mqc.yaml'))
    ch_multiqc_custom_methods_description = params.multiqc_methods_description ?
        file(params.multiqc_methods_description, checkIfExists: true) :
        file("$projectDir/assets/methods_description_template.yml", checkIfExists: true)
    ch_methods_description                = Channel.value(
        methodsDescriptionText(ch_multiqc_custom_methods_description))

    ch_multiqc_files = ch_multiqc_files.mix(ch_collated_versions)
    ch_multiqc_files = ch_multiqc_files.mix(
        ch_methods_description.collectFile(
            name: 'methods_description_mqc.yaml',
            sort: true
        )
    )

    MULTIQC (
        ch_multiqc_files.collect(),
        ch_multiqc_config.toList(),
        ch_multiqc_custom_config.toList(),
        ch_multiqc_logo.toList(),
        [],
        []
    )
    emit:
    multiqc_report = MULTIQC.out.report.toList() // channel: /path/to/multiqc_report.html
    versions       = ch_versions                 // channel: [ path(versions.yml) ]
    

}

/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    THE END
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/
