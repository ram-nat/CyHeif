cimport heif.cheif as cheif

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
        if err.code != cheif.heif_error_code.heif_error_Ok:
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

cdef class HeifDecodingOptions:
    cdef cheif.heif_decoding_options* _options

    def __cinit__(self, bint convert_hdr_to_8bit=False, bint apply_transformations=True):
        # TODO: Default libheif versions in Ubuntu don't support this flag yet
        convert_hdr_to_8bit = False
        if convert_hdr_to_8bit or not apply_transformations:
            self._options = cheif.heif_decoding_options_alloc()
            # TODO: Default libheif versions in Ubuntu don't support this flag yet
            #self._options.convert_hdr_to_8bit = <int>(convert_hdr_to_8bit)
            self._options.ignore_transformations = <int>(not apply_transformations)
        else:
            self._options = NULL

    def __dealloc__(self):
        if self._options is not NULL:
            cheif.heif_decoding_options_free(self._options)
            self._options = NULL

    cdef cheif.heif_decoding_options* get_decoding_options(self):
        return self._options

cdef class HeifEncoder:
    cdef cheif.heif_encoder* _encoder
    cdef HeifContext _ctx

    def __cinit__(self, cheif.heif_compression_format fmt, HeifContext ctx = None):
        self._ctx = ctx if ctx is not None else HeifContext()
        res = cheif.heif_context_get_encoder_for_format(self._ctx._heif_ctx, fmt, &self._encoder)
        HeifError(res)
    
    def __dealloc__(self):
        if self._encoder is not NULL:
            cheif.heif_encoder_release(self._encoder)
            self._encoder = NULL
        self._ctx = None

    cdef set_logging_level(self: HeifEncoder, int lvl):
        res = cheif.heif_encoder_set_logging_level(self._encoder, lvl)
        HeifError(res)


cdef class HeifImageAttributes:
    cdef cheif.heif_colorspace colorspace
    cdef cheif.heif_chroma chroma
    cdef int bits_per_pixel
    cdef int width
    cdef int height

    @staticmethod
    cdef HeifImageAttributes from_image(cheif.heif_image* img):
        cdef HeifImageAttributes img_attr = HeifImageAttributes.__new__(HeifImageAttributes)
        img_attr.colorspace = cheif.heif_image_get_colorspace(img)
        img_attr.chroma = cheif.heif_image_get_chroma_format(img)
        img_attr.bits_per_pixel = cheif.heif_image_get_bits_per_pixel_range(img, cheif.heif_channel.heif_channel_interleaved)
        img_attr.width = cheif.heif_image_get_width(img, cheif.heif_channel.heif_channel_interleaved)
        img_attr.height = cheif.heif_image_get_height(img, cheif.heif_channel.heif_channel_interleaved)
        return img_attr

    cdef str get_pillow_raw_format(self):
        chroma_to_pillow_raw_format: Dict[cheif.heif_chroma, str] = {
            cheif.heif_chroma.heif_chroma_interleaved_RGB: 'RGB',
            cheif.heif_chroma.heif_chroma_interleaved_RGBA: 'RGBA',
        }
        return chroma_to_pillow_raw_format[self.chroma]

    cdef print_image_attributes(self):
        print('Width: {}, Height: {}, Bits Per Pixel: {}, Chroma: {}, ColorSpace: {}'.format(self.width, self.height, self.bits_per_pixel, self.chroma, self.colorspace))

cdef class HeifImage:
    cdef cheif.heif_image* _img

    def __dealloc__(self):
        if self._img is not NULL:
            cheif.heif_image_release(self._img)
            self._img = NULL

    @staticmethod
    cdef HeifImage from_image(cheif.heif_image* img):
        cdef HeifImage image = HeifImage()
        image._img = img
        return image

cdef class HeifImageHandle:
    cdef cheif.heif_image_handle* _handle
    cdef cheif.heif_image* _img
    cdef HeifContext _ctx

    def __dealloc__(self):
        if self._img is not NULL:
            cheif.heif_image_release(self._img)
            self._img = NULL
        if self._handle is not NULL:
            cheif.heif_image_handle_release(self._handle)
            self._handle = NULL
        self._ctx = None

    @staticmethod
    cdef HeifImageHandle from_image_handle(cheif.heif_image_handle* handle, HeifContext ctx = None):
        ctx = ctx if ctx is not None else HeifContext()
        cdef HeifImageHandle image_handle = HeifImageHandle()
        image_handle._ctx = ctx
        image_handle._handle = handle
        return image_handle

    @staticmethod
    cdef HeifImageHandle from_file(const char* file_name, HeifContext ctx = None):
        ctx = ctx if ctx is not None else HeifContext()
        ctx.read_from_file(file_name)
        cdef cheif.heif_image_handle* handle
        res = cheif.heif_context_get_primary_image_handle(ctx._heif_ctx, &handle)
        HeifError(res)
        return HeifImageHandle.from_image_handle(handle, ctx)

    cdef cheif.heif_colorspace get_image_colorspace(self):
        return cheif.heif_image_get_colorspace(self._img)

    cdef cheif.heif_chroma get_image_chroma_format(self):
        return cheif.heif_image_get_chroma_format(self._img)

    cdef int get_image_handle_has_alpha(self):
        return cheif.heif_image_handle_has_alpha_channel(self._handle)

    cdef int get_image_handle_luma_bits_per_pixel(self):
        return cheif.heif_image_handle_get_luma_bits_per_pixel(self._handle)

    cdef int get_image_height(self, cheif.heif_channel channel):
        return cheif.heif_image_get_height(self._img, channel)

    cdef int get_image_width(self, cheif.heif_channel channel):
        return cheif.heif_image_get_width(self._img, channel)

    cdef int get_image_bits_per_pixel_range(self, cheif.heif_channel channel):
        return cheif.heif_image_get_bits_per_pixel_range(self._img, channel)

    cdef (cheif.heif_colorspace, cheif.heif_chroma) get_colorspace_and_chroma(self, bint convert_hdr_to_8bit=False):
        cdef cheif.heif_colorspace color_space = cheif.heif_colorspace.heif_colorspace_RGB
        cdef int has_alpha = self.get_image_handle_has_alpha()
        cdef int bits_per_pixel = self.get_image_handle_luma_bits_per_pixel()
        cdef cheif.heif_chroma chroma = cheif.heif_chroma.heif_chroma_interleaved_RGB
        # TODO: AFAICT, Pillow does not support 10 bits per pixel raw format
        convert_hdr_to_8bit = True
        if bits_per_pixel <= 8 or convert_hdr_to_8bit:
            chroma = cheif.heif_chroma.heif_chroma_interleaved_RGBA if bool(has_alpha) else cheif.heif_chroma.heif_chroma_interleaved_RGB                
        else:
            chroma = cheif.heif_chroma.heif_chroma_interleaved_RRGGBBAA_LE if bool(has_alpha) else cheif.heif_chroma.heif_chroma_interleaved_RRGGBB_LE
        return (color_space, chroma)
    
    cdef decode_image(self, bint convert_hdr_to_8bit=False, bint apply_transformations=True):
        if self._img is not NULL:
            cheif.heif_image_release(self._img)
            self._img = NULL
        cdef cheif.heif_colorspace color_space
        cdef cheif.heif_chroma chroma
        (color_space, chroma) = self.get_colorspace_and_chroma(convert_hdr_to_8bit)
        cdef HeifDecodingOptions decoding_options = HeifDecodingOptions(convert_hdr_to_8bit, apply_transformations)
        res = cheif.heif_decode_image(
            self._handle, 
            &self._img, 
            color_space, 
            chroma, 
            decoding_options.get_decoding_options())
        HeifError(res)

    cdef HeifImageAttributes get_image_bytes(
        self, 
        const unsigned char** data, 
        int* sz, 
        bint convert_hdr_to_8bit=False, 
        bint apply_transformations=True):
        self.decode_image(convert_hdr_to_8bit, apply_transformations)
        cdef HeifImageAttributes img_attr = HeifImageAttributes.from_image(self._img)
        cdef int stride = 0
        data[0] = cheif.heif_image_get_plane_readonly(self._img, cheif.heif_channel.heif_channel_interleaved, &stride)
        sz[0] = img_attr.height * stride
        print('Width: {}, Height: {}, Stride: {}'.format(img_attr.width, img_attr.height, stride))
        if data is NULL:
            raise Exception('Read failed')
        return img_attr

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

    cdef HeifImageHandle add_exif_data(self: HeifImageHandle, const unsigned char[:] exif_data, int sz):
        self.decode_image()
        cdef HeifEncoder encoder = HeifEncoder(cheif.heif_compression_format.heif_compression_HEVC)
        cdef cheif.heif_image_handle* out_handle
        res = cheif.heif_context_encode_image(encoder._ctx._heif_ctx, self._img, encoder._encoder, NULL, &out_handle)
        HeifError(res)
        cdef HeifImageHandle new_image_handle = HeifImageHandle.from_image_handle(out_handle, encoder._ctx)
        res = cheif.heif_context_add_exif_metadata(encoder._ctx._heif_ctx, out_handle, &exif_data[0], sz)
        HeifError(res)
        return new_image_handle

    @staticmethod
    cdef HeifImageHandle get_image_from_rgb_bytes(
        const unsigned char[:] image_data, 
        int sz, 
        int width, 
        int height,
        const unsigned char[:] exif_data = None,
        int exif_sz = 0):
        cdef HeifImage img = HeifImage()
        res = cheif.heif_image_create(
            width, 
            height, 
            cheif.heif_colorspace.heif_colorspace_RGB, 
            cheif.heif_chroma.heif_chroma_interleaved_RGB, 
            &img._img)
        HeifError(res)

        res = cheif.heif_image_add_plane(
            img._img,
            cheif.heif_channel.heif_channel_interleaved,
            width,
            height,
            24)
        HeifError(res)

        cdef int stride
        cdef unsigned char* img_buffer 
        img_buffer = cheif.heif_image_get_plane(img._img, cheif.heif_channel.heif_channel_interleaved, &stride)
        img_buffer_view = <unsigned char[:height*stride]>img_buffer

        assert(height*stride >= sz)
        img_buffer_view[:sz] = image_data[:sz]

        cdef HeifEncoder encoder = HeifEncoder(cheif.heif_compression_format.heif_compression_HEVC)
        cdef cheif.heif_image_handle* out_handle
        res = cheif.heif_context_encode_image(encoder._ctx._heif_ctx, img._img, encoder._encoder, NULL, &out_handle)
        HeifError(res)

        cdef HeifImageHandle new_image_handle = HeifImageHandle.from_image_handle(out_handle, encoder._ctx)
        if exif_sz > 0:
            res = cheif.heif_context_add_exif_metadata(encoder._ctx._heif_ctx, out_handle, &exif_data[0], exif_sz)
            HeifError(res)
        
        return new_image_handle

    cdef write_to_file(self: HeifImageHandle, const char* file_name):
        res = cheif.heif_context_write_to_file(self._ctx._heif_ctx, file_name)
        HeifError(res)

def get_pil_image(
    const char* file_name,
    bint apply_transformations=True, 
    bint retain_exif=True) -> Image:

    heifImageHandle = HeifImageHandle.from_file(file_name)
    cdef int num_bytes
    cdef const unsigned char* data
    cdef HeifImageAttributes img_attr = heifImageHandle.get_image_bytes(&data, &num_bytes, True, apply_transformations)
    cdef int stride = <int>(num_bytes / img_attr.height)
    cdef const unsigned char[:] data_view = <const unsigned char[:num_bytes]>data
    pil_image = Image.frombuffer(
        img_attr.get_pillow_raw_format(), 
        (img_attr.width, img_attr.height), 
        data_view, 
        'raw', 
        img_attr.get_pillow_raw_format(), 
        stride, 
        1
    )
    if retain_exif:
        heif_buffer = heifImageHandle.get_image_exif_data()
        # HACK - Reading PIL Image sources shows setting this dictionary item will make Image.getExif work
        # TODO: Replace hard-coded 4 with the right offset read from the EXIF stream
        pil_image.info['exif'] = bytes(heif_buffer._data[4:heif_buffer._sz])
    return pil_image

def write_pil_image(
    input_img: Image,
    const char* output_file_name,
    bint retain_exif=True) -> None:

    # TODO: libheif seems to have a bug where images that have width that are not multiple of 8
    # will not be handled properly (bytes in plane will not match bytes in raw image). Round up
    # and resize the input image to work around this bug.
    if input_img.width % 8 != 0:
        width = input_img.width + (8 - (input_img.width % 8))
        input_img = input_img.resize((width, input_img.height))

    cdef bytes img_bytes = input_img.tobytes('raw', 'RGB')
    cdef bytes exif_bytes
    if retain_exif:
        exif_bytes = input_img.getexif().tobytes()
    cdef HeifImageHandle output_image = HeifImageHandle.get_image_from_rgb_bytes(
        img_bytes,
        int(len(img_bytes)),
        input_img.width,
        input_img.height,
        exif_bytes,
        int(len(exif_bytes)))
    output_image.write_to_file(output_file_name)

def get_exif_data(const char* file_name) -> Image.Exif:
    cdef HeifImageHandle heifImageHandle = HeifImageHandle.from_file(file_name)
    heif_buffer = heifImageHandle.get_image_exif_data()
    exif = Image.Exif()
    cdef const unsigned char[:] data_view = <const unsigned char[:heif_buffer._sz]>heif_buffer._data
    # HACK - Reading PIL.Image.Exif sources shows passing a byte array to Exif.load will work
    # HACK - Unfortunately, it needs to be a byte array as load calls starts_with on it
    # TODO: Replace hard-coded 4 with the right offset read from the EXIF stream
    exif.load(bytes(data_view[4:]))
    return exif

def write_exif_data_from_bytes(
    const char* input_file_name,
    const char* output_file_name, 
    exif_data: bytes) -> None:
    cdef HeifImageHandle input_image = HeifImageHandle.from_file(input_file_name)
    cdef HeifImageHandle output_image = input_image.add_exif_data(exif_data, int(len(exif_data)))
    output_image.write_to_file(output_file_name)

def write_exif_data(
    const char* input_file_name,
    const char* output_file_name, 
    exif_data: Image.Exif) -> None:
    exif_bytes = exif_data.tobytes()
    write_exif_data_from_bytes(input_file_name, output_file_name, exif_bytes)

def get_heif_version():
    return cheif.heif_get_version()
