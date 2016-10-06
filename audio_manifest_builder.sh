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
    echo " e.g.: $0 326_1019 /content/prod/rstar/content/fales/mss326/wip/se/ fales mss326"
}

#read and check parameters
get_param () {
    local param=$(exiftool -"$2" -b -n "$1")
    echo "$param"
}

get_file_name () {
    local file_name=$(basename "$1")
    echo "${file_name}"
}

get_audio_name () {
   local audio_name=$(basename "$1")
   echo "${audio_name%_s.m4a}"
}

delete_old_manifest () {
    if [[ -f $1 ]]; then
	rm $1
    fi
}

generate_m3u8_manifest ()  {
    echo "#EXTM3U">>${M3U8_MANIFEST}
    echo "#AUDIO_ID:$2">>${M3U8_MANIFEST}
    echo ''>>${M3U8_MANIFEST}
    echo "#EXT-X-STREAM-INF:PROGRAM-ID=1,BANDWIDTH=100000">>${M3U8_MANIFEST}
    echo "">>${M3U8_MANIFEST}
    echo "${BASE_URL_HLS}/$1.m3u8">>${M3U8_MANIFEST}
    echo "">>${M3U8_MANIFEST}
}

generate_f4m_manifest () {
    echo "<?xml version=\"1.0\" encoding=\"utf-8\"?>">>${F4M_MANIFEST}
    echo "<manifest xmlns=\"http://ns.adobe.com/f4m/1.0\">">>${F4M_MANIFEST}
    echo "<id>$2</id>">>${F4M_MANIFEST}
    echo "<baseURL>${BASE_URL_HDS}</baseURL>">>${F4M_MANIFEST}
    echo "<mimeType>audio/mp4</mimeType>">>${F4M_MANIFEST}
    echo "<media url=\"mp4:$1\" />">>${F4M_MANIFEST}
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
    echo "AUDIO_DIR:${AUDIO_DIR}" 

#define variables 
BASE_URL_HDS=rtmp://${AUDIO_SERVER_NAME}/${APP_NAME}
BASE_URL_HLS=http://${AUDIO_SERVER_NAME}/hls-vod/audio-only-aac/${APP_NAME_HLS}

#iterate over audio files in the directory
for f in  ${AUDIO_DIR}/*_s.m4a
do
    fr=$(get_file_name "$f")
    a_name=$(get_audio_name "$fr") 
    #define variables
    M3U8_MANIFEST=${AUDIO_DIR}/"$a_name"_"$M3U8"
    F4M_MANIFEST=${AUDIO_DIR}/"$a_name"_"$F4M"
    #generate hls manifest file- extention u8m3
    delete_old_manifest ${M3U8_MANIFEST}
    generate_m3u8_manifest "$fr" "$a_name"
    #generates hds manifest file - extention f4m 
    delete_old_manifest ${F4M_MANIFEST}
    generate_f4m_manifest "$fr" "$a_name"
done
