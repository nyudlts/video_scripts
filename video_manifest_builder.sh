#!/bin/bash

## The script is used to generate manifest files for dynamic streaming
## of DLTS video. generates manifest files for hls (mobile) and hds
## streaming.Use filename as a parameter.

readonly REQUIRED_ARGUMENT_COUNT=4
readonly VIDEO_SERVER_NAME=ams.library.nyu.edu
readonly M3U8=manifest.m3u8
readonly F4M=manifest_rtmp.f4m

print_error () {
    echo "ERROR: $@" >&2
}

print_usage () {
    echo "usage: $0 <video file prefix> <streaming file dir> <partner code> <collection code>"
    echo " e.g.: $0 231_0710 /content/prod/rstar/content/fales/gcn/wip/se/231_0710/aux fales gcn"
    echo " e.g.: $0 AD-MC023_ref1_A /content/prod/rstar/content/nyuad/ad_mc023/wip/se/AD-MC023_ref1/aux nyuad ad_mc023"
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

# need to deal with filenames with different numbers of leading underscores,
# e.g., 
#   TAM-616_ref100_142k_mobile_s.mp4
#   AD-MC023_ref1_A_1232k_mobile_s.mp4
# 
# to compensate for this variability, the string is reversed, parsed,
# then reversed back
get_bitrate_mobile () {
    local bitrate=$( echo $1 | rev | cut -d'_' -f3 | rev )
    echo "$bitrate"
}

# need to deal with filenames with different numbers of leading underscores,
# e.g., 
#   TAM-616_ref100_1520k_s.mp4
#   AD-MC023_ref1_A_1520k_s.mp4
# 
# to compensate for this variability, the string is reversed, parsed,
# then reversed back
get_bitrate () {
    local bitrate=$( echo $1 | rev | cut -d'_' -f2 | rev )
    echo "$bitrate"
}

delete_old_manifest () {
    if [[ -f $1 ]]; then
	rm $1
    fi
}

generate_m3u8_manifest () {
    echo "#EXTM3U">>${M3U8_MANIFEST}
    echo "#VIDEO_ID:${VIDEO_ID}">>${M3U8_MANIFEST}
    echo ''>>${M3U8_MANIFEST}
    for f in  ${VIDEO_DIR}/${VIDEO_ID}_*k_mobile_s.mp4
    do
	fr=$(get_file_name "$f")
	br=$(get_bitrate_mobile "$fr")
	resolution=$(get_param $f "ImageHeight")x$(get_param $f "ImageWidth")
	br_i=$((1000*(${br%k}-32)))
	echo "#EXT-X-STREAM-INF:PROGRAM-ID=1,BANDWIDTH=$br_i,RESOLUTION=$resolution">>${M3U8_MANIFEST}
	echo "">>${M3U8_MANIFEST}
	echo "${BASE_URL_HLS}/$fr.m3u8">>${M3U8_MANIFEST}
	echo "">>${M3U8_MANIFEST}
    done
}

generate_f4m_manifest () {
    echo "<?xml version=\"1.0\" encoding=\"utf-8\"?>">>${F4M_MANIFEST}
    echo "<manifest xmlns=\"http://ns.adobe.com/f4m/1.0\">">>${F4M_MANIFEST}
    echo "<id>${VIDEO_ID}</id>">>${F4M_MANIFEST}
    echo "<baseURL>${BASE_URL_HDS}</baseURL>">>${F4M_MANIFEST}
    echo "<mimeType>video/mp4</mimeType>">>${F4M_MANIFEST}
    for f in  ${VIDEO_DIR}/${VIDEO_ID}_*k_s.mp4
    do
	fr=$(get_file_name "$f")
	br=$(get_bitrate "$fr")
	width=$(get_param $f "ImageWidth")
	height=$(get_param $f "ImageHeight")
	br_i=$((${br%k}))
	echo "<media url=\"mp4:${fr%.mp4}\" width=\"$width\" height=\"$height\" bitrate=\"$br_i\"/>">>${F4M_MANIFEST}
    done
    echo "</manifest>">>${F4M_MANIFEST}
}

#check that we are on Linux (it won't work on Mac)
if [[ $(uname) != 'Linux' ]]; then
    echo "ERROR: script only supported on Linux" >&2
    exit 1
fi

#read and validate parameters
if [[ "$#" -ne ${REQUIRED_ARGUMENT_COUNT} ]]; then
    print_error "incorrect argument count"
    print_usage
    exit 1
fi
VIDEO_ID="$1"
VIDEO_DIR="$2"
PARTNER_CODE="$3"
COLLECTION_CODE="$4"
APP_NAME="${PARTNER_CODE}_${COLLECTION_CODE}"
APP_NAME_HLS="${PARTNER_CODE}/${COLLECTION_CODE}"

if [[ ! -d ${VIDEO_DIR} ]]; then
    echo "VIDEO_DIR:${VIDEO_DIR} doesn't exist." 
    exit 1
fi

#define variables 
M3U8_MANIFEST=${VIDEO_DIR}/"${VIDEO_ID}"_"$M3U8"
F4M_MANIFEST=${VIDEO_DIR}/"${VIDEO_ID}"_"$F4M"
BASE_URL_HDS=rtmp://${VIDEO_SERVER_NAME}/${APP_NAME}
BASE_URL_HLS=http://${VIDEO_SERVER_NAME}/hls-vod/${APP_NAME_HLS}

#generate hls manifest file- extention u8m3
delete_old_manifest ${M3U8_MANIFEST}
generate_m3u8_manifest

#generates hds manifest file - extention f4m 
delete_old_manifest ${F4M_MANIFEST}
generate_f4m_manifest

