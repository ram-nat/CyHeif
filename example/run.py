import sys

from cyheifloader import cyheif 

from PIL import Image
from PIL.ExifTags import TAGS

print(cyheif.get_heif_version())
heif_img = cyheif.HeifImage(b'sample.heic')
exif = heif_img.get_exif_data()
exif_readable = {TAGS.get(k):v for (k,v) in exif.items()}
print(exif_readable)
pil_img = heif_img.get_pil_image()
pil_img_exif = pil_img.getexif()
pil_img = pil_img.resize((pil_img.width // 32, pil_img.height // 32))
print({TAGS.get(k):v for (k,v) in pil_img_exif.items()})
pil_img.show()
pil_img.save('sample.jpg', 'JPEG', exif=pil_img.getexif().tobytes())
print('Done')
