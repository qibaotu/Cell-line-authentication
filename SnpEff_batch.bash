#!/bin/sh
#SBATCH -J SnpEff          # Job name
#SBATCH -o SnpEff.%j.out   # define stdout filename; %j expands to jobid
#SBATCH -e SnpEff.%j.err   # define stderr filename; skip to combine stdout and stderr

#SBATCH --mail-user=Juan.Xie@sdstate.edu
#SBATCH --mail-type=ALL

#SBATCH -N 1              # Number of nodes, not cores (16 cores/node)
#SBATCH -p test
#SBATCH -t 120:00:00       # max time
#SBATCH --ntasks-per-node 20  # cores 
#SBATCH --array=1-810%80


nCores=10
module use /cm/shared/modulefiles_local

genomeFastaFiles=/gpfs/scratch/juan.xie/resources/hg38/Homo_sapiens_assembly38.fasta


cd /gpfs/scratch/juan.xie/BreastCancer2/1

ID=$( cat /gpfs/scratch/juan.xie/IDs/paired2 | sed -n ${SLURM_ARRAY_TASK_ID}p)

cd ${ID}

time gatk VariantFiltration \
		-R $genomeFastaFiles \
        -V ${ID}.SNP.vcf \
        -window 35 \
        -cluster 3 \
        --filter-expression "FS >30.0" \
        --filter-name "FS" \
		--filter-expression "QD <2.0" \
		--filter-name "QD" \
        -O ${ID}_filtered.vcf

# annotation
java -Xmx4g -jar /gpfs/home/juan.xie/miniconda3/share/snpeff-4.3.1t-2/snpEff.jar -v -stats ./$ID.html hg38 ${ID}_filtered.vcf > ./$ID.ann.vcf  

		
## further filter

java -jar /gpfs/home/juan.xie/miniconda3/share/snpsift-4.3.1t-1/SnpSift.jar filter "(FILTER='PASS')" $ID.ann.vcf > ./$ID.ann.filtered.vcf

