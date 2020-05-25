#Script created by Luis Víquez-R for the qiime analysis of the DNA-PNA clamps.
#This paper was submitted to Methods in Ecology and Evolution
#title: Jumping the green wall: the use of PNA-DNA clamps to enhance microbiome sampling depth in wildlife microbiome research
# Authors: Luis Víquez-R, Ramona Fleischer, Kerstin Wilhelm, Marco Tschapka,and Simone Sommer
#Universität Ulm, 2020

#Github repository: https://github.com/luisvqz/V4_pna_clamps_4_wildlife.git

tmux

source activate qiime2-2019.10


#Importing the data

qiime tools import \
  --type 'SampleData[PairedEndSequencesWithQuality]' \
  --input-path data \
  --input-format CasavaOneEightSingleLanePerSampleDirFmt \
  --output-path outputmet2/demux-paired-end.qza 

#Sumarize the data of the output

qiime demux summarize \
--i-data outputmet2/demux-paired-end.qza \
--o-visualization outputmet2/demux-paired-end.qzv


#We use DADA2 methods

qiime dada2 denoise-paired \
--i-demultiplexed-seqs outputmet2/demux-paired-end.qza \
--p-trim-left-f 23 \
--p-trim-left-r 20 \
--p-trunc-len-f 200 \
--p-trunc-len-r 200 \
--p-n-threads 8 \
--output-dir outputmet2/DADA2stats \
--o-representative-sequences outputmet2/rep-seqs-dada2.qza \
--o-table outputmet2/table-dada2.qza \
--verbose

qiime feature-table summarize \
--i-table outputmet2/table-dada2.qza \
--o-visualization outputmet2/table-dada2.qzv \
--m-sample-metadata-file mapping/mapfile20200217t.txt

#This code allows us to visualise the number of sequences removed at each denoising step:

qiime metadata tabulate \
  --m-input-file outputmet2/DADA2stats/denoising_stats.qza \
  --o-visualization outputmet2/DADA2stats/denoising_stats.qzv


#This code allows us to visualise the ASV sequences kept in the dataset:

qiime feature-table tabulate-seqs \
  --i-data outputmet2/rep-seqs-dada2.qza \
  --o-visualization outputmet2/rep-seqs-dada2.qzv

#Assignment taxonomy to the features in our samples using SILVA database, a classifier needs to be train for this
#please see the qiime2 tutorials on how to train a new classfier

qiime feature-classifier classify-sklearn \
  --i-classifier gg/silva-132-99-515-806-nb-classifiert.qza \
  --i-reads outputmet2/rep-seqs-dada2.qza \
  --p-n-jobs 4 \
  --o-classification outputmet2/taxonomy.qza

#for visualizatin we can use

qiime metadata tabulate \
  --m-input-file outputmet2/taxonomy.qza \
  --o-visualization outputmet2/taxonomy.qzv


##### here the analysis splits in two, we want to keep the unfiltered data 
##(meaning the data that in which we havent apply the taxonomy filters to remove mitochondrias and chloroplasts)
## so we create an output table for the rep seq, barplots to explore data and a summary table of the features contain in our samples


#lets visualise our results as a boxplot:

qiime taxa barplot \
  --i-table outputmet2/table-dada2.qza \
  --i-taxonomy outputmet2/taxonomy.qza \
  --m-metadata-file mapping/mapfile20200217t.txt \
  --o-visualization outputmet2/taxa-bar-plotssectionunf.qzv

qiime tools view outputmet2/taxa-bar-plotssectionunf.qzv


### summary table for unfiltered data
qiime feature-table summarize \
--i-table outputmet2/table-dada2.qza \
--o-visualization outputmet2/table-unf.qzv \
--m-sample-metadata-file mapping/mapfile20200217t.txt

### summary rep seq for unflitered data

qiime feature-table tabulate-seqs \
  --i-data outputmet2/rep-seqs-dada2.qza \
  --o-visualization outputmet2/rep-seqs-unf.qzv

#######tree for unfiltered
qiime phylogeny align-to-tree-mafft-fasttree \
  --i-sequences outputmet2/rep-seqs-dada2.qza \
  --o-alignment outputmet2/aligned-rep-seqs-dada2.qza \
  --o-masked-alignment outputmet2/masked-aligned-rep-seqs-dada2.qza \
  --o-tree outputmet2/unrooted-treeunf.qza \
  --o-rooted-tree outputmet2/rooted-treeunf.qza

##### Here we end the unfiltered part of the analysis and proceed to remove archaea, mitochondria and chloroplasts

###lets remove sequences that are Archaea,mitochondria,chloroplast,Unassigned and not assigned at the phylum level from our table and list of sequences:

  ######FOR SILVA

qiime taxa filter-table \
  --i-table outputmet2/table-dada2.qza  \
  --i-taxonomy outputmet2/taxonomy.qza \
  --p-exclude Archaea,Mitochondra,Chloroplast,Unassigned \
  --p-include D_ \
  --o-filtered-table outputmet2/table-filtered0.qza

qiime taxa filter-table \
  --i-table outputmet2/table-filtered0.qza  \
  --i-taxonomy outputmet2/taxonomy.qza \
  --p-exclude D_4__Mitochondria \
  --p-include D_ \
  --o-filtered-table outputmet2/table-filtered.qza

qiime taxa filter-seqs \
  --i-sequences outputmet2/rep-seqs-dada2.qza \
  --i-taxonomy outputmet2/taxonomy.qza \
  --p-exclude Archaea,Mitochondra,Chloroplast,Unassigned \
  --p-include D_ \
  --o-filtered-sequences outputmet2/rep-seqs-filtered0.qza

qiime taxa filter-seqs \
  --i-sequences outputmet2/rep-seqs-filtered0.qza \
  --i-taxonomy outputmet2/taxonomy.qza \
  --p-exclude D_4__Mitochondria \
  --p-include D_ \
  --o-filtered-sequences outputmet2/rep-seqs-filtered.qza

#after filtering we need to create new tables 

qiime feature-table summarize \
--i-table outputmet2/table-filtered.qza \
--o-visualization outputmet2/table-filtered.qzv \
--m-sample-metadata-file mapping/mapfile20200217t.txt


qiime feature-table tabulate-seqs \
  --i-data outputmet2/rep-seqs-filtered.qza \
  --o-visualization outputmet2/rep-seqs-filtered.qzv

#######tree for filtered
qiime phylogeny align-to-tree-mafft-fasttree \
  --i-sequences outputmet2/rep-seqs-filtered.qza \
  --o-alignment outputmet2/aligned-rep-seqs-filtered.qza \
  --o-masked-alignment outputmet2/masked-aligned-rep-seqs-filtered.qza \
  --o-tree outputmet2/unrooted-treefil.qza \
  --o-rooted-tree outputmet2/rooted-treefil.qza

#these plots are good for checking if everything is ok

qiime taxa barplot \
  --i-table outputmet2/table-filtered.qza \
  --i-taxonomy outputmet2/taxonomy.qza \
  --m-metadata-file mapping/mapfile20200217t.txt \
  --o-visualization outputmet2/filtered-taxa-bar-plots.qzv


#Ok now we will export the data to be analysed in phyloseq

#we require to export 3 elements, sample table, taxonomy file and the tree

qiime tools export \
  --input-path outputmet2/table-filtered.qza \
  --output-path filtered/exported-table

qiime tools export \
  --input-path outputmet2/taxonomy.qza \
  --output-path filtered/taxonomy

#this middle step convert them into BIOM files which can be read by R

biom convert -i filtered/exported-table/feature-table.biom -o filtered/exported-table/clampsfil.txt --header-key taxonomy --to-tsv

qiime tools export \
  --input-path outputmet2/unrooted-treefil.qza \
  --output-path filtered/exported-treefil


####### FOR UNFILTERED (same procedure)

qiime tools export \
  --input-path outputmet2/table-dada2.qza \
  --output-path unfiltered/exported-tableunf

qiime tools export \
  --input-path outputmet2/taxonomy.qza \
  --output-path unfiltered/taxonomyunf

qiime tools export \
  --input-path outputmet2/unrooted-treeunf.qza \
  --output-path unfiltered/exported-treeunf

biom convert -i unfiltered/exported-tableunf/feature-table.biom -o unfiltered/exported-tableunf/clampsunf.txt --header-key taxonomy --to-tsv

##### now we need to get the data ready for R, make sure that you are in the write WD

pwd
R


## importing the table for filtered
table<-read.csv("exported-table/clampsfil.txt",sep='\t',check.names=FALSE,skip=1)
head(table)
names(table)

## importing the taxonomy for filtered
Taxonomy<-read.table ("taxonom/taxonomy.tsv",sep='\t', header=TRUE)

head(Taxonomy)
names(Taxonomy)

###we ask R to match the lines in both tables

table$taxonomy<-with(Taxonomy,Taxon[match(table$"#OTU ID",Taxonomy$Feature.ID)])

## and we write them in a new table
write.table(table,"exported-table/leptoTaxonomy.txt",row.names=FALSE,sep="\t")

##now we can exit R
quit()
n

## we go to the WD with the newly created table and we add a couple of things so it can be read in qiime2
cd filtered/exported-table
sed -i '1s/^/# Constructed from biom file\n/' leptoTaxonomy.txt
sed -i -e 's/"//g' leptoTaxonomy.txt
ls

##optional step to check if the table looks right, won't work over ssh on a server
subl exported-table/leptoTaxonomy.txt


## and finally we can export the file in json format so we can proceed with the analysis in Phyloseq

biom convert -i exported-table/leptoTaxonomy.txt -o exported-table/leptoTaxonomy.biom --table-type "OTU table" --process-obs-metadata taxonomy --to-json



###### Now we repeat the same steps for the unfiltered data
cd ..
cd unfiltered
R
table<-read.csv("exported-tableunf/clampsunf.txt",sep='\t',check.names=FALSE,skip=1)
head(table)
names(table)
Taxonomy<-read.table ("taxonomyunf/taxonomy.tsv",sep='\t', header=TRUE)
head(Taxonomy)
names(Taxonomy)
table$taxonomy<-with(Taxonomy,Taxon[match(table$"#OTU ID",Taxonomy$Feature.ID)])
write.table(table,"exported-tableunf/leptounfTaxonomy.txt",row.names=FALSE,sep="\t")
quit()
n
sed -i '1s/^/# Constructed from biom file\n/' exported-tableunf/leptounfTaxonomy.txt
sed -i -e 's/"//g' exported-tableunf/leptounfTaxonomy.txt
ls
subl exported-tableunf/leptounfTaxonomy.txt
biom convert -i exported-tableunf/leptounfTaxonomy.txt -o exported-tableunf/leptounfTaxonomy.biom --table-type "OTU table" --process-obs-metadata taxonomy --to-json
