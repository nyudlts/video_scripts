#!/bin/bash
#
# $Id$
#
# Wrapper script for video_manifest_builder.sh 
#
echo "Reading config...." >&2
         
if [ ! -f builder_config.cfg ]; then
 echo "Config file builder_config.cfg doesn't exist. Please provide one" 
 exit 1 
fi
             
source builder_config.cfg

if [ ! -d $SOURCE_DIR ]; then
 echo "SOURCE_DIR:$SOURCE_DIR doesn't exist."  
 exit 1
fi  

declare -a VIDEOS

if [ $# -gt 0 ]; then
        if [ ! -f $1 ]; then
           echo "file $1 doesn't exist. Please check your path "
           exit 1
        fi
	readarray -t VIDEOS < $1
else
	VIDEOS=`ls $SOURCE_DIR | sort`
fi

for VIDEO in $VIDEOS
do
	echo Processing $VIDEO
	./video_manifest_builder.sh $VIDEO
	RETVAL=$?
	if [ $RETVAL -eq 0 ]; then
		STATUS=PASS
	else
		STATUS=FAIL
	fi
	echo "$VIDEO: $STATUS"
done
