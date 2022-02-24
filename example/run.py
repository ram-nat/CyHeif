import sys

# cyheifloader allows specifying the path to heif.dll on Windows
# using the environment variable LIBHEIF_PATH.
from cyheifloader import cyheif

from PIL import Image
from PIL.ExifTags import TAGS

# Print libheif version
print(f'LibHeif Version: {cyheif.get_heif_version()}')

file_name = sys.argv[1] if len(sys.argv) > 1 else 'sample.heic'
file_name = str.encode(file_name, 'UTF-8')
print(f'Processing {file_name}')

# Print EXIF data from HEIF file
print('Getting EXIF Data from EXIF')
exif = cyheif.get_exif_data(file_name)
exif_readable = {TAGS.get(k):v for (k,v) in exif.items()}
print(exif_readable)

# Get pillow image from HEIF file
print('Getting Pillow Image from HEIC')
pil_img = cyheif.get_pil_image(file_name)
pil_img_exif = pil_img.getexif()

# Resize pillow image
pil_img = pil_img.resize((pil_img.width // 32, pil_img.height // 32))

print('showing image')
pil_img.show()

# Save pillow image as jpeg
print('Saving Pillow Image as JPEG')
pil_img.save('sample.jpg', 'JPEG', exif=pil_img.getexif().tobytes())
pil_img.save('sample.png', 'PNG', exif=pil_img.getexif().tobytes())

# Update EXIF data in input HEIF file and save it to output HEIF file
print('Updating EXIF data in HEIC')
pil_img_exif[0x010F] = 'A test image for CyHeif'
cyheif.write_exif_data(file_name, b'sample_exif.heic', pil_img_exif)

# Write pillow image to output HEIF file
print('Writing Pillow Image to HEIC')
cyheif.write_pil_image(pil_img, b'sample_from_pil.heic')
