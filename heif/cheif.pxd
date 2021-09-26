from libc cimport stdint

cdef extern from "libheif/heif.h":
    ctypedef unsigned char uint8_t

    ctypedef unsigned int heif_item_id

    cpdef enum heif_error_code:
        # Everything ok, no error occurred.
        heif_error_Ok = 0,

        # Input file does not exist.
        heif_error_Input_does_not_exist = 1,

        # Error in input file. Corrupted or invalid content.
        heif_error_Invalid_input = 2,

        # Input file type is not supported.
        heif_error_Unsupported_filetype = 3,

        # Image requires an unsupported decoder feature.
        heif_error_Unsupported_feature = 4,

        # Library API has been used in an invalid way.
        heif_error_Usage_error = 5,

        # Could not allocate enough memory.
        heif_error_Memory_allocation_error = 6,

        # The decoder plugin generated an error
        heif_error_Decoder_plugin_error = 7,

        # The encoder plugin generated an error
        heif_error_Encoder_plugin_error = 8,

        # Error during encoding or when writing to the output
        heif_error_Encoding_error = 9,

        # Application has asked for a color profile type that does not exist
        heif_error_Color_profile_does_not_exist = 10

    cpdef enum heif_chroma:
        heif_chroma_undefined = 99,
        heif_chroma_monochrome = 0,
        heif_chroma_420 = 1,
        heif_chroma_422 = 2,
        heif_chroma_444 = 3,
        heif_chroma_interleaved_RGB = 10,
        heif_chroma_interleaved_RGBA = 11,
        heif_chroma_interleaved_RRGGBB_BE = 12,
        heif_chroma_interleaved_RRGGBBAA_BE = 13,
        heif_chroma_interleaved_RRGGBB_LE = 14,
        heif_chroma_interleaved_RRGGBBAA_LE = 15

    cpdef enum heif_colorspace:
        heif_colorspace_undefined = 99,
        heif_colorspace_YCbCr = 0,
        heif_colorspace_RGB = 1,
        heif_colorspace_monochrome = 2

    cpdef enum heif_channel:
        heif_channel_Y = 0,
        heif_channel_Cb = 1,
        heif_channel_Cr = 2,
        heif_channel_R = 3,
        heif_channel_G = 4,
        heif_channel_B = 5,
        heif_channel_Alpha = 6,
        heif_channel_interleaved = 10

    struct heif_context:
        pass

    struct heif_reading_options:
        pass

    struct heif_image_handle:
        pass

    struct heif_image:
        pass

    struct heif_decoding_options:
        uint8_t ignore_transformations
        #uint8_t convert_hdr_to_8bit

    heif_context* heif_context_alloc()
    void heif_context_free(heif_context* ctx)

    struct heif_error:
        heif_error_code code
        int subcode
        const char* message

    const char* heif_get_version()

    # Context
    heif_error heif_context_read_from_file(
        heif_context* ctx, 
        const char* filename, 
        const heif_reading_options* read_options)

    heif_error heif_context_get_primary_image_handle(
        heif_context* ctx, 
        heif_image_handle** img_handle)

    heif_error heif_decode_image(
        const heif_image_handle* in_handle, 
        heif_image** out_img,
        heif_colorspace colorspace,
        heif_chroma chroma,
        const heif_decoding_options* options)

    heif_decoding_options* heif_decoding_options_alloc()

    void heif_decoding_options_free(heif_decoding_options* opt)

    # Image
    const uint8_t* heif_image_get_plane_readonly(
        const heif_image* img,
        heif_channel channel,
        int* out_stride)

    int heif_image_get_primary_width(const heif_image* img)

    int heif_image_get_primary_height(const heif_image* img)

    void heif_image_release(const heif_image* img)

    void heif_image_handle_release(const heif_image_handle* handle)

    int heif_image_handle_get_height(const heif_image_handle* handle)

    int heif_image_handle_get_width(const heif_image_handle* handle)

    int heif_image_handle_has_alpha_channel(const heif_image_handle* handle)

    int heif_image_handle_get_luma_bits_per_pixel(const heif_image_handle* handle)

    int heif_image_handle_get_chroma_bits_per_pixel(const heif_image_handle* handle)

    heif_colorspace heif_image_get_colorspace(const heif_image* handle)

    heif_chroma heif_image_get_chroma_format(const heif_image* handle)

    int heif_image_get_bits_per_pixel_range(const heif_image* handle, heif_channel channel)

    int heif_image_get_height(const heif_image* handle, heif_channel channel)

    int heif_image_get_width(const heif_image* handle, heif_channel channel)

    # Metadata
    int heif_image_handle_get_list_of_metadata_block_IDs(
        const heif_image_handle* handle,
        const char* type_filter,
        heif_item_id* ids, 
        int count)

    size_t heif_image_handle_get_metadata_size(
        const heif_image_handle* handle,
        heif_item_id metadata_id)

    heif_error heif_image_handle_get_metadata(
        const heif_image_handle* handle,
        heif_item_id metadata_id,
        void* out_data)
