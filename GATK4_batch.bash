#!/bin/bash
#SBATCH -N 1
#SBATCH -p LM --mem=128GB
#SBATCH --ntasks-per-node 28
#SBATCH -t 120:00:00
# echo commands to stdout
set -x

cd /pylon5/cc5fpcp/xiej/Cell_Line

# download gtf
# cd /pylon5/cc5fpcp/xiej/Cell_Line/resources/bundle/hg38

# wget ftp://ftp.ebi.ac.uk/pub/databases/gencode/Gencode_human/release_26/gencode.v26.primary_assembly.annotation.gtf.gz
# gunzip gencode.v26.primary_assembly.annotation.gtf.gz

## STAR--build Index
genomeDir=/pylon5/cc5fpcp/xiej/Cell_Line/resources/star_index_hg38
genomeFastaFiles=/pylon5/cc5fpcp/xiej/Cell_Line/resources/bundle/hg38/Homo_sapiens_assembly38.fasta
sjdbGTFfile=/pylon5/cc5fpcp/xiej/Cell_Line/resources/bundle/hg38/gencode.v26.primary_assembly.annotation.gtf
dbsnp_vcf=/pylon5/cc5fpcp/xiej/Cell_Line/resources/bundle/hg38/dbsnp_146.hg38.vcf


module load staraligner/2.5.2b


	time STAR --runThreadN 6 \
	--runMode genomeGenerate \
	--genomeDir $genomeDir \
	--genomeFastaFiles $genomeFastaFiles \
	--sjdbGTFfile /pylon5/cc5fpcp/xiej/Cell_Line/resources/bundle/hg38/gencode.v26.primary_assembly.annotation.gtf \
	--sjdbOverhang 99




## STAR-- per sample 2-pass
runDir=/pylon5/cc5fpcp/xiej/Cell_Line/1pass
mkdir $runDir
cd $runDir

for file in /pylon5/cc5fpcp/xiej/Cell_Line/RawData/*fastq
do
time STAR --runThreadN 12 \
--genomeDir $genomeDir \
--readFilesIn $file \
--outFileNamePrefix /pylon5/cc5fpcp/xiej/Cell_Line/1pass/$(basename $file .fastq)
done



## rebuild index
genomeDir=/pylon5/cc5fpcp/xiej/Cell_Line/hg38_2pass
mkdir $genomeDir
STAR --runThreadN 12 \
      --runMode genomeGenerate \
      --genomeDir $genomeDir \
      --genomeFastaFiles $genomeFastaFiles \
      --sjdbFileChrStartEnd /pylon5/cc5fpcp/xiej/Cell_Line/1pass/*out.tab \
      --sjdbOverhang 99  

	  
##
runDir=/pylon5/cc5fpcp/xiej/Cell_Line/2pass
mkdir $runDir
cd $runDir

for file in /pylon5/cc5fpcp/xiej/Cell_Line/RawData/*fastq
do
time STAR --runThreadN 12 \
--genomeDir $genomeDir \
--readFilesIn $file \
	  --outFileNamePrefix /pylon5/cc5fpcp/xiej/Cell_Line/2pass/$(basename $file .fastq)
done    


##  ref: https://www.jianshu.com/p/b400dc7c5eea
# ref: http://www.bioinfo-scrounger.com/archives/311
## ref2: https://gatkforums.broadinstitute.org/gatk/discussion/3891/calling-variants-in-rnaseq
# ftp://ftp.broadinstitute.org/bundle/hg38/
# https://software.broadinstitute.org/gatk/documentation/quickstart.php
# https://github.com/gatk-workflows/gatk3-4-rnaseq-germline-snps-indels/blob/master/rna-germline-variant-calling.wdl


module load gatk/4.0.1.2


## picard Add read groups, sort, mark duplicates and create index
for file in /pylon5/cc5fpcp/xiej/Cell_Line/2pass/*Aligned.out.sam
do
time gatk AddOrReplaceReadGroups \
        -I $file \
        -O  /pylon5/cc5fpcp/xiej/Cell_Line/RST2/$(basename $file Aligned.out.sam)_rg_added_sorted.bam \
        -SO coordinate \
        -RGID $(basename $file Aligned.out.sam) \
        -RGLB rna \
        -RGPL illumina \
        -RGPU hiseq \
        -RGSM $(basename $file Aligned.out.sam) 
done

for file in /pylon5/cc5fpcp/xiej/Cell_Line/RST2/*rg_added_sorted.bam
do
time gatk MarkDuplicates \
        -I $file \
        -O /pylon5/cc5fpcp/xiej/Cell_Line/RST2/$(basename $file _rg_added_sorted.bam)_dedup.bam  \
        -CREATE_INDEX true \
        -VALIDATION_STRINGENCY SILENT \
        -M /pylon5/cc5fpcp/xiej/Cell_Line/RST2/$(basename $file _rg_added_sorted.bam)_dedup.metrics
done


### variant calling
# Split’N’Trim and reassign mapping qualities
for file in /pylon5/cc5fpcp/xiej/Cell_Line/RST2/*dedup.bam 
do

time gatk SplitNCigarReads \
        -R $genomeFastaFiles \
        -I $file \
        -O /pylon5/cc5fpcp/xiej/Cell_Line/RST2/$(basename $file _dedup.bam)_dedup_split.bam
done
        
		
# optional: IndelRealign
# https://gatkforums.broadinstitute.org/gatk/discussion/6800/known-sites-for-indel-realignment-and-bqsr-in-hg38-bundle
# https://gatkforums.broadinstitute.org/gatk/discussion/11455/realignertargetcreator-and-indelrealigner

for file in /pylon5/cc5fpcp/xiej/Cell_Line/RST2/*dedup_split.bam
do

# optional: BQSR, base recalibration
time gatk BaseRecalibrator \
        -R $genomeFastaFiles \
        -I $file \
        --known-sites /pylon5/cc5fpcp/xiej/Cell_Line/resources/bundle/hg38/1000G_phase1.snps.high_confidence.hg38.vcf.gz \
        --known-sites /pylon5/cc5fpcp/xiej/Cell_Line/resources/bundle/hg38/Mills_and_1000G_gold_standard.indels.hg38.vcf.gz \
		--known-sites /pylon5/cc5fpcp/xiej/Cell_Line/resources/bundle/hg38/dbsnp_146.hg38.vcf.gz \
        -O /pylon5/cc5fpcp/xiej/Cell_Line/RST2/$(basename $file _dedup_split.bam)_recal_data.table
done

## PrintReads is replaced by ApplyBQSR
for file in /pylon5/cc5fpcp/xiej/Cell_Line/RST2/*dedup_split.bam
do
time gatk ApplyBQSR \
   -R $genomeFastaFiles \
   -I $file \
   --bqsr-recal-file /pylon5/cc5fpcp/xiej/Cell_Line/RST2/$(basename $file _dedup_split.bam)_recal_data.table \
   -O $(basename $file _dedup_split.bam)_BQSR.bam
done
 
		
## now can do variant calling
for file in /pylon5/cc5fpcp/xiej/Cell_Line/RST2/*dedup_split.bam
do
time gatk HaplotypeCaller \
        -R $genomeFastaFiles \
        -I $file \
        --dont-use-soft-clipped-bases \
        -stand-call-conf 20.0 \
        -O /pylon5/cc5fpcp/xiej/Cell_Line/RST2/$(basename $file _dedup_split.bam).vcf
done

## variant filtering

for file in /pylon5/cc5fpcp/xiej/Cell_Line/RST2/*vcf
do
time gatk VariantFiltration \
        -R $genomeFastaFiles \
        -V $file \
        -window 35 \
        -cluster 3 \
        --filter-expression "FS >30.0 || QD <2.0" \
        --filter-name "my_filter" \
        -O /pylon5/cc5fpcp/xiej/Cell_Line/RST2/$(basename $file .vcf)_filtered.vcf
done

## install SnpEff
wget http://sourceforge.net/projects/snpeff/files/snpEff_latest_core.zip
# Unzip file
unzip snpEff_latest_core.zip

## download SnpEff databases
cd /path/to/snpEff

java -jar ./snpEff/snpEff.jar download hg38

# annotate
java -Xmx4g -jar ./snpEff/snpEff.jar -v -stats SRR24851145.html hg38 /pylon5/cc5fpcp/xiej/Cell_Line/SNP_annotation/SRR2481145_filtered.vcf >SRR2481145_filtered.ann.vcf

# filter
java -jar ./SnpSift.jar filter "(ANN[*].IMPACT = 'HIGH') & (FILTER='PASS') &(DP >=10)" /pylon5/cc5fpcp/xiej/Cell_Line/SNP_annotation/SRR2481145_filtered.ann.vcf >SRR2481145_filtered.ann.filtered.vcf


