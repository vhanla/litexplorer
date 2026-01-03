unit libpng;

{$ALIGN ON}
{$MINENUMSIZE 4}

interface

const
  PNG_LIBPNG_VER_STRING = '1.8.0';
  PNG_HEADER_VERSION_STRING = 'libpng version 1.8.0 - (git)';
  PNG_LIBPNG_VER = 10800; // 1.8.0

  // These describe the color_type field in png_info.
  // color type masks
  PNG_COLOR_MASK_PALETTE = 1;
  PNG_COLOR_MASK_COLOR   = 2;
  PNG_COLOR_MASK_ALPHA   = 4;

  // color types.  Note that not all combinations are legal
  PNG_COLOR_TYPE_GRAY       = 0;
  PNG_COLOR_TYPE_PALETTE    = PNG_COLOR_MASK_COLOR or PNG_COLOR_MASK_PALETTE;
  PNG_COLOR_TYPE_RGB        = PNG_COLOR_MASK_COLOR;
  PNG_COLOR_TYPE_RGB_ALPHA  = PNG_COLOR_MASK_COLOR or  PNG_COLOR_MASK_ALPHA;
  PNG_COLOR_TYPE_GRAY_ALPHA = PNG_COLOR_MASK_ALPHA;
  // aliases
  PNG_COLOR_TYPE_RGBA       = PNG_COLOR_TYPE_RGB_ALPHA;
  PNG_COLOR_TYPE_GA         = PNG_COLOR_TYPE_GRAY_ALPHA;

  // This is for compression type. PNG 1.0-1.2 only define the single type.
  PNG_COMPRESSION_TYPE_BASE    = 0; // Deflate method 8, 32K window
  PNG_COMPRESSION_TYPE_DEFAULT = PNG_COMPRESSION_TYPE_BASE;

  // This is for filter type. PNG 1.0-1.2 only define the single type.
  PNG_FILTER_TYPE_BASE        = 0; // Single row per-byte filtering
  PNG_INTRAPIXEL_DIFFERENCING = 64; // Used only in MNG datastreams
  PNG_FILTER_TYPE_DEFAULT     = PNG_FILTER_TYPE_BASE;

  // These are for the interlacing type.  These values should NOT be changed.
  PNG_INTERLACE_NONE  = 0; // Non-interlaced image
  PNG_INTERLACE_ADAM7 = 1; // Adam7 interlacing
  PNG_INTERLACE_LAST  = 2; // Not a valid value

  (* Filter values (not flags) - used in pngwrite.c, pngwutil.c for now.
   * These defines should NOT be changed.
   *)
  PNG_FILTER_VALUE_NONE  = 0;
  PNG_FILTER_VALUE_SUB   = 1;
  PNG_FILTER_VALUE_UP    = 2;
  PNG_FILTER_VALUE_AVG   = 3;
  PNG_FILTER_VALUE_PAETH = 4;
  PNG_FILTER_VALUE_LAST  = 5;

  // flags for png_ptr->free_me and info_ptr->free_me
  PNG_FREE_ALL = $7FFF;

type
  int = Integer;
  png_uint_16 = Word;
  png_uint_32 = Cardinal;
  png_int_32 = Longint;

  png_size_t = NativeUInt;

  png_bytepp = ^png_bytep;
  png_bytep = ^png_byte;
  png_const_bytep = png_bytep;
  png_byte = Byte;

  png_charpp = ^png_charp;
  png_charp = PAnsiChar;

  png_infopp = ^png_infop;
  png_infop = Pointer;

  png_structpp = ^png_structp;
  png_structp = Pointer;

  png_error_ptrp = ^png_error_ptr;
  png_error_ptr = procedure(png_ptr: png_structp; msg: png_charp); cdecl;

  png_voidp = Pointer;

  png_rw_ptrp = ^png_rw_ptr;
  png_rw_ptr = procedure(png_ptr: png_structp; data: png_bytep; data_length: png_size_t); cdecl;

  png_flush_ptrp = ^png_flush_ptr;
  png_flush_ptr = procedure(png_ptr: png_structp); cdecl;
  // Memory allocator callbacks for FastMM5 integration
  png_malloc_ptr = function(png_ptr: png_structp; size: png_size_t): png_voidp; cdecl;
  png_free_ptr = procedure(png_ptr: png_structp; ptr: png_voidp); cdecl;

  (* Three color definitions.  The order of the red, green, and blue, (and the
   * exact size) is not important, although the size of the fields need to
   * be png_byte or png_uint_16 (as defined below).
   *)
  png_color = packed record
    red: png_byte;
    green: png_byte;
    blue: png_byte;
  end;
  png_colorp = ^png_color;
  png_const_colorp = png_colorp;

  png_color_16 = packed record
    index: png_byte;    // used for palette files
    red: png_uint_16;   // for use in red green blue files
    green: png_uint_16;
    blue: png_uint_16;
    gray: png_uint_16;  // for use in grayscale files
  end;
  png_color_16p = ^png_color_16;
  png_const_color_16p = png_color_16p;

var

(* The following return the library version as a short string in the
 * format 1.0.0 through 99.99.99zz.  To get the version of *.h files
 * used with your application, print out PNG_LIBPNG_VER_STRING, which
 * is defined in png.h.
 * Note: now there is no difference between png_get_libpng_ver() and
 * png_get_header_ver().  Due to the version_nn_nn_nn typedef guard,
 * it is guaranteed that png.c uses the correct version of png.h.
 *)
png_get_libpng_ver: function(png_ptr: png_structp): png_charp; cdecl;

// Allocate and initialize png_ptr struct for writing, and any other memory
png_create_write_struct: function(user_png_ver: png_charp;
  error_ptr: png_voidp; error_fn: png_error_ptr;
  warn_fn: png_error_ptr): png_structp;  cdecl;

// Create write struct with custom memory allocators (Enable FastMM5 by passing callbacks here)
png_create_write_struct_2: function(user_png_ver: png_charp;
  error_ptr: png_voidp; error_fn: png_error_ptr; warn_fn: png_error_ptr;
  mem_ptr: png_voidp; malloc_fn: png_malloc_ptr; free_fn: png_free_ptr): png_structp; cdecl;

(* Allocate the memory for an info_struct for the application.  We don't
 * really need the png_ptr, but it could potentially be useful in the
 * future.  This should be used in favour of malloc(png_sizeof(png_info))
 * and png_info_init() so that applications that want to use a shared
 * libpng don't have to be recompiled if png_info changes size.
 *)
png_create_info_struct: function(png_ptr: png_structp): png_infop; cdecl;

(* Replace the default data output functions with a user supplied one(s).
 * If buffered output is not used, then output_flush_fn can be set to NULL.
 * If PNG_WRITE_FLUSH_SUPPORTED is not defined at libpng compile time
 * output_flush_fn will be ignored (and thus can be NULL).
 * It is probably a mistake to use NULL for output_flush_fn if
 * write_data_fn is not also NULL unless you have built libpng with
 * PNG_WRITE_FLUSH_SUPPORTED undefined, because in this case libpng's
 * default flush function, which uses the standard *FILE structure, will
 * be used.
 *)
png_set_write_fn: procedure(png_ptr: png_structp; io_ptr: png_voidp;
  write_data_fn: png_rw_ptr; output_flush_fn: png_flush_ptr);  cdecl;

png_set_IHDR: procedure(png_ptr: png_structp; info_ptr: png_infop;
  width, height: png_uint_32; bit_depth, color_type, interlace_type,
  compression_type, filter_type: int); cdecl;

// Writes all the PNG information before the image.
png_write_info: procedure(png_ptr: png_structp; info_ptr: png_infop); cdecl;

// Write a row of image data
png_write_row: procedure(png_ptr: png_structp; row: png_bytep); cdecl;

// Writes the end of the PNG file.
png_write_end: procedure(png_ptr: png_structp; info_ptr: png_infop); cdecl;

// Free data that was allocated internally
png_free_data: procedure(png_ptr: png_structp; info_ptr: png_infop; num: int); cdecl;

// Free any memory associated with the png_struct and the png_info_structs
png_destroy_write_struct: procedure(png_ptr_ptr: png_structpp;
  info_ptr_ptr: png_infopp); cdecl;

(* Set the library compression level.  Currently, valid values range from
 * 0 - 9, corresponding directly to the zlib compression levels 0 - 9
 * (0 - no compression, 9 - "maximal" compression).  Note that tests have
 * shown that zlib compression levels 3-6 usually perform as well as level 9
 * for PNG images, and do considerably fewer caclulations.  In the future,
 * these values may not correspond directly to the zlib compression levels.
 *)
png_set_compression_level: procedure(png_ptr: png_structp; level: int); cdecl;

// Use 1 byte per pixel in 1, 2, or 4-bit depth files.
png_set_packing: procedure(png_ptr: png_structp); cdecl;

png_set_gAMA: procedure(png_ptr: png_structp; info_ptr: png_infop; file_gamma: double); cdecl;

png_set_sRGB: procedure(png_ptr: png_structp; info_ptr: png_infop; srgb_intent: int); cdecl;

(* Set the filtering method(s) used by libpng.  Currently, the only valid
 * value for "method" is 0.
 *)
png_set_filter: procedure(png_ptr: png_structp; method, filters: int); cdecl;

(* png_set_PLTE() shall set the array of color values used as palette for image
* to "palette". The palette shall include "num_palette" entries.
*)
png_set_PLTE: procedure(png_ptr: png_structp; info_ptr: png_infop;
  palette: png_const_colorp; num_palette: int); cdecl;

(* png_set_tRNS() shall set the transparency data for paletted images and image
* types that don't need a full alpha channel. For a paletted image,
* png_set_tRNS() shall set the array of transparency values for the palette
* colors to "trans_alpha". The number of transparency entries is given by "num_trans".
* For non-paletted images, png_set_tRNS() shall set the single color value or
* graylevel to "trans_color"
*)
png_set_tRNS: procedure(png_ptr: png_structp; info_ptr: png_infop;
  trans_alpha: png_const_bytep; num_trans: int;
  trans_color: png_const_color_16p); cdecl;

// Return the user pointer associated with the I/O functions
png_get_io_ptr: function(const png_ptr: png_structp): png_voidp; cdecl;

// Returns image width in pixels
png_get_image_width: function(png_ptr: png_structp; info_ptr: png_infop): png_uint_32; cdecl;

// Returns image height in pixels
png_get_image_height: function(png_ptr: png_structp; info_ptr: png_infop): png_uint_32; cdecl;

// Reading and Information
  png_create_read_struct_2: function(user_png_ver: png_charp;
    error_ptr: png_voidp; error_fn: png_error_ptr; warn_fn: png_error_ptr;
    mem_ptr: png_voidp; malloc_fn: png_malloc_ptr; free_fn: png_free_ptr): png_structp; cdecl;

  png_read_info: procedure(png_ptr: png_structp; info_ptr: png_infop); cdecl;
  png_read_image: procedure(png_ptr: png_structp; image: png_bytepp); cdecl;
  png_read_end: procedure(png_ptr: png_structp; info_ptr: png_infop); cdecl;
  png_set_read_fn: procedure(png_ptr: png_structp; io_ptr: png_voidp; read_data_fn: png_rw_ptr); cdecl;
  png_read_update_info: procedure(png_ptr: png_structp; info_ptr: png_infop); cdecl;

// Free memory associated with the png_struct and the png_info structs for reading
  png_destroy_read_struct: procedure(png_ptr_ptr: png_structpp;
    info_ptr_ptr: png_infopp; end_info_ptr_ptr: png_infopp); cdecl;

  // High-performance Transforms (Let the DLL do the work via SIMD)
  png_set_expand: procedure(png_ptr: png_structp); cdecl;
  png_set_palette_to_rgb: procedure(png_ptr: png_structp); cdecl;
  png_set_expand_gray_1_2_4_to_8: procedure(png_ptr: png_structp); cdecl;
  png_set_tRNS_to_alpha: procedure(png_ptr: png_structp); cdecl;
  png_set_gray_to_rgb: procedure(png_ptr: png_structp); cdecl;
  png_set_bgr: procedure(png_ptr: png_structp); cdecl;
  png_set_filler: procedure(png_ptr: png_structp; filler: png_uint_32; flags: int); cdecl;
  png_set_strip_16: procedure(png_ptr: png_structp); cdecl;

  // Getters
  png_get_valid: function(png_ptr: png_structp; info_ptr: png_infop; flag: png_uint_32): png_uint_32; cdecl;
  png_get_rowbytes: function(png_ptr: png_structp; info_ptr: png_infop): png_size_t; cdecl;
  png_get_bit_depth: function(png_ptr: png_structp; info_ptr: png_infop): png_byte; cdecl;
  png_get_color_type: function(png_ptr: png_structp; info_ptr: png_infop): png_byte; cdecl;

const
  // Constants for transforms
  PNG_FILLER_BEFORE = 0;
  PNG_FILLER_AFTER = 1;
  PNG_INFO_tRNS = $0010;

const
  libpng_dll = 'libpng18.dll';

procedure InitLibPng(const ALibName: string = libpng_dll);

implementation

uses
  Windows,
  SysUtils,
  SyncObjs;

var
  GHandle: THandle = 0;
  GLock: TCriticalSection = nil;
  GIsInitialized: Boolean = False;

procedure UnloadLib; forward;

procedure InitLibPng(const ALibName: string);

  function GetProcAddr(const AProcName: PAnsiChar): Pointer;
  begin
    Result := GetProcAddress(GHandle, AProcName);
    if Result = nil then begin
      raise Exception.CreateFmt('Unable to find "%s" in %s', [AProcName, ALibName]);
    end;
  end;

begin
  if GIsInitialized then begin
    Exit;
  end;

  GLock.Acquire;
  try
    if GIsInitialized then begin
      Exit;
    end;

    if GHandle = 0 then begin
      GHandle := SafeLoadLibrary(PChar(ALibName));
      if GHandle = 0 then begin
        raise Exception.CreateFmt(
          'Unable to load library %s - %s', [ALibName, SysErrorMessage(GetLastError)]
        );
      end;
    end;

    try
      png_get_libpng_ver := GetProcAddr('png_get_libpng_ver');
      png_create_write_struct := GetProcAddr('png_create_write_struct');
      png_create_write_struct_2 := GetProcAddr('png_create_write_struct_2');
      png_create_info_struct := GetProcAddr('png_create_info_struct');
      png_set_write_fn := GetProcAddr('png_set_write_fn');
      png_set_IHDR := GetProcAddr('png_set_IHDR');
      png_write_info := GetProcAddr('png_write_info');
      png_write_row := GetProcAddr('png_write_row');
      png_write_end := GetProcAddr('png_write_end');
      png_free_data := GetProcAddr('png_free_data');
      png_destroy_write_struct := GetProcAddr('png_destroy_write_struct');
      png_set_compression_level := GetProcAddr('png_set_compression_level');
      png_set_packing := GetProcAddr('png_set_packing');
      png_set_gAMA := GetProcAddr('png_set_gAMA');
      png_set_sRGB := GetProcAddr('png_set_sRGB');
      png_set_filter := GetProcAddr('png_set_filter');
      png_set_PLTE := GetProcAddr('png_set_PLTE');
      png_set_tRNS := GetProcAddr('png_set_tRNS');
      png_get_io_ptr := GetProcAddr('png_get_io_ptr');
      png_get_image_width := GetProcAddr('png_get_image_width');
      png_get_image_height := GetProcAddr('png_get_image_height');

      png_create_read_struct_2 := GetProcAddr('png_create_read_struct_2');
      png_read_info := GetProcAddr('png_read_info');
      png_read_image := GetProcAddr('png_read_image');
      png_read_end := GetProcAddr('png_read_end');
      png_set_read_fn := GetProcAddr('png_set_read_fn');
      png_read_update_info := GetProcAddr('png_read_update_info');

      png_destroy_read_struct := GetProcAddr('png_destroy_read_struct');

      png_set_expand := GetProcAddr('png_set_expand');
      png_set_palette_to_rgb := GetProcAddr('png_set_palette_to_rgb');
      png_set_expand_gray_1_2_4_to_8 := GetProcAddr('png_set_expand_gray_1_2_4_to_8');
      png_set_tRNS_to_alpha := GetProcAddr('png_set_tRNS_to_alpha');
      png_set_gray_to_rgb := GetProcAddr('png_set_gray_to_rgb');
      png_set_bgr := GetProcAddr('png_set_bgr');
      png_set_filler := GetProcAddr('png_set_filler');
      png_set_strip_16 := GetProcAddr('png_set_strip_16');

      png_get_valid := GetProcAddr('png_get_valid');
      png_get_rowbytes := GetProcAddr('png_get_rowbytes');
      png_get_bit_depth := GetProcAddr('png_get_bit_depth');
      png_get_color_type := GetProcAddr('png_get_color_type');

      GIsInitialized := True;
    except
      UnloadLib;
      raise;
    end;
  finally
    GLock.Release;
  end;
end;

procedure UnloadLib;
begin
  GLock.Acquire;
  try
    if GHandle <> 0 then begin
      FreeLibrary(GHandle);
      GHandle := 0;
    end;

    png_get_libpng_ver := nil;
    png_create_write_struct := nil;
    png_create_write_struct_2 := nil;
    png_create_info_struct := nil;
    png_set_write_fn := nil;
    png_set_IHDR := nil;
    png_write_info := nil;
    png_write_row := nil;
    png_write_end := nil;
    png_free_data := nil;
    png_destroy_write_struct := nil;
    png_set_compression_level := nil;
    png_set_packing := nil;
    png_set_gAMA := nil;
    png_set_sRGB := nil;
    png_set_filter := nil;
    png_set_PLTE := nil;
    png_set_tRNS := nil;
    png_get_io_ptr := nil;
    png_get_image_width := nil;
    png_get_image_height := nil;

    png_create_read_struct_2 := nil;
    png_read_info := nil;
    png_read_image := nil;
    png_read_end := nil;
    png_set_read_fn := nil;
    png_read_update_info := nil;

    png_destroy_read_struct := nil;

    png_set_expand := nil;
    png_set_palette_to_rgb := nil;
    png_set_expand_gray_1_2_4_to_8 := nil;
    png_set_tRNS_to_alpha := nil;
    png_set_gray_to_rgb := nil;
    png_set_bgr := nil;
    png_set_filler := nil;
    png_set_strip_16 := nil;

    png_get_valid := nil;
    png_get_rowbytes := nil;
    png_get_bit_depth := nil;
    png_get_color_type := nil;
  finally
    GIsInitialized := False;
    GLock.Release;
  end;
end;

initialization
  GLock := TCriticalSection.Create;

finalization
  UnloadLib;
  FreeAndNil(GLock);

end.

