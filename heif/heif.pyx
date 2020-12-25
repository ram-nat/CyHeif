cimport cheif

from cpython.pycapsule cimport *

from cpython cimport Py_buffer
from cpython.buffer cimport PyBuffer_FillInfo

from PIL import Image

cdef class HeifError:
    def __cinit__(self, cheif.heif_error err):
        if err.code != 0:
            raise Exception('Heif Error - Message: {0}, Code: {1}, Sub Code: {2}'.format(err.message, err.code, err.subcode))

cdef class HeifContext:
    cdef cheif.heif_context* _heif_ctx

    def __cinit__(self):
        self._heif_ctx = cheif.heif_context_alloc()
        if self._heif_ctx == NULL:
            raise MemoryError('Context Allocation Failed')

    def __dealloc__(self):
        if self._heif_ctx != NULL:
            cheif.heif_context_free(self._heif_ctx)
            self._heif_ctx = NULL

    cdef read_from_file(self, const char* file_name):
        cdef cheif.heif_error res
        res = cheif.heif_context_read_from_file(self._heif_ctx, file_name, NULL)
        HeifError(res)

cdef class HeifImageHandle:
    cdef cheif.heif_image_handle* _handle
    cdef cheif.heif_image* _img
    cdef HeifContext _ctx

    def __cinit__(self, const char* file_name = NULL, HeifContext ctx = None):
        self._ctx = ctx if ctx is not None else HeifContext()
        if file_name is not NULL:
            self._ctx.read_from_file(file_name)
        res = cheif.heif_context_get_primary_image_handle(self._ctx._heif_ctx, &self._handle)        
        HeifError(res)
        res = cheif.heif_decode_image(self._handle, &self._img, 1, 11, NULL)
        HeifError(res)

    def __dealloc__(self):
        if self._img is not NULL:
            cheif.heif_image_release(self._img)
            self._img = NULL
        if self._handle is not NULL:
            cheif.heif_image_handle_release(self._handle)
            self._handle = NULL
        self._ctx = None

    cdef get_image_bytes(self, const unsigned char** data, int* sz):
        #cdef const unsigned char* data = NULL
        cdef int stride = 0
        data[0] = cheif.heif_image_get_plane_readonly(self._img, 10, &stride)
        cdef int height = cheif.heif_image_handle_get_height(self._handle)
        sz[0] = height * stride
        if data is NULL:
            raise Exception('Read failed')

cdef class HeifImage:
    cdef const char* _file_name
    cdef const unsigned char* _data
    cdef int _num_bytes
    cdef int _width
    cdef int _height
    cdef HeifImageHandle _heifImageHandle
    cdef int _stride

    def __cinit__(self, const char* file_name):
        self._file_name = file_name
        self._data = NULL
        self._heifImageHandle = None

    cdef read_heif_image(self):
        if self._data != NULL:
            return       
        self._heifImageHandle = HeifImageHandle(self._file_name)
        self._width = cheif.heif_image_handle_get_width(self._heifImageHandle._handle)
        self._height = cheif.heif_image_handle_get_height(self._heifImageHandle._handle)
        self._heifImageHandle.get_image_bytes(&self._data, &self._num_bytes)
        self._stride = <int>(self._num_bytes / self._height)
        print('Read {0} bytes'.format(self._num_bytes))

    def get_pil_image(self):
        self.read_heif_image()
        print('Size is {0}x{1}'.format(self._height, self._width))
        cdef const unsigned char[:] data_view = <const unsigned char[:self._num_bytes]>self._data
        return Image.frombuffer('RGBX', (self._width, self._height), data_view, 'raw', 'RGBX', self._stride, 1)


def get_heif_version():
    return cheif.heif_get_version()
