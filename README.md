# Utility to add Clean and Bold EXIF Banner to Images

## Banner Generation
### Horizontal
![Horizontal Banner](output/O_horizontal.jpeg)
### Vertical
![Horizontal Banner](output/O_vertical.jpeg)

## Dependencies
imageMagick and exifTool

## Commands

### Single Image 
```
./exif_style.sh images/horizontal.jpg
```

### Multiple Image
```
for img in images/*.jpg; do ./exif_style.sh "$img" ; done
```

## Examples
```
images/
output/
```

Output is generated under output/O_name.jpeg



