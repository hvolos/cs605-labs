#!/bin/bash

if [[ -z "$1" || -z "$2" || -z "$3" || -z "$4" ]]; then

echo "Please enter number of indexes, number of partitions , outputBaseDir and indexServerHostNames per partition e.g. 2 /home/zhadji01/nutch-test/28GBindexesCopies Nicocluster5"

exit
fi

indexes=$1
partitions=$2
mountpoint=$3
#((multiply=num+1))
#((MBtoReserver=227*multiply))

script="/local/websearch/scripts/custom_index_generation.sh"

curDir=`pwd`
cd $mountpoint
baseDir=`pwd`
cd $curDir

declare -A hosts

args=("$@")
args_length=$#

#index=2
index=3
i=0
while [ $index -lt $args_length ];  
do	
	hosts[$i]=${args[$index]}
	((index++))
	((i++))
done

hosts_size=${#hosts[@]}
if [ $hosts_size -ne $partitions ]; then
	echo "error exiting. The hosts array size must be equal to partitions"
	exit
fi

inputDir=/mydata/4GBindex
hardLinks=2
part=0
indexesPerPart=`echo "${indexes} / $partitions" | bc`


declare -A sshPids
while [ $part -lt $partitions ]; 
do
		MBtoReserver=0
		outDir="$baseDir"/"$partitions"_"$part"		
		((added_base = part * indexesPerPart))	
		added=$added_base
		
		count=0
		while [ $count -lt $indexesPerPart ]; 
		do
								
			((added=added_base+count))
			
			if [ $count -eq 0 ]; then
				toAdd="$added"
			else
				toAdd="$toAdd $added"
			fi	
			
			if [ $added -lt 10 ]; then
				file=part-0000"$added"
			elif [ $added -lt 100 ]; then
				file=part-000"$added"
			else
				file=part-00"$added"
			fi
			#echo $added
			addToSize=`du -m $inputDir/indexes/$file | awk '{print $1}'`
			((MBtoReserver=MBtoReserver+addToSize))
			((count++))
			#echo $addToSize
		done
		#exit
		#echo $toAdd
		#echo $MBtoReserver
		#exit;
		((MBtoReserver=MBtoReserver+10))
   echo "$MBtoReserver"
   echo "$outDir"
   mkdir $outDir
		ssh  ${hosts[$part]} "sudo mkdir -p $outDir; sudo mount -t tmpfs -o size="$MBtoReserver"m,mpol=bind:0 tmpfs $outDir;$script $outDir $inputDir $hardLinks $toAdd; exit;" &
		sshPids[$part]=$!		
		#echo "$script $outDir $inputDir $toAdd"
		((part++))
done

for pid in "${sshPids[@]}"
do
	wait $pid
done

exit;

#part=0
count=0
#part=""

while [ $count -le $num ];
do
	if [ $count -eq 0 ]; then
		part="$count"
	else
		part="$part $count"
	fi
	
	if [ $count -lt 10 ]; then
		file=part-0000"$count"
	elif [ $count -lt 100 ]; then
		file=part-000"$count"
	else
		file=part-00"$count"
	fi
	addToSize=`du -m $inputDir/indexes/$file | awk '{print $1}'`
	((MBtoReserver=MBtoReserver+addToSize))
	outDir="$baseDir"/28GB_"$count"
	#mkdir $outDir
	#echo "$part"
	
	((test=num))
	if [ $test -eq $count ]; then
		mkdir -p $outDir
		((MBtoReserver=MBtoReserver+10))
		#echo "Mb to reserve $MBtoReserver"
		#exit
		mount -t tmpfs -o size="$MBtoReserver"m,mpol=bind:0,1 tmpfs $outDir
		$script $outDir $inputDir $hardLinks $part
	fi
	
	((count++))
done

exit;
