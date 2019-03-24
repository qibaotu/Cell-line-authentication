### test SRAdb

library(SRAdb)

setwd('/gpfs/scratch/juan.xie/BreastCancer2/')
sqlfile = getSRAdbFile() 
sra_con = dbConnect(SQLite(), sqlfile)
rs1 <-read.table('/gpfs/scratch/juan.xie/IDs/breast_cell_lines_IDs_paired',header=T)

ascpCMD <- 'ascp -QT -l 300m -i /gpfs/home/juan.xie/.aspera/connect/etc/asperaweb_id_dsa.openssh'


getSRAfile( rs1$run, sra_con, destDir=getwd(),fileType = 'sra',
               srcType = 'fasp', ascpCMD = ascpCMD )
