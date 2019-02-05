# Cell-line-authentication

Implementation of the pipeline in a paper titled 'A novel RNA sequencing data analysis method for cell line authentication'.

Major steps:
fastq file -->read alignment(STAR 2-pass) --> variant calling (GATK4) --> variant annotation & filtering (snpEff&snpSift) --> SNVs comparision with COSMIC
