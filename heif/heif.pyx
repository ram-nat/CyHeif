cimport cheif

from cpython.pycapsule cimport *

from cpython.mem cimport PyMem_Malloc, PyMem_Free

from PIL import Image

cdef class HeifBuffer:
    cdef unsigned char* _data
    cdef size_t _sz

    def __cinit__(self, size_t sz):
        self._data = <unsigned char*>PyMem_Malloc(sz * sizeof(unsigned char))
        if self._data is NULL:
            raise MemoryError()
        self._sz = sz

    def __dealloc__(self):
        PyMem_Free(self._data)
        self._data = NULL
        self._sz = 0

cdef class HeifError:
    def __cinit__(self, cheif.heif_error err):
        if err.code != 0:
            raise Exception(
                'Heif Error - Message: {0}, Code: {1}, Sub Code: {2}'.format(err.message, err.code, err.subcode)
            )

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
        cdef int stride = 0
        data[0] = cheif.heif_image_get_plane_readonly(self._img, 10, &stride)
        cdef int height = cheif.heif_image_handle_get_height(self._handle)
        sz[0] = height * stride
        if data is NULL:
            raise Exception('Read failed')

    cdef cheif.heif_item_id get_image_exif_metadata_id(self):
        cdef cheif.heif_item_id metadata_item_id
        cdef int num_items = 0
        num_items = cheif.heif_image_handle_get_list_of_metadata_block_IDs(
            self._handle,
            b'Exif',
            &metadata_item_id,
            1
        )
        if num_items != 1:
            return 0
        return metadata_item_id

    cdef HeifBuffer get_image_exif_data(self):
        cdef cheif.heif_item_id exif_id = self.get_image_exif_metadata_id()
        if exif_id == 0:
            return None
        cdef size_t sz = cheif.heif_image_handle_get_metadata_size(self._handle, exif_id)
        # TODO: Arbitrary sanity check - needs to be fixed
        if sz < 4 or sz > 512*1024:
            raise Exception('Invalid EXIF Data')
        cdef HeifBuffer buf = HeifBuffer(sz)
        res = cheif.heif_image_handle_get_metadata(self._handle, exif_id, buf._data)
        HeifError(res)
        return buf

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

    def get_pil_image(self, bint retain_exif=True):
        self.read_heif_image()
        cdef const unsigned char[:] data_view = <const unsigned char[:self._num_bytes]>self._data
        pil_image = Image.frombuffer(
            'RGBX', 
            (self._width, self._height), 
            data_view, 
            'raw', 
            'RGBX', 
            self._stride, 
            1
        )
        if retain_exif:
            heif_buffer = self._heifImageHandle.get_image_exif_data()
            # HACK - Reading PIL Image sources shows setting this dictionary item will make Image.getExif work
            # TODO: Replace hard-coded 4 with the right offset read from the EXIF stream
            pil_image.info['exif'] = bytes(heif_buffer._data[4:heif_buffer._sz])
        return pil_image

    def get_exif_data(self):
        self.read_heif_image()
        heif_buffer = self._heifImageHandle.get_image_exif_data()
        exif = Image.Exif()
        cdef const unsigned char[:] data_view = <const unsigned char[:heif_buffer._sz]>heif_buffer._data
        # HACK - Reading PIL.Image.Exif sources shows passing a byte array to Exif.load will work
        # HACK - Unfortunately, it needs to be a byte array as load calls starts_with on it
        # TODO: Replace hard-coded 4 with the right offset read from the EXIF stream
        exif.load(bytes(data_view[4:]))
        return exif

def get_heif_version():
    return cheif.heif_get_version()
