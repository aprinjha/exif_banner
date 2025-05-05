#!/bin/bash

# Input image (passed as first argument)
input="$1"

mkdir tmp

# Get the filename without extension
base=$(basename "$input")
name="${base%.*}"

# Output file
output="O_${name}.jpeg"

# Extract EXIF data
model=$(exiftool -s3 -Model "$input")
iso=$(exiftool -s3 -ISO "$input")
aperture=$(exiftool -s3 -FNumber "$input")
shutter=$(exiftool -s3 -ExposureTime "$input")
focal=$(exiftool -s3 -FocalLength "$input" | sed 's/ //g')
lensid=$(exiftool -s3 -LensID "$input")
datetime=$(exiftool -d "%Y.%m.%d %H:%M" -s3 -DateTimeOriginal "$input")

# Compose text
left="$model"
right="${focal}  f/$aperture  $shutter\s  ISO$iso"
copyright="$© 2025"

iw=`identify -format "%w" $input`
ih=`identify -format "%h" $input`


if [ $ih -gt $iw ]
then
    borderWidth=$(($iw/15))
    fontsize=$(($iw/37))
    fontsize2=$(($iw/32))
    rxy=$(echo "(($iw+$ih) / 2) * 0.014" | bc | awk '{printf "%d", $1}')
    echo "$ih>$iw"
else
    borderWidth=$(($ih/15))
    fontsize=$(($ih/35))
    fontsize2=$(($ih/32))
    rxy=$(echo "(($iw+$ih) / 2) * 0.014" | bc | awk '{printf "%d", $1}')
    echo "$ih<$iw"
fi

borderHeight=$(($ih/16))

textBoxHeight=$(($borderWidth+$ih))
textBoxWidth=$(($borderWidth+$borderWidth/5))

#lineAOff=$(($textBoxHeight+$ih/28))
#lineBOff=$(($textBoxHeight+$ih/22))
lineAOff=$(($textBoxHeight+ ($borderWidth * 3 / 5)))
lineBOff=$(($lineAOff + ($fontsize / 4)))

magick -size "$iw\x$ih" xc:black -fill white  -draw "roundrectangle 0,0 $iw,$ih $rxy,$rxy" tmp/temp_mask.png
magick "$input" tmp/temp_mask.png -alpha Off -compose CopyOpacity -composite tmp/temp_round.png
magick tmp/temp_round.png -bordercolor white -border "$borderWidth\x$borderWidth" "tmp/temp_border.jpg"
magick "tmp/temp_border.jpg" -size "$iw\x$borderHeight" xc:white -append tmp/temp_base.jpg

# Generate the output image with white border and text
magick "tmp/temp_base.jpg" \
  -pointsize "$fontsize" \
  -font Helvetica -fill darkgrey \
  -annotate +$textBoxWidth+$lineAOff "Shot on" \
  -pointsize "$fontsize2" \
  -font Helvetica-Bold -fill black \
  -gravity NorthWest \
  -annotate +$textBoxWidth+$lineBOff "$left" \
  -font Helvetica -fill black \
  -gravity NorthEast \
  -annotate +$textBoxWidth+$lineBOff "$right" \
  "$output"



echo "✅ Created: $output"