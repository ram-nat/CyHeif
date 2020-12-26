from libc cimport stdint

cdef extern from "libheif/heif.h":
    ctypedef unsigned char uint8_t

    ctypedef unsigned int heif_item_id

    struct heif_context:
        pass

    struct heif_reading_options:
        pass

    struct heif_image_handle:
        pass

    struct heif_image:
        pass

    struct heif_decoding_options:
        pass

    heif_context* heif_context_alloc()
    void heif_context_free(heif_context* ctx)

    struct heif_error:
        int code
        int subcode
        const char* message

    const char* heif_get_version()

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
        int colorspace,
        int chroma,
        const heif_decoding_options* options)

    const uint8_t* heif_image_get_plane_readonly(
        const heif_image* img,
        int channel,
        int* out_stride)

    int heif_image_get_primary_width(const heif_image* img)

    int heif_image_get_primary_height(const heif_image* img)

    void heif_image_release(const heif_image* img)

    void heif_image_handle_release(const heif_image_handle* handle)

    int heif_image_handle_get_height(const heif_image_handle* handle)

    int heif_image_handle_get_width(const heif_image_handle* handle)

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
