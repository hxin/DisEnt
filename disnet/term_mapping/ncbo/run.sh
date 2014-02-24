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

##config file,read global first, everything in local will over write global
config_g=$BASEDIR/../../../config.cnf
config_l=$BASEDIR/config.cnf

if [ -f $config_g ] ; then
    . $config_g
else
	echo "config file $config_g is missing, aborting..." | tee -a $log
	exit 1
fi

if [ -f $config_l ] ; then
    . $config_l
else
	echo "config file $config_l is missing, aborting..." | tee -a $log
	exit 1
fi


if [ ! $# -eq 0 ] ; then
	while [ "$1" != "" ]; do
	    case $1 in
	        -i | --input )          shift
	                                in=$1
	                                ;;
	        -o | --output )  		out=$1
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
	in=$BASEDIR/data/in
	out=$BASEDIR/data/out
	#usage
	#exit 1
fi


chunk=$BASEDIR/tmp/chunks

[ ! -d $BASEDIR/tmp ] && mkdir $BASEDIR/tmp;
[ ! -d $BASEDIR/data ] && mkdir $BASEDIR/data;
echo "[$(date +"%T %D")] Start chunking files..." | tee -a $log
echo "	[$(date +"%T %D")] Create/Empty chunk folder..." | tee -a $log
( [ -d $chunk ] && rm -f $chunk/* ) || mkdir $BASEDIR/tmp/chunks;
echo "	[$(date +"%T %D")] Chunking file..."| tee -a $log 
if [ $test = 'y' ]; then
	(head -100 $in >$chunk/source && cd $chunk && split -n l/5 -a 3 -d ./source chunk_ && rm -f ./source)
else
	(cat $in >$chunk/source && cd $chunk && split -n l/5 -a 3 -d ./source chunk_ && rm -f ./source)
fi

#ls $chunk
echo "[$(date +"%T %D")] Start NCBO mapping..."| tee -a $log
for line in $(find $chunk -iname 'chunk_*'); do
	if [ $test = 'y' ]; then
		perl $BASEDIR/ncbo.pl $line & 
	else
		perl $BASEDIR/ncbo.pl $line > $line'_parsed' &
	fi
done
echo "	[$(date +"%T %D")] Waiting for process to be finished..."| tee -a $log
wait
[ $test= 'y' ] && exit 0;

echo "	[$(date +"%T %D")] Finish!"| tee -a $log
echo "[$(date +"%T %D")] Joining result..."| tee -a $log
echo 	"[$(date +"%T %D")] Done..."| tee -a $log
for line in $(find $chunk -iname 'chunk_*_parsed'); do 
	cat $line >> $chunk/all	
done
cp $chunk/all $out

exit 0;