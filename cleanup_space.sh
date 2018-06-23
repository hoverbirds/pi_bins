#!/bin/sh

cd /home/pi/media/videos

#convert all existing recordings to mp4
allH264Files=`ls -1 *.h264 | tr "\n" " "`
for h264file in $allH264Files
do
    MP4Box -add $h264file "$h264file.mp4"
done

# while free space is less than 2GB and there are still files to delete
freeGB=`df | grep "/dev/root" | tr -s " " |  cut -d " " -f 4`
echo "free space before cleanup is $freeGB\n"
mediaFiles=`ls -clt | tr -s " " | cut -d " " -f 9 | tr "\n" " "`
echo "current files are $mediaFiles\n"
while [ $freeGB -lt 2097152  -a  ! -z $mediaFiles ] 
do
    for file in $mediaFiles
    do
        echo "removing file $file\n"
        rm $file
        break;
    done
    freeGB=`df | grep "/dev/root" | tr -s " " |  cut -d " " -f 4`
    mediaFiles=`ls -clt | tr -s " " | cut -d " " -f 9 | tr "\n" " "`
done

cd - 
