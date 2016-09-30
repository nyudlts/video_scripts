#!/bin/bash

## The script is used to generate manifest files for dynamic streaming of DLTS audio. generates manifest files for hls (mobile) and hds streaming.Use filename as a parameter.   

readonly REQUIRED_ARGUMENT_COUNT=4
readonly AUDIO_SERVER_NAME=ams.library.nyu.edu
readonly M3U8=manifest.m3u8
readonly F4M=manifest_rtmp.f4m

print_error () {
    echo "ERROR: $@" >&2
}

print_usage () {
    echo "usage: $0 <audio id> <audio dir> <partner code> <collection code>"
    echo " e.g.: $0 326_1019_00002 /content/prod/rstar/content/fales/mss326/wip/se/326_0071_00001/aux fales mss326"
}

#read and check parameters
get_param () {
    local param=$(exiftool -"$2" -b -n "$1")
    echo "$param"
}

get_file_name () {
    local file_name=$(basename "$1")
    echo "$file_name"
}

delete_old_manifest () {
    if [[ -f $1 ]]; then
	rm $1
    fi
}

generate_m3u8_manifest () {
    echo "#EXTM3U">>${M3U8_MANIFEST}
    echo "#AUDIO_ID:${AUDIO_ID}">>${M3U8_MANIFEST}
    echo ''>>${M3U8_MANIFEST}
    for f in  ${AUDIO_DIR}/${AUDIO_ID}_s.m4a
    do
	fr=$(get_file_name "$f")
	echo "#EXT-X-STREAM-INF:PROGRAM-ID=1,BANDWIDTH=100000">>${M3U8_MANIFEST}
	echo "">>${M3U8_MANIFEST}
	echo "${BASE_URL_HLS}/$fr.m3u8">>${M3U8_MANIFEST}
	echo "">>${M3U8_MANIFEST}
    done
}

generate_f4m_manifest () {
    echo "<?xml version=\"1.0\" encoding=\"utf-8\"?>">>${F4M_MANIFEST}
    echo "<manifest xmlns=\"http://ns.adobe.com/f4m/1.0\">">>${F4M_MANIFEST}
    echo "<id>${AUDIO_ID}</id>">>${F4M_MANIFEST}
    echo "<baseURL>${BASE_URL_HDS}</baseURL>">>${F4M_MANIFEST}
    echo "<mimeType>audio/mp4</mimeType>">>${F4M_MANIFEST}
    for f in  ${AUDIO_DIR}/${AUDIO_ID}_s.m4a
    do
	fr=$(get_file_name "$f")
	echo "<media url=\"mp4:${fr%.mp4}\" />">>${F4M_MANIFEST}
    done
    echo "</manifest>">>${F4M_MANIFEST}
}

#read and validate parameters
if [[ "$#" -ne ${REQUIRED_ARGUMENT_COUNT} ]]; then
    print_error "incorrect argument count"
    print_usage
    exit 1
fi
AUDIO_ID="$1"
AUDIO_DIR="$2"
PARTNER_CODE="$3"
COLLECTION_CODE="$4"
APP_NAME="${PARTNER_CODE}_${COLLECTION_CODE}"
APP_NAME_HLS="${PARTNER_CODE}/${COLLECTION_CODE}"

if [[ ! -d ${AUDIO_DIR} ]]; then
    echo "AUDIO_DIR:${AUDIO_DIR} doesn\'t exist." 
    exit 1
fi

#define variables 
M3U8_MANIFEST=${AUDIO_DIR}/"${AUDIO_ID}"_"$M3U8"
F4M_MANIFEST=${AUDIO_DIR}/"${AUDIO_ID}"_"$F4M"
BASE_URL_HDS=rtmp://${AUDIO_SERVER_NAME}/${APP_NAME}
BASE_URL_HLS=http://${AUDIO_SERVER_NAME}/hls-vod/audio-only-aac/${APP_NAME_HLS}

#generate hls manifest file- extention u8m3
delete_old_manifest ${M3U8_MANIFEST}
generate_m3u8_manifest

#generates hds manifest file - extention f4m 
delete_old_manifest ${F4M_MANIFEST}
generate_f4m_manifest

