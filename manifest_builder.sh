cript is used to generate manifest files for dynamic streaming of DLTS video. generates manifest files for hls (mobile) and hds streaming.Use filename as a parameter.   

#generate hls manifest file- extention u8m3
echo '#EXTM3U'>>$1'_manifest.u8m3'
echo ''>>$1'_manifest.u8m3'
for f in $(ls $1_*k_mobile_s.mp4);
do
 br=`echo $f | awk -F_ '{ print $3 }'`
 br_i=$(((${br%k}-32)*1000))
echo '#EXT-X-STREAM-INF:PROGRAM-ID=1,BANDWIDTH='$br_i>>$1'_manifest.m3u8'
echo ''>>$1'_manifest.u8m3'
echo '/hls-vod/afi-ds/'$f'.m3u8'>>$1'_manifest.m3u8'
echo ''>>$1'_manifest.u8m3'
done

#generates hds manifest file - extention m4p 
echo '<manifest xmlns="http://ns.adobe.com/f4m/2.0">'i>>$1'_manifest.f4m'
echo '<baseURL>http://ams.library.nyu.edu/hls-void/afi-ds/ </baseURL>'>>$1'_manifest.f4m'
for f in $(ls $1_*k_s.mp4)
do
 br=`echo $f | awk -F_ '{ print $3 }'`
 br_i=$((${br%k}-32))
 echo '<media href="'$fri'.f4m" bitrate="i'$br_i'"/>'>>$1'_manifest.f4m'
done
echo '</manifest>'>>$1'_manifest.f4m'
