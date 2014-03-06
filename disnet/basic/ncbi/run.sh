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

	
##e2e
echo $(gettime)" Checking update for entrez2ensembl mapping data..."
( [ -n "$(cd $tmp/; wget -N --spider $e2e_url 2>&1 | grep 'exists')" ] && exit 1; exit 0; )
##1 needs update, 0 don't.
if [ $? -eq 0 ];then
	echo $(gettime)" No available update!"
else
		echo $(gettime)" Update available..."
		echo $(gettime)" Fetching from $e2e_url..." 
		(cd $tmp/ && wget -nv -N $e2e_url)
		chmod 664 $tmp/gene2ensembl.gz
fi
echo $(gettime)" Parsing ..."
zcat $tmp/gene2ensembl.gz | cut -f 1,2,3 | tail -n+2 > $data/entrez2ensembl

echo $(gettime)" Checking update for gene history data..."
( [ -n "$(cd $BASEDIR/tmp/; wget -N --spider $gene_hist_url 2>&1 | grep 'exists')" ] && exit 1; exit 0; )
##1 needs update, 0 don't.
if [ $? -eq 0 ];then
		echo $(gettime)" No available update!"
	else
		echo $(gettime)" Update available..."
		echo $(gettime)" Fetching from $gene_hist_url..." 
		(cd $BASEDIR/tmp/ && wget -nv -N $gene_hist_url)
		chmod 664 $tmp/gene_history.gz	
	fi
echo $(gettime)" Parsing..."
zgrep "^9606" $tmp/gene_history.gz > $data/gene_history_entrez


echo '****************Result****************'
for result in $(find $data -type f); do
	echo  $result Count:`wc -l $result | cut -d ' ' -f1`
	head -2 $result
	echo ...
	echo '#############################################################'
done

echo $(gettime)" Updating db..."
mysqlimport -h $host -u $user -p$psw --delete -L $db $data/entrez2ensembl
mysqlimport -h $host -u $user -p$psw --delete -L $db $data/gene_history_entrez


exit 0;
