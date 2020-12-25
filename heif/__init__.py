import os

libheif_path = os.getenv('LIBHEIF_PATH', 'C:/vcpkg/installed/x64-windows/bin')

with os.add_dll_directory(libheif_path):
    import heiflib
