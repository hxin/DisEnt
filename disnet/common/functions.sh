readcnf(){
	[  $# -eq 0 ] && echo "Usage: readcnf FILE" && exit 1;
	config=$1
	if [ -f $config ] ; then
	    . $config
	else
		echo "config file $config is missing, aborting..."
		exit 1
	fi
}

gettime(){
		echo "[$(date +"%T %D")]"
}