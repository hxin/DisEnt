#!/bin/sh
BASEDIR=$(dirname $0)


functions=$BASEDIR/../../common/functions.sh
scripts=$BASEDIR/scripts
tmp=$BASEDIR/tmp
chunks=$tmp/chunks
data=$BASEDIR/data


human_geneinfo=$BASEDIR/tmp/Homo_sapiens.gene_info.gz
gene_hist=$BASEDIR/tmp/gene_history.gz

config_g=$BASEDIR/../../config.cnf
config_l=$BASEDIR/config.cnf

##load functions
if [ -f $functions ];then
	. $functions
else
   	echo "$functions is missing, aborting..."
   	exit 1;
fi

##read config file
readcnf $config_g && readcnf $config_l

##create/clean tmp folder
[ ! -d $tmp ] && mkdir $tmp || [ $cleantmp = 'y' ] && rm -rf $tmp/*
[ ! -d $chunks ] && mkdir $chunks || [ $cleanchunks = 'y' ] && rm -rf $chunks/*
[ ! -d $data ] && mkdir $data || [ $cleandata = 'y' ] && rm -rf $data/*

if [ $checkupdate = 'y' ];then 
	
	##e2e
	echo "[$(date +"%T %D")] Checking update for entrez2ensembl mapping data..."
	( [ -n "$(cd $tmp/; wget -N --spider $e2e_url 2>&1 | grep 'exists')" ] && exit 1; exit 0; )
	##1 needs update, 0 don't.
	if [ $? -eq 0 ];then
		echo "[$(date +"%T %D")] No available update!"
	else
		echo "[$(date +"%T %D")] Update available..."
		echo "[$(date +"%T %D")] Fetching from $e2e_url..." 
		(cd $tmp/ && wget -nv -N $e2e_url)
		chmod 664 $tmp/gene2ensembl.gz
		echo "[$(date +"%T %D")] Parsing ..."
		zcat $tmp/gene2ensembl.gz | cut -f 1,2,3 | tail -n+2 > $tmp/ENTREZ_entrez2ensembl
	fi

	##huamn gene info
	echo "[$(date +"%T %D")] Checking update for human_geneinfo data..."
	( [ -n "$(cd $tmp/; wget -N --spider $human_geneinfo_url 2>&1 | grep 'exists')" ] && exit 1; exit 0; )
	##1 needs update, 0 don't.
	if [ $? -eq 0 ];then
		echo "[$(date +"%T %D")] No available update!"
	else
		echo "[$(date +"%T %D")] Update available..."
		echo "[$(date +"%T %D")] Fetching from $H_GENEINFO..." 
		(cd $BASEDIR/tmp/ && wget -nv -N $ENTREZ_HUMAN_GENEINFO_URL)
		chmod 664 $H_GENEINFO
		echo "[$(date +"%T %D")] Parsing..."
		zcat $H_GENEINFO | cut -f 2 | tail -n+2 > $BASEDIR/tmp/ENTREZ_human_gene
	fi

	echo "[$(date +"%T %D")] Checking update for gene history data..."
	( [ -n "$(cd $BASEDIR/tmp/; wget -N --spider $ENTREZ_GENE_HISTORY_URL 2>&1 | grep 'exists')" ] && exit 1; exit 0; )
	##1 needs update, 0 don't.
	if [ $? -eq 0 ];then
		echo "[$(date +"%T %D")] No available update!"
	else
		NEED_UPDATE_DB=1
		echo "[$(date +"%T %D")] Update available..."
		echo "[$(date +"%T %D")] Fetching from $ENTREZ_GENE_HISTORY_URL..." 
		(cd $BASEDIR/tmp/ && wget -nv -N $ENTREZ_GENE_HISTORY_URL)
		chmod 664 $GENE_HISTORY
		echo "[$(date +"%T %D")] Parsing..."
		zgrep "^9606" $GENE_HISTORY > $BASEDIR/tmp/ENTREZ_gene_history
	fi
fi

echo "[$(date +"%T %D")] Result:"
for result in $(find $data -type f); do 
	echo ''
	echo $result
	head -2 $result
done



exit 0;
