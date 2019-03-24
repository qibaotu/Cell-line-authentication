#!/bin/sh
#SBATCH -J download          # Job name
#SBATCH -o myjob.%j.out   # define stdout filename; %j expands to jobid
#SBATCH -e myjob.%j.err   # define stderr filename; skip to combine stdout and stderr

#SBATCH --mail-user=Juan.Xie@sdstate.edu
#SBATCH --mail-type=ALL

#SBATCH -N 1              # Number of nodes, not cores (16 cores/node)
#SBATCH -p defq
#SBATCH -t 120:00:00       # max time
#SBATCH --ntasks-per-node 20  

#SBATCH --partition=test        # Partition/Queue

nCores=10

cd /gpfs/scratch/juan.xie/script

Rscript SRAdb_meta.R