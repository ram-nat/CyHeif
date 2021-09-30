import sys

from cyheifloader import cyheif 

from PIL import Image
from PIL.ExifTags import TAGS

print(cyheif.get_heif_version())
heif_img = cyheif.HeifImage()
exif = heif_img.get_exif_data(b'sample.heic')
exif_readable = {TAGS.get(k):v for (k,v) in exif.items()}
print(exif_readable)
pil_img = heif_img.get_pil_image(b'sample.heic')
pil_img_exif = pil_img.getexif()
print({TAGS.get(k):v for (k,v) in pil_img_exif.items()})
pil_img = pil_img.resize((pil_img.width // 32, pil_img.height // 32))
print('showing image')
pil_img.show()
pil_img.save('sample.jpg', 'JPEG', exif=pil_img.getexif().tobytes())
print('Done')
pil_img_exif.image_description = 'A test image for CyHeif'
heif_img = cyheif.HeifImage()
heif_img.write_exif_data(b'sample.heic', b'sample_exif.heic', pil_img_exif)