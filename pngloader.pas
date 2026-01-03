unit pngloader;

interface

uses
  Windows, SysUtils, Classes, GR32, LibPng;

// Loads a PNG file directly into a TBitmap32 using FastMM optimizations
procedure LoadPngFast(const Filename: string; DestBitmap: TBitmap32);

implementation

// -----------------------------------------------------------------------------
// FastMM5 Callbacks
// These allow libpng to allocate its internal buffers on the Delphi Heap,
// improving performance and preventing heap fragmentation.
// -----------------------------------------------------------------------------
function PngMalloc(png_ptr: png_structp; size: png_size_t): png_voidp; cdecl;
begin
  GetMem(Result, size);
end;

procedure PngFree(png_ptr: png_structp; ptr: png_voidp); cdecl;
begin
  FreeMem(ptr);
end;

// -----------------------------------------------------------------------------
// I/O Callback
// Reads data from a TStream passed as io_ptr
// -----------------------------------------------------------------------------
procedure PngReadData(png_ptr: png_structp; data: png_bytep; length: png_size_t); cdecl;
var
  Stream: TStream;
begin
  Stream := TStream(png_get_io_ptr(png_ptr));
  if Stream.Read(data^, length) <> length then
    raise Exception.Create('Read error in PNG stream');
end;

// -----------------------------------------------------------------------------
// Error Handler
// LibPng uses longjmp on errors. We must intercept this to prevent crashing.
// Note: Raising exceptions across DLL boundaries requires care, but for
// reading it is usually safe enough to bail out.
// -----------------------------------------------------------------------------
procedure PngErrorFn(png_ptr: png_structp; msg: png_charp); cdecl;
begin
  raise Exception.CreateFmt('LibPng Error: %s', [msg]);
end;

procedure PngWarnFn(png_ptr: png_structp; msg: png_charp); cdecl;
begin
  // Uncomment to log warnings if needed
  // OutputDebugString(PChar('LibPng Warning: ' + string(msg)));
end;

// -----------------------------------------------------------------------------
// Main Loading Function
// -----------------------------------------------------------------------------
//procedure LoadPngFast(const Filename: string; DestBitmap: TBitmap32);
//var
//  Stream: TMemoryStream;
//  png: png_structp;
//  info: png_infop;
//  Width, Height: png_uint_32;
//  BitDepth, ColorType: Integer;
//  RowPointers: array of png_bytep;
//  Y: Integer;
//begin
//  // Initialize the DLL functions if not already done
//  InitLibPng;
//
//  Stream := TMemoryStream.Create;
//  try
//    Stream.LoadFromFile(Filename); // Load entire file to memory for speed
//
//    // 1. Initialize Read Structure with FastMM allocators
//    png := png_create_read_struct_2(PNG_LIBPNG_VER_STRING,
//      nil, @PngErrorFn, @PngWarnFn, // Error handling
//      nil, @PngMalloc, @PngFree);   // Memory handling
//
//    if png = nil then
//      raise Exception.Create('Failed to create libpng read struct');
//
//    info := png_create_info_struct(png);
//    if info = nil then
//    begin
//      png_destroy_read_struct(@png, nil, nil);
//      raise Exception.Create('Failed to create libpng info struct');
//    end;
//
//    try
//      // 2. Set Input Source
//      png_set_read_fn(png, Stream, @PngReadData);
//
//      // 3. Read Header
//      png_read_info(png, info);
//
//      Width := png_get_image_width(png, info);
//      Height := png_get_image_height(png, info);
//      BitDepth := png_get_bit_depth(png, info);
//      ColorType := png_get_color_type(png, info);
//
//      // 4. Configure Transforms
//      // The goal is to make libpng output BGRA 32-bit data directly
//      // regardless of the input format (Paletted, Gray, RGB, etc.)
//
//      // Expand Paletted colors to RGB
//      if ColorType = PNG_COLOR_TYPE_PALETTE then
//        png_set_palette_to_rgb(png);
//
//      // Expand Grayscale to 8-bit
//      if (ColorType = PNG_COLOR_TYPE_GRAY) and (BitDepth < 8) then
//        png_set_expand_gray_1_2_4_to_8(png);
//
//      // Expand Transparency chunk to Alpha channel
//      if png_get_valid(png, info, PNG_INFO_tRNS) <> 0 then
//        png_set_tRNS_to_alpha(png);
//
//      // Convert Grayscale to RGB
//      if (ColorType = PNG_COLOR_TYPE_GRAY) or (ColorType = PNG_COLOR_TYPE_GRAY_ALPHA) then
//        png_set_gray_to_rgb(png);
//
//      // Reduce 16-bit to 8-bit (GR32 is 8-bit per channel)
//      if BitDepth = 16 then
//        png_set_strip_16(png);
//
//      // Add Alpha channel if missing (RGB -> RGBA)
//      // GR32 uses opaque alpha (255) by default.
//      if not (ColorType in [PNG_COLOR_TYPE_RGB_ALPHA, PNG_COLOR_TYPE_GRAY_ALPHA]) then
//        png_set_filler(png, $FF, PNG_FILLER_AFTER); // Add 0xFF filler at end
//
//      // Swap R and B (PNG is RGB, GR32 is BGR)
//      png_set_bgr(png);
//
//      // Update info struct to reflect the transforms
//      png_read_update_info(png, info);
//
//      // 5. Prepare TBitmap32
//      DestBitmap.SetSize(Width, Height);
//
//      // 6. Setup Row Pointers for Direct Reading
//      // We map the row pointers directly to TBitmap32's internal memory.
//      // This eliminates an intermediate buffer copy.
//      SetLength(RowPointers, Height);
//
//      for Y := 0 to Height - 1 do
//        RowPointers[Y] := png_bytep(DestBitmap.ScanLine[Y]);
//
//      // 7. Decode Image
//      png_read_image(png, @RowPointers[0]);
//      png_read_end(png, nil);
//
//    finally
//      png_destroy_read_struct(@png, @info, nil);
//    end;
//
//  finally
//    Stream.Free;
//  end;
//end;

procedure LoadPngFast(const Filename: string; DestBitmap: TBitmap32);
var
  Stream: TMemoryStream;
  png: png_structp;
  info: png_infop;
  Width, Height: png_uint_32;
  BitDepth, ColorType: Integer;
  RowPointers: array of png_bytep;
  Y: Integer;
begin
  InitLibPng; // Ensure DLL is loaded

  Stream := TMemoryStream.Create;
  try
    Stream.LoadFromFile(Filename);
    Stream.Position := 0; // <--- IMPORTANT: Ensure we start at the beginning

    // 1. Init LibPng with Custom Memory Allocators
    png := png_create_read_struct_2(PNG_LIBPNG_VER_STRING,
      nil, @PngErrorFn, @PngWarnFn, // Error handlers
      nil, @PngMalloc, @PngFree);   // FastMM allocators

    if png = nil then
      raise Exception.Create('Failed to initialize libpng');

    info := png_create_info_struct(png);
    if info = nil then
    begin
      // If info creation fails, we must destroy the png struct manually
      png_destroy_read_struct(@png, nil, nil);
      raise Exception.Create('Failed to initialize PNG info');
    end;

    try
      // 2. Setup Input
      png_set_read_fn(png, Stream, @PngReadData);

      // 3. Read Info
      png_read_info(png, info);

      Width := png_get_image_width(png, info);
      Height := png_get_image_height(png, info);
      BitDepth := png_get_bit_depth(png, info);
      ColorType := png_get_color_type(png, info);

      // 4. Setup Transforms (Force BGRA 32-bit output)

      // Convert Paletted -> RGB
      if ColorType = PNG_COLOR_TYPE_PALETTE then
        png_set_palette_to_rgb(png);

      // Convert Grayscale < 8-bit -> 8-bit
      if (ColorType = PNG_COLOR_TYPE_GRAY) and (BitDepth < 8) then
        png_set_expand_gray_1_2_4_to_8(png);

      // Expand Transparency Chunk -> Alpha Channel
      if png_get_valid(png, info, PNG_INFO_tRNS) <> 0 then
        png_set_tRNS_to_alpha(png);

      // Convert Grayscale -> RGB
      if (ColorType = PNG_COLOR_TYPE_GRAY) or (ColorType = PNG_COLOR_TYPE_GRAY_ALPHA) then
        png_set_gray_to_rgb(png);

      // Reduce 16-bit -> 8-bit (Speed over accuracy)
      if BitDepth = 16 then
        png_set_strip_16(png);

      // Add Alpha channel if missing (RGB -> RGBA)
      // 0xFF means fully opaque alpha for inserted pixels
      if not (ColorType in [PNG_COLOR_TYPE_RGB_ALPHA, PNG_COLOR_TYPE_GRAY_ALPHA]) then
        png_set_filler(png, $FF, PNG_FILLER_AFTER);

      // Swap R and B (PNG is RGBA, Windows/GR32 is BGRA)
      png_set_bgr(png);

      // Apply transforms to update info struct
      png_read_update_info(png, info);

      // 5. Prepare Graphics32 Bitmap
      DestBitmap.SetSize(Width, Height);

      // 6. Map Rows directly to Bitmap Memory
      // Note: We cast PColor32Array (GR32) to png_bytep (libpng)
      SetLength(RowPointers, Height);
      for Y := 0 to Height - 1 do
        RowPointers[Y] := png_bytep(DestBitmap.ScanLine[Y]);

      // 7. Decode directly into TBitmap32 memory
      png_read_image(png, @RowPointers[0]);
      png_read_end(png, nil);

      // 8. IMPORTANT: Notify Graphics32 that data changed
      // This is required because we bypassed TBitmap32 methods and wrote to memory directly.
      DestBitmap.Changed;

    finally
      // 9. Cleanup LibPng memory
      png_destroy_read_struct(@png, @info, nil);
    end;

  finally
    Stream.Free;
  end;
end;

end.