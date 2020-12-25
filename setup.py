from distutils.core import setup
from distutils.extension import Extension
import sys
import os
import argparse

argparser = argparse.ArgumentParser(add_help=False)
argparser.add_argument('--use-cython', action='store_true', default=False)
argparser.add_argument('--libheif_path', default='C:/vcpkg/installed/x64-windows')
args, unknown = argparser.parse_known_args()
sys.argv = [sys.argv[0]] + unknown

libheif_bin_path = os.path.join(args.libheif_path, 'bin')
libheif_lib_path = os.path.join(args.libheif_path, 'lib')
libheif_inc_path = os.path.join(args.libheif_path, 'include')

ext = '.pyx' if args.use_cython else '.c'

extensions = [
    Extension(
        'heiflib', 
        ['heif/heif'+ext], 
        language='c', 
        libraries=['heif'], 
        library_dirs=[libheif_bin_path, libheif_lib_path],
        include_dirs=[libheif_inc_path],
    )
]

if args.use_cython:
    from Cython.Build import cythonize
    compiler_directives={'language_level': '3'}
    extensions = cythonize(extensions, compiler_directives=compiler_directives)

setup(
    name='heiflib',
    ext_modules=extensions,
    packages=['heif']
)
