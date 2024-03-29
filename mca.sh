#!/bin/bash

# Expand aliases
shopt -s expand_aliases

# Check Python version
pversion=`python -c 'import sys; print(".".join(map(str, sys.version_info[:3])))' | cut -d"." -f1`
if [ $pversion == 2 ]; then
	alias urldecode='python -c "import urllib, sys; print urllib.unquote(sys.argv[1] if len(sys.argv) > 1 else sys.stdin.read()[0:-1])"'
elif [ $pversion == 3 ]; then
	alias urldecode='python -c "import sys, urllib.parse as ul; print(ul.unquote(sys.argv[1] if len(sys.argv) > 1 else sys.stdin.read()[0:-1]))"'
else
	echo "make sure you have python installed!"
fi

# Check if "yq" is installed
which yq &> /dev/null
if [ $? -ne 0 ]; then
	echo "Please install "yq" first: # pip install yq"
fi

function checkfile() {
	type=`cat $1 2> /dev/null | yq .kind | sed 's/"//g'`
        if [ "$type" != MachineConfig ] ; then
		return 1
	else
		return 0
	fi
}

function decode() {
	echo -e "\e[1m.... decoding $1\e[0m"
	echo ""
       	mkdir $dir 2> /dev/null
	# separating files that are using url encoding
	urlencodedfiles=`cat $1 | yq '.spec.config.storage.files[] | select((.contents.source != "data:,") and (.contents.source | contains(";base64,") | not )).path' | sed 's/"//g'`
	for y in $urlencodedfiles ; do filename=`echo $y | rev | cut -d '/' -f 1 | rev` ; cat $1 | yq --arg path "$y" '.spec.config.storage.files[] | select(.path == $path).contents.source' | urldecode | sed '1 s/"data:,//' | sed '$s/^.*$//' | sed '${/^$/d;}' > $dir/$filename ; done

	# separating files that are using base64 encoding
	base64files=`cat $1 | yq '.spec.config.storage.files[] | select((.contents.source != "data:,") and (.contents.source | contains(";base64,"))).path' | sed 's/"//g'`
       	for y in $base64files ; do filename=`echo $y | rev | cut -d '/' -f 1 | rev` ; cat $1 | yq --arg path "$y" '.spec.config.storage.files[] | select(.path == $path).contents.source' | sed -e 's/.*base64,\(.*\)"/\1/' | base64 -d | sed '1 s/"data:,//' | sed '$s/^.*$//' | sed '${/^$/d;}' > $dir/$filename ; done

	# Separating services units configurations that are usually in clear text
    	units=`cat $1 | yq '.spec.config.systemd.units[] | select(.contents != null).name' | sed 's/"//g'`
	mkdir $dir/service-units/ 2> /dev/null
	for x in $units ; do cat $1 | yq -r --arg z "$x" '.spec.config.systemd.units[] | select(.contents != null) | select(.name == $z).contents' | sed '${/^$/d;}' > $dir/service-units/$x ; done
}

function compare() {
	echo -e "\e[1mDecoding $1 and $2 MachineConfig files first\e[0m"
	echo ""
        for i in $1 $2 ; do
               name=`cat $i 2> /dev/null | yq .metadata.name | sed 's/"//g'`
               creationtime=`cat $i 2> /dev/null  | yq .metadata.creationTimestamp | sed 's/"//g'`
               dir="$name-$creationtime"
               decode "$i"
        done
        dir1=`cat $1 | yq '.metadata | .name, .creationTimestamp' | sed 's/"//g' | paste -d "-"  - -`
        dir2=`cat $2 | yq '.metadata | .name, .creationTimestamp' | sed 's/"//g' | paste -d "-"  - -`
        echo -e "\e[1mComparing configuration files between $1 and $2\e[0m"
	diff=`diff -q $dir1/ $dir2/ | sort`
        echo -e "\e[1;43mUnique files existing only in $1 MachineConfig:\e[0m"
	echo ""
        echo "$diff" | grep Only | grep $dir1
	echo ""
        echo -e "\e[1;43mUnique files existing only in $2 MachineConfig:\e[0m"
	echo ""
        echo "$diff" | grep Only | grep $dir2
        echo ""
	echo -e "\e[1;43mFiles existing in both MachineConfig files $1 and $2 but differ in contents:\e[0m"
	echo ""
        echo "$diff" | grep differ | awk '{print $2}' | cut -d "/" -f2
	echo ""
	echo "=============================================================="
        echo -e "\e[1mComparing services configurations between $1 and $2\e[0m"
	diff=`diff -q $dir1/service-units/ $dir2/service-units/ | sort`
        echo -e "\e[1;43mUnique services configurations existing only in $1 MachineConfig:\e[0m"
	echo ""
        echo "$diff" | grep Only | grep $dir1
	echo ""
        echo -e "\e[1;43mUnique services configurations existing only in $2 MachineConfig:\e[0m"
	echo ""
        echo "$diff" | grep Only | grep $dir2
        echo ""
	echo -e "\e[1;43mServices configurations existing in both MachineConfig files $1 and $2 but differ in contents:\e[0m"
	echo ""
        echo "$diff" | grep differ | awk '{print $2}' | cut -d "/" -f3
	echo ""
}

function extract() {
	# check if the provided file path exists in the MachineConfig file
	configfile=`cat $mcfile | yq --arg conf "$1" '.spec.config.storage.files[] | select(.path == $conf)' | yq .contents.source`
	if [ -z $configfile ]; then
		echo -e "\e[1;33mWARNING:\e[0m $1 doesn't exist in $mcfile MahineConfig. Please make sure to use the full path"
	else
		echo $configfile | urldecode | sed '1 s/"data:,//' | sed '$ d' > $dir/`echo $1 | rev | cut -d '/' -f 1 | rev`
		echo "$1 got extracted"
	fi
}

# show description of each option
if [[ "$1" == "help" || "$1" == "--help"|| "$1" == "-h" || "$#" == 0 ]]; then
	echo "==============================================================================================================="
	echo "A tool to decode MachineConfig YAML failes into a readable format and extracts configurations data of each file"
	echo "==============================================================================================================="
        echo "
USAGE: ./decode-mc.sh <operation> <MachineConfig file1> <MachineConfig file2> ....

OPTIONS:
       	decode, --decode, -d: 
		Can take multiple MachineConfig files to decode them into a readable files and extract the configurations from each one.
               	Each provides MachineConfig file will result in a newly created direcory for it. This directory will have the actual name.
               	of the provided MachineConfig file.
	
	compare, --compare, -c:
		Will try to find different files that have been extracted from each MachineConfig "this option will rely on the native 'diff' command".
		It will always compare between the first two MachineConfig files, so a third or fourth or ... arguments will be neglected.
        extract, --extract, -e:
		Specify full file path to be extracted from the MachineConfig files instead of extracting everything from it.
	"
elif [[ "$1" == "decode" || "$1" == "--decode" || "$1" == "-d" ]]; then
	# skipping the first argument "operation"
	shift
	if [ $# -eq 0 ]; then
		echo "Please provide MachineConfig files to decode"
		exit
	else
		for i in $@ ; do
			checkfile "$i"
			if [ $? -eq 0 ]; then
				name=`cat $i 2> /dev/null | yq .metadata.name | sed 's/"//g'`
       		 		creationtime=`cat $i 2> /dev/null  | yq .metadata.creationTimestamp | sed 's/"//g'`
	       	 		dir="$name-$creationtime"
				decode "$i"
				echo "Check $i data under $dir directory"
			else
				echo "$i is not a valid MachineConfig file"
        	        	exit 1
			fi

		done
	fi
elif [[ "$1" == "compare" || "$1" == "--compare" || "$1" == "-c" ]]; then
	# skipping the first argument "operation"
	shift
	if [ $# -lt 2 ]; then
		echo "Please provide two MachineConfig files to compare"
		exit
	elif [ $1 == $2 ]; then
		echo "Both MachineConfig files have the same name!"
		exit 1
	else
		for i in $1 $2 ; do
			checkfile "$i"
			if [ $? -ne 0 ]; then
				echo "$i is not a valid MachineConfig file"
				exit
			fi
		done
		compare $1 $2
	fi
elif [[ "$1" == "extract" || "$1" == "--extract" || "$1" == "-e" ]]; then
	checkfile $2
	if [ $? -eq 0 ]; then
		mcfile=$2
		name=`cat $2 2> /dev/null | yq .metadata.name | sed 's/"//g'`
        	creationtime=`cat $2 2> /dev/null  | yq .metadata.creationTimestamp | sed 's/"//g'`
		dir="$name-$creationtime"
		shift
		shift
		pass="0"
		for i in $@ ; do
			configfile=`cat $mcfile | yq --arg conf "$i" '.spec.config.storage.files[] | select(.path == $conf)' | yq .contents.source`
			if [ -z $configfile ]; then
				pass=$pass
			else
				pass=1
			fi
		done
		if [ "$pass" -ne 0 ]; then
			mkdir -p $dir/ 2> /dev/null
			for i in $@ ; do
				extract $i
			done
			echo -e "Check extracted configuration files under \e[34m$dir/\e[0m"
		else
			echo "None of the provided files exists in $mcfile"
		fi
	 else
        		echo "$2 is not a valid MachineConfig file"
	        exit 1
        fi

else
	echo "$1 is not a valid option, choose either "decode" , "compare" or "extract""
fi
