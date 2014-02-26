#!/bin/sh
BASEDIR=$(dirname $0)


functions=$BASEDIR/../../common/functions.sh
scripts=$BASEDIR/scripts
tmp=$BASEDIR/tmp
chunks=$tmp/chunks
data=$BASEDIR/data

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
	
	#######fetch human gene
	echo "[$(date +"%T %D")] Fetching human gene..."
	[ $human_gene = 'y' ] && perl $scripts/fetch_human_gene.pl > $tmp/ENSEMBL_human_gene

	#######fetch homolog
	#######chunk human gene file and and a batch query 
	if [ $homolog = 'y' ];then
		echo "[$(date +"%T %D")] Prepare for homolog/orthology mapping of all human gene..."
		echo "	[$(date +"%T %D")] Create/Empty chunk folder..."
		( [ -d $chunks ] && rm -f $chunks/* ) || mkdir $BASEDIR/tmp/chunks;
		
		echo "	[$(date +"%T %D")] Chunking file..."
		if [ $testrun = 'y' ];then
			head -50 $tmp/ENSEMBL_human_gene > $chunks/ENSEMBL_human_gene
			printf "ENSG00000000457\t13\t23708313\t23708703" >> $chunks/ENSEMBL_human_gene
		else
			cp $tmp/ENSEMBL_human_gene $chunks/ENSEMBL_human_gene
		fi
		
		`cd $chunks && split -n l/$ensembl_chunk_number -a 3 -e -d ENSEMBL_human_gene chunk_`
		#ls $chunks

		echo "[$(date +"%T %D")] Fetching homologs, this may take hours...(2h for fly) UNCOMMENT!!!!!HERE!!!!!!!!!!!!!!!!!!!!!!!!!!!"
		for line in $(find $chunks -iname 'chunk_*'); do 
		    perl $scripts/fetch_homolog.pl $species $line > ${line}_parsed &
		done

		echo "	[$(date +"%T %D")] Waiting for process to be finished..."
		wait
		echo "	[$(date +"%T %D")] Joining result..."
		for line in $(find $chunks -iname 'chunk_*_parsed'); do 
		     cat $line >> $chunks/all
		done
		cp $chunks/all $chunks/../ENSEMBL_human_homolog
		
		
		
		##copy to data
		cp $tmp/ENSEMBL_human_homolog $data/ENSEMBL_human_homolog
		cp $tmp/ENSEMBL_human_gene $data/ENSEMBL_human_gene
		echo "	[$(date +"%T %D")] Finish!"
	fi
fi

echo "[$(date +"%T %D")] Result:"
for result in $(find $data -type f); do 
	echo ''
	echo $result
	head -2 $result
done



exit 0;
