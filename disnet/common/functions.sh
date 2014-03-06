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

preview(){
		[  $# -eq 0 ] && echo "Usage: preview DIR" && exit 1;
		$dir=$1;	
		if [ -d $config ] ; then
			echo $(gettime)" Result in $dir:"
			echo '#############################################################'						
	    	for line in $(find $dir -type f); do
				echo $line
				head -2 $line
				echo '#############################################################'
			done
		else
			echo "$dir is not a valid folder!"
			exit 1
		fi
}