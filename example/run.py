import heif.heiflib as heif

from PIL import Image

print(heif.get_heif_version())
heif_img = heif.HeifImage(b'sample.heic')
pil_img = heif_img.get_pil_image()
pil_img.show()
pil_img.save('sample.jpg', 'JPEG')
print('Done')
