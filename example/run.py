import sys

from cyheifloader import cyheif 

from PIL import Image

print(cyheif.get_heif_version())
heif_img = cyheif.HeifImage(b'sample.heic')
pil_img = heif_img.get_pil_image()
pil_img.show()
pil_img.save('sample.jpg', 'JPEG')
print('Done')
