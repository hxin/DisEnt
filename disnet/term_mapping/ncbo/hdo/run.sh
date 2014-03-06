#!/bin/sh
BASEDIR=$(dirname $0)


usage(){
	echo "!!"
	echo "!!Usage: $0 -i INPUT -o OUTPUT;"
	echo "!!input should be tab seperated and looks like this:"
	echo "!!gene_id	disease_id	disease_description	other_references"
	echo "!!"
}




##main


if [ ! $# -eq 0 ] ; then
	while [ "$1" != "" ]; do
	    case $1 in
	        -i | --input )          shift
	                                in=$1
	                                ;;
	        -o | --output )  		shift
	        						out=$1
	                                ;;
	        -h | --help )           usage
	                                exit
	                                ;;
	        * )                    	usage		
	                                exit 1
    	 esac
    shift
	done 
else
	#in=$BASEDIR/data/in
	#out=$BASEDIR/data/out
	while read LINE; do
		echo ${LINE} >>  /tmp/1.tmp
	done
	in=/tmp/1.tmp	
fi

functions=$BASEDIR/../../../common/functions.sh
scripts=$BASEDIR/scripts
tmp=$BASEDIR/tmp
chunks=$tmp/chunks

config_g=$BASEDIR/../../../config.cnf
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

echo "[$(date +"%T %D")] First line of your input file: " | tee -a $log
head -1 $in | tee -a $log
echo "[$(date +"%T %D")] Start chunking files..." | tee -a $log
echo "	[$(date +"%T %D")] Create/Empty chunk folder..." | tee -a $log
[ ! -d $tmp ] && mkdir $tmp || [ $cleantmp = 'y' ] && rm -rf $tmp/*
[ ! -d $chunks ] && mkdir $chunks || [ $cleanchunks = 'y' ] && rm -rf $chunks/*

echo "	[$(date +"%T %D")] Chunking file..."| tee -a $log 
if [ $testrun = 'y' ]; then
	(head -100 $in >$chunks/source && cd $chunks && split -n l/5 -a 3 -d ./source chunk_ && rm -f ./source)
else
	(cat $in >$chunks/source && cd $chunks && split -n l/5 -a 3 -d ./source chunk_ && rm -f ./source)
fi

#ls $chunks
echo "[$(date +"%T %D")] Start NCBO mapping..."| tee -a $log
for line in $(find $chunks -iname 'chunk_*'); do
	if [ $debug = 'y' ]; then
		perl $BASEDIR/ncbo.pl $line & 
	else
		perl $BASEDIR/ncbo.pl $line > $line'_parsed' &
	fi
done
echo "	[$(date +"%T %D")] Waiting for process to be finished..."| tee -a $log
wait

echo "	[$(date +"%T %D")] Finish!"| tee -a $log
echo "[$(date +"%T %D")] Joining result..."| tee -a $log
echo 	"[$(date +"%T %D")] Done..."| tee -a $log
for line in $(find $chunks -iname 'chunk_*_parsed'); do 
	cat $line >> $chunks/all	
done
[ -n $out ] && cp $chunks/all $out || cat $chunks/all

exit 0;