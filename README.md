# Cell-line-authentication

Implementation of the pipeline in a paper titled 'A novel RNA sequencing data analysis method for cell line authentication' published on PLOS one.

Major steps:
fastq file -->read alignment(STAR 2-pass) --> variant calling (GATK4) --> variant annotation & filtering (snpEff&snpSift) --> SNVs comparision with COSMIC.

The vignette is provided at https://htmlpreview.github.io/?https://github.com/qibaotu/Cell-line-authentication/blob/master/vignette/Cell_line.html
