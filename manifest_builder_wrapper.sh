#!/bin/bash
#
# $Id$
#
# Wrapper script for video_manifest_builder.sh 
#
#------------------------------------------------------------------------------
global_status=0

# determine script path
SCRIPT_DIR="${BASH_SOURCE%/*}"
if [[ ! -d "$SCRIPT_DIR" ]]; then SCRIPT_DIR="$PWD"; fi

readonly CONFIG_FILE="${SCRIPT_DIR}/builder_config.cfg"
readonly MANIFEST_SCRIPT="${SCRIPT_DIR}/video_manifest_builder.sh"

echo "Reading config...." >&2
         
if [[ ! -f ${CONFIG_FILE} ]]; then
 echo "Config file builder_config.cfg doesn't exist. Please provide one" 
 exit 1 
fi
             
source "${CONFIG_FILE}"

if [[ ! -d "${SOURCE_DIR}" ]]; then
 echo "SOURCE_DIR:${SOURCE_DIR} doesn't exist."  
 exit 1
fi  

declare -a VIDEOS

if [[ $# -gt 0 ]]; then
        if [[ ! -f $1 ]]; then
           echo "file $1 doesn't exist. Please check your path "
           exit 1
        fi
	readarray -t VIDEOS < $1
else
	VIDEOS=$(ls $SOURCE_DIR | sort)
fi

for video in $VIDEOS
do
	echo "Processing ${video}"
	${MANIFEST_SCRIPT} "${video}"
	retval=$?
	if [[ "${retval}" -eq 0 ]]; then
		status='PASS'
	else
		status='FAIL'
		global_status=1
	fi
	echo "${video}: ${status}"
done

exit "$global_status"
