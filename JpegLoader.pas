unit JpegLoader;

interface

uses
  Windows, SysUtils, Classes, GR32, LibTurboJPEG;

// Loads a JPEG file directly into a TBitmap32
procedure LoadJpegFast(const Filename: string; DestBitmap: TBitmap32);

implementation

//procedure LoadJpegFast(const Filename: string; DestBitmap: TBitmap32);
//var
//  Stream: TMemoryStream;
//  Decompressor: TJHandle;
//  JpegSize: Cardinal;
//  Width, Height, SubSamp, ColorSpace: Integer;
//  Res: Integer;
//begin
//  InitLibTurboJPEG;
//
//  Stream := TMemoryStream.Create;
//  try
//    Stream.LoadFromFile(Filename);
//    JpegSize := Stream.Size;
//    if JpegSize = 0 then Exit;
//
//    // 1. Initialize Decompressor
//    Decompressor := tjInitDecompress();
//    if Decompressor = nil then
//      raise Exception.Create('Failed to initialize TurboJPEG decompressor');
//
//    try
//      // 2. Read Header (Width/Height)
//      // We pass the memory pointer directly from the stream
//      Res := tjDecompressHeader3(Decompressor, PByte(Stream.Memory), JpegSize,
//        @Width, @Height, @SubSamp, @ColorSpace);
//
//      if Res <> 0 then
//        raise Exception.CreateFmt('TurboJPEG Header Error: %s', [tjGetErrorStr2(Decompressor)]);
//
//      // 3. Prepare Graphics32 Bitmap
//      DestBitmap.SetSize(Width, Height);
//
//      // 4. Decompress directly to Bitmap memory
//      // TJPF_BGRA matches Graphics32 native format (B, G, R, Alpha).
//      // TJFLAG_ACCURATEDCT ensures high quality (use TJFLAG_FASTDCT for speed over quality)
//      // TJFLAG_BOTTOMUP is NOT used because GR32 usually expects top-down logical rows
//      // (though it stores them in memory top-down, passing Bits gives top-left pixel).
//
//      Res := tjDecompress2(
//        Decompressor,
//        PByte(Stream.Memory),
//        JpegSize,
//        PByte(DestBitmap.Bits), // Write directly to GR32 memory
//        Width,
//        0, // Pitch: 0 = Let TurboJPEG calc it (Width * 4) which matches GR32
//        Height,
//        TJPF_BGRA, // Direct mapping to TBitmap32
//        TJFLAG_ACCURATEDCT
//      );
//
//      if Res <> 0 then
//        raise Exception.CreateFmt('TurboJPEG Decompress Error: %s', [tjGetErrorStr2(Decompressor)]);
//
//      // 5. Clean alpha channel
//      // JPEGs don't have alpha. TurboJPEG might set Alpha byte to 0 or 255 depending on implementation.
//      // GR32 needs Alpha=255 (Opaque) to be visible.
//      // Since TJPF_BGRA sets Alpha to 0xFF (255) usually, this is fine.
//      // If you see transparent images, un-comment the line below:
//      // DestBitmap.SetAlpha255;
//
//      DestBitmap.Changed;
//
//    finally
//      tjDestroy(Decompressor);
//    end;
//
//  finally
//    Stream.Free;
//  end;
//end;
procedure LoadJpegFast(const Filename: string; DestBitmap: TBitmap32);
var
  Stream: TMemoryStream;
  Decompressor: TJHandle;
  JpegSize: Cardinal;
  Width, Height, SubSamp, ColorSpace: Integer;
  Res: Integer;
  DestBuffer: PByte;
  Pitch: Integer;
begin
  InitLibTurboJPEG; // Ensure DLL is loaded

  Stream := TMemoryStream.Create;
  try
    Stream.LoadFromFile(Filename);
    Stream.Position := 0;
    JpegSize := Stream.Size;

    if JpegSize = 0 then Exit;

    // 1. Initialize Decompressor
    Decompressor := tjInitDecompress();
    if Decompressor = nil then
      raise Exception.Create('Failed to initialize TurboJPEG decompressor');

    try
      // 2. Read Header
      Res := tjDecompressHeader3(Decompressor, PByte(Stream.Memory), JpegSize,
        @Width, @Height, @SubSamp, @ColorSpace);

      if Res <> 0 then
        raise Exception.CreateFmt('TurboJPEG Header Error: %s', [tjGetErrorStr2(Decompressor)]);

      if (Width <= 0) or (Height <= 0) then Exit;

      // 3. Prepare Graphics32 Bitmap
      DestBitmap.SetSize(Width, Height);

      // Get the raw pointer to the bitmap bits
      DestBuffer := PByte(DestBitmap.Bits);
      if DestBuffer = nil then
        raise Exception.Create('Failed to allocate bitmap memory');

      // 4. Calculate Pitch (Stride) explicitly
      // GR32 uses 4 bytes per pixel (BGRA).
      Pitch := Width * 4;

      // 5. Decompress
      // Note: We cast TJPF_BGRA to Integer(8) to ensure correct ABI value is passed
      Res := tjDecompress2(
        Decompressor,
        PByte(Stream.Memory),
        JpegSize,
        DestBuffer,
        Width,
        Pitch,      // Explicit pitch prevents ambiguity
        Height,
        Integer(TJPF_BGRA), // Pass as explicit Integer (Value 8)
        TJFLAG_ACCURATEDCT
      );

      if Res <> 0 then
        raise Exception.CreateFmt('TurboJPEG Decompress Error: %s', [tjGetErrorStr2(Decompressor)]);

      // 6. Notify GR32 of change
      DestBitmap.Changed;

    finally
      tjDestroy(Decompressor);
    end;

  finally
    Stream.Free;
  end;
end;

end.
