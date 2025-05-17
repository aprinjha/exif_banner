#!/bin/bash

# Error Codes
RED=$(tput setaf 1)
YELLOW=$(tput setaf 3)
NORMAL=$(tput sgr0)
GREEN=$(tput setaf 2)

# Log Verbosity
logOutput=1

# Usage instructions
usage() { printf "Usage: $0 
${RED}Mandatory
\t-i <string> Image Path and Name 
${YELLOW}Optional
\t-l <int>    Log Output Print, default 1
\t-p <string> Personal Profile, default if not supplied
\t-c <string> Camera Profile  , default if not supplied
\t-f <string> Format Profile  , default if not supplied
\t-m <string> Manual Aperture , skipped if not provided and profile.manual=yes
\t-o <int>    Auto Orientation, default 0${NORMAL}"
1>&2; exit 1; }

# Print Out 
logOut() {
  if [ $logOutput == 1 ]; then
    printf "$1\n"  # Print the argument passed to the function
  fi
}

# Setting default
input=""
camera="default"
profile="default"
format="default"
auto_orient="off"
aperture=""

while getopts ":l:i:p:c:m:o:f:" opt; do
  case "${opt}" in
	l)
		logOutput=0
		;;
	i)  
		input=${OPTARG}
		logOut "Loaded Image $input"
		;;
	c) 
		camera=${OPTARG}            
		logOut "Loaded Camera Profile $camera"
		;;
	p)	profile=${OPTARG}            
		logOut "Loaded Brand Profile $profile"
		;;
	f)	format=${OPTARG}            
		logOut "Loaded Formatting Profile $format"
		;;
	m)
		aperture="ƒ/${OPTARG}  "
		logOut "Manual Aperture $aperture"
		;;
	o) 
		auto_orient="on"
		logOut "Auto Orientation On"
		;;
	*)
		usage ;;
  esac
done

if [ -z "${input}" ]; then
	printf "${RED}ERR: Missing Input Image -i $input${NORMAL}\n"
	usage
fi

# Make directory to store temporary files
mkdir tmp

# Get the filename without extension
base=$(basename "$input")
name="${base%.*}"

# Config file
config="cfg/profiles.yaml"

# Output file
output="output/O_${name}.jpeg"

# Extract Personal/Brand Data
if [ "$(yq ".personal.${profile}" "$config")" != "null" ]; then
	handle=$(yq ".personal.${profile}.handle" "$config")
	copyrightYear=$(yq ".personal.${profile}.copyright.year" "$config")
else
	printf "${RED}ERR: Unknown Personal Profile supplied -f $profile${NORMAL}\n"
	usage
fi

# Extract EXIF data
if [ "$camera" == "default" ]; then
	model=$(exiftool -s3 -Model "$input")
	description=$(exiftool -s3 -ImageDescription "$input")
	iso=$(exiftool -s3 -ISO "$input")
	aperture="ƒ/$(exiftool -s3 -FNumber "$input")  "
	shutter=$(exiftool -s3 -ExposureTime "$input")
	focal=$(exiftool -s3 -FocalLength "$input" | sed 's/ //g')
	lens=$(exiftool -s3 -LensID "$input")
	datetime=$(exiftool -d "%Y.%m.%d %H:%M" -s3 -DateTimeOriginal "$input")
else 
	model=$(yq ".camera.${camera}.model" "$config")
	description=$(exiftool -s3 -ImageDescription "$input")
	lens=$(yq ".camera.${camera}.lens" "$config")
	iso=$(exiftool -s3 -ISO "$input")
	shutter=$(exiftool -s3 -ExposureTime "$input")
	if [ "$(yq ".camera.${camera}.manual" "$config")" == "yes" ]; then
		logOut "Manual Mode Loaded"
		focal=$(yq ".camera.${camera}.focal" "$config")
	else
		aperture="f/$(exiftool -s3 -FNumber "$input")  "
		focal=$(exiftool -s3 -FocalLength "$input" | sed 's/ //g')
	fi
	datetime=$(exiftool -d "%Y.%m.%d %H:%M" -s3 -DateTimeOriginal "$input")
fi

# Compose text
left="$model"
right="${focal}  $aperture$shutter\s  ISO$iso"
copyright="$description © $handle $copyrightYear"

# auto-orient
magick "$input" -auto-orient "tmp/temp_auto.jpeg"
input="tmp/temp_auto.jpeg"

# Extract Formatting Options
if [ "$(yq ".format.${format}" "$config")" != "null" ]; then
	font=$(yq ".format.${format}.font" "$config")
	fontBold=$(yq ".format.${format}.fontBold" "$config")
	lineAfill=$(yq ".format.${format}.lineAfill" "$config")
	lineBfill=$(yq ".format.${format}.lineBfill" "$config")
else
	printf "${RED}ERR: Unknown Formatting Profile supplied -f $format${NORMAL}\n"
	usage
fi


# Image Dimensions extract
iw=`identify -format "%w" $input`
ih=`identify -format "%h" $input`

if [ $ih -gt $iw ]
then
    borderWidth=$(($iw/15))
    fontsize=$(($iw/37))
    fontsize2=$(($iw/32))
    rxy=$(echo "(($iw+$ih) / 2) * 0.014" | bc | awk '{printf "%d", $1}')
    #logOut "$ih>$iw"
else
    borderWidth=$(($ih/15))
    fontsize=$(($ih/35))
    fontsize2=$(($ih/32))
    rxy=$(echo "(($iw+$ih) / 2) * 0.014" | bc | awk '{printf "%d", $1}')
    #logOut "$ih<$iw"
fi

borderHeight=$(($ih/16))

textBoxHeight=$(($borderWidth+$ih))
textBoxWidth=$(($borderWidth+$borderWidth/5))

lineAOff=$(($textBoxHeight+ ($borderWidth * 3 / 5)))
lineBOff=$(($lineAOff + ($fontsize / 4)))

magick -size "$iw\x$ih" xc:black -fill white  -draw "roundrectangle 0,0 $iw,$ih $rxy,$rxy" tmp/temp_mask.png
magick "$input" tmp/temp_mask.png -alpha Off -compose CopyOpacity -composite  tmp/temp_round.png
magick tmp/temp_round.png -bordercolor white -border "$borderWidth\x$borderWidth" \
  	-size "$iw\x$borderHeight" xc:white -append tmp/temp_base.jpeg

# Generate the output image with white border and text
magick "tmp/temp_base.jpeg" \
  	-pointsize "$fontsize" \
  	-font $font -fill $lineAfill \
  	-annotate +$textBoxWidth+$lineAOff "Shot on" \
  	-pointsize "$fontsize2" \
  	-font $fontBold -fill $lineBfill \
  	-gravity NorthWest \
  	-annotate +$textBoxWidth+$lineBOff "$left" \
  	-font $font -fill $lineBfill \
  	-gravity NorthEast \
  	-annotate +$textBoxWidth+$lineBOff "$right" \
  	"$output"

# In Progress Multiple Modes
#magick "tmp/temp_base.jpeg" \
#  	-pointsize "$fontsize2" \
#  	-font $fontBold -fill $lineBfill \
#  	-gravity NorthWest \
#  	-annotate +$textBoxWidth+$lineAOff "$description" \
#  	-font $font -fill $lineBfill \
#  	-gravity NorthEast \
#  	-annotate +$textBoxWidth+$lineAOff "$left" \
#  	"$output"

# Clearing Dirs
rm -r tmp/

printf "Created: $output\n"
