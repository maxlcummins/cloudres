# nf-core/cloudres

[![GitHub Actions CI Status](https://github.com/nf-core/cloudres/actions/workflows/ci.yml/badge.svg)](https://github.com/nf-core/cloudres/actions/workflows/ci.yml)
[![GitHub Actions Linting Status](https://github.com/nf-core/cloudres/actions/workflows/linting.yml/badge.svg)](https://github.com/nf-core/cloudres/actions/workflows/linting.yml)
[![Cite with Zenodo](http://img.shields.io/badge/DOI-10.5281/zenodo.XXXXXXX-1073c8?labelColor=000000)](https://doi.org/10.5281/zenodo.XXXXXXX)
[![unit tests](https://img.shields.io/badge/unit_tests-nf--test-337ab7.svg)](https://www.nf-test.com)

[![Nextflow](https://img.shields.io/badge/nextflow%20DSL2-%E2%89%A524.04.2-23aa62.svg)](https://www.nextflow.io/)
[![run with conda](http://img.shields.io/badge/run%20with-conda-3EB049?labelColor=000000&logo=anaconda)](https://docs.conda.io/en/latest/)
[![run with docker](https://img.shields.io/badge/run%20with-docker-0db7ed?labelColor=000000&logo=docker)](https://www.docker.com/)
[![run with singularity](https://img.shields.io/badge/run%20with-singularity-1d355c.svg?labelColor=000000)](https://sylabs.io/docs/)
[![Launch on Seqera Platform](https://img.shields.io/badge/Launch%20%F0%9F%9A%80-Seqera%20Platform-%234256e7)](https://cloud.seqera.io/launch?pipeline=https://github.com/nf-core/cloudres)

## Introduction

**nf-core/cloudres** is a Nextflow pipeline designed for bacterial antimicrobial resistance (AMR) typing. The pipeline ingests raw sequence data (FASTQ files) and performs comprehensive processing steps, including quality control, read trimming, host contamination removal, de novo assembly, and AMR gene detection. The output comprises quality reports, sequence assemblies, and AMR typing results to guide downstream analyses.

## Pipeline Overview

The main steps of the pipeline include:

1. **Quality Control:**  
   - Run [FastQC](https://www.bioinformatics.babraham.ac.uk/projects/fastqc/) on raw reads.
   - Aggregate QC metrics with [MultiQC](http://multiqc.info/).

2. **Preprocessing:**  
   - Trim and filter sequence data using [Fastp](https://github.com/OpenGene/fastp).
   - Remove contaminating host sequences (if provided) using tailored modules.

3. **Assembly and Typing:**  
   - Assemble reads using [SPADES](http://cab.spbu.ru/software/spades/).
   - Perform AMR gene identification and bacterial typing via integrated tools.

4. **Post-processing and Reporting:**  
   - Generate comprehensive reports and collate software versions.
   - Sync results to designated S3 buckets for further review.

## Usage

Prepare a sample sheet (`samplesheet.csv`) containing your FASTQ files. The expected format is:

```csv
name,fastq_1,fastq_2
SAMPLE_NAME,/path/to/sample_R1.fastq.gz,/path/to/sample_R2.fastq.gz
```

Each row represents the sample name followed by the paths to its paired-end reads.

Running the Pipeline
You can run the pipeline using:

```bash
nextflow run nf-core/cloudres \
   -profile <docker/singularity/.../institute> \
   --input samplesheet.csv \
   --outdir /path/to/output_directory
```

> [!WARNING]
> Please provide pipeline parameters via the CLI or Nextflow `-params-file` option. Custom config files including those provided by the `-c` Nextflow option can be used to provide any configuration _**except for parameters**_; see [docs](https://nf-co.re/docs/usage/getting_started/configuration#custom-configuration-files).

## Credits

nf-core/cloudres was originally written by maxlcummins.

We thank the following people for their extensive assistance in the development of this pipeline:

## Contributions and Support

If you would like to contribute to this pipeline, please see the [contributing guidelines](.github/CONTRIBUTING.md).

## Citations

<!-- TODO nf-core: Add citation for pipeline after first release. Uncomment lines below and update Zenodo doi and badge at the top of this file. -->
<!-- If you use nf-core/cloudres for your analysis, please cite it using the following doi: [10.5281/zenodo.XXXXXX](https://doi.org/10.5281/zenodo.XXXXXX) -->

<!-- TODO nf-core: Add bibliography of tools and data used in your pipeline -->

An extensive list of references for the tools used by the pipeline can be found in the [`CITATIONS.md`](CITATIONS.md) file.

This pipeline uses code and infrastructure developed and maintained by the [nf-core](https://nf-co.re) community, reused here under the [MIT license](https://github.com/nf-core/tools/blob/main/LICENSE).

> **The nf-core framework for community-curated bioinformatics pipelines.**
>
> Philip Ewels, Alexander Peltzer, Sven Fillinger, Harshil Patel, Johannes Alneberg, Andreas Wilm, Maxime Ulysse Garcia, Paolo Di Tommaso & Sven Nahnsen.
>
> _Nat Biotechnol._ 2020 Feb 13. doi: [10.1038/s41587-020-0439-x](https://dx.doi.org/10.1038/s41587-020-0439-x).
