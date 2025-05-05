# Create clean metadata overlays for your favorite images. Support for Landscape/Portrait mode, as well as Camera Profiles/Manual Lenses, and AutoInvert

## Banner Generation
### Horizontal
![Horizontal Banner](output/O_horizontal.jpeg)
### Vertical
![Horizontal Banner](output/O_vertical.jpeg)

## Dependencies
imageMagick, yq, and exifTool

## Commands

### Run Options
```
Usage: ./exif_style.sh 
Mandatory
        -i <string> Image Path and Name 
Optional
        -l <int>    Log Output Print, default 1 disabled 0
        -p <string> Personal Profile, default if not supplied, else loaded from cfg/profiles.yaml
        -c <string> Camera Profile  , default if not supplied, else loaded from cfg/profiles.yaml
        -f <string> Format Profile  , default if not supplied, else loaded from cfg/profiles.yaml
        -m <string> Manual Aperture , If profile.manual=yes this will overwrite aperture
        -o <int>    Auto Orientation, default 0, in case of iPhone rotated images, 1 will orient based on EXIF
```

### Single Image 
```
./exif_style.sh -i images/horizontal.jpg
```

### Multiple Image
```
for img in images/*.jpg; do ./exif_style.sh -i "$img" ; done
```

## Examples
```
images/
output/
```

Output is generated under output/O_name.jpeg



