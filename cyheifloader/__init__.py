import sys

if sys.platform.startswith('win32'):
    import os

    libheif_path = os.getenv('LIBHEIF_PATH', os.path.join(sys.prefix, 'bin'))

    with os.add_dll_directory(libheif_path):
        import cyheif
else:
    import cyheif
