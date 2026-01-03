unit Helpers;

interface

uses
  Winapi.Windows,
  System.Win.Registry,
  Winapi.ActiveX,
  Winapi.ShlObj,
  ACL.Utils.Registry,
  System.SysUtils;

function LooksLikeBinary(const Buf; Size: Integer): Boolean;

implementation

const
  BOM_UTF8:    array[0..2] of Byte = ($EF,$BB,$BF);
  BOM_UTF16LE: array[0..1] of Byte = ($FF,$FE);
  BOM_UTF16BE: array[0..1] of Byte = ($FE,$FF);


function LooksLikeBinary(const Buf; Size: Integer): Boolean;
var
  P: PByte;
  I: Integer;
begin
  Result := False;
  P := @Buf;
  for I := 0 to Size - 1 do
  begin
    if P^ = 0 then
      Exit(True);
    Inc(P);
  end;
end;

function LooksLikeText(const Buf; Size: Integer): Boolean;
var
  P: PByte;
  I, Bad: Integer;
begin
  Bad := 0;
  P := @Buf;

  for I := 0 to Size - 1 do
  begin
    // Allow common whitespace + printable ASCII
    if not (
      (P^ = 9) or   // TAB
      (P^ = 10) or  // LF
      (P^ = 13) or  // CR
      (P^ >= 32)
    ) then
      Inc(Bad);

    Inc(P);
  end;

  // >5% control junk? not text
  Result := (Bad * 100 div Size) < 5;
end;



procedure WriteKey(
  const Root: HKEY;
  const KeyPath: string;
  const Caption: string;
  const IconPath: string;
  const Command: string
);
var
  Key: HKEY;
begin
  if RegCreateKeyExW(
       Root,
       PWideChar(KeyPath),
       0,
       nil,
       REG_OPTION_NON_VOLATILE,
       KEY_WRITE,
       nil,
       Key,
       nil
     ) <> ERROR_SUCCESS then
    RaiseLastOSError;

  try
    if Caption <> '' then
      RegSetValueExW(
        Key,
        nil,
        0,
        REG_SZ,
        PByte(PWideChar(Caption)),
        (Length(Caption) + 1) * SizeOf(WideChar)
      );

    if IconPath <> '' then
      RegSetValueExW(
        Key,
        'Icon',
        0,
        REG_SZ,
        PByte(PWideChar(IconPath)),
        (Length(IconPath) + 1) * SizeOf(WideChar)
      );

    if Command <> '' then
    begin
      RegCloseKey(Key);
      if RegCreateKeyExW(
           Root,
           PWideChar(KeyPath + '\command'),
           0,
           nil,
           REG_OPTION_NON_VOLATILE,
           KEY_WRITE,
           nil,
           Key,
           nil
         ) <> ERROR_SUCCESS then
        RaiseLastOSError;

      RegSetValueExW(
        Key,
        nil,
        0,
        REG_SZ,
        PByte(PWideChar(Command)),
        (Length(Command) + 1) * SizeOf(WideChar)
      );
    end;
  finally
    RegCloseKey(Key);
  end;
end;

procedure RegisterFilePilotContextMenus(const ExePath: string);
var
  CmdFile: string;
  CmdHere: string;
begin
  CmdFile := '"' + ExePath + '" "%1"';
  CmdHere := '"' + ExePath + '" "%V"';

  // Directory
  WriteKey(
    HKEY_CURRENT_USER,
    'Software\Classes\Directory\shell\OpenInFilePilot',
    'Open in File Pilot',
    ExePath,
    CmdFile
  );

  // All files
  WriteKey(
    HKEY_CURRENT_USER,
    'Software\Classes\*\shell\OpenInFilePilot',
    'Open in File Pilot',
    ExePath,
    CmdFile
  );

  // Desktop background
  WriteKey(
    HKEY_CURRENT_USER,
    'Software\Classes\DesktopBackground\shell\FilePilotHere',
    'File Pilot here',
    ExePath,
    CmdHere
  );

  // Directory background
  WriteKey(
    HKEY_CURRENT_USER,
    'Software\Classes\Directory\Background\shell\FilePilotHere',
    'File Pilot here',
    ExePath,
    CmdHere
  );
end;

procedure DeleteKeyTreeSafe(Root: HKEY; const KeyPath: string);
var
  Status: Longint;
begin
  // Available since Vista
////  Status := RegDeleteTreeW(Root, PWideChar(KeyPath));

  // Treat "not found" as success
  if (Status <> ERROR_SUCCESS) and (Status <> ERROR_FILE_NOT_FOUND) then
    RaiseLastOSError(Status);
end;

procedure UnregisterFilePilotContextMenus;
begin
  DeleteKeyTreeSafe(
    HKEY_CURRENT_USER,
    'Software\Classes\Directory\shell\OpenInFilePilot'
  );

  DeleteKeyTreeSafe(
    HKEY_CURRENT_USER,
    'Software\Classes\*\shell\OpenInFilePilot'
  );

  DeleteKeyTreeSafe(
    HKEY_CURRENT_USER,
    'Software\Classes\DesktopBackground\shell\FilePilotHere'
  );

  DeleteKeyTreeSafe(
    HKEY_CURRENT_USER,
    'Software\Classes\Directory\Background\shell\FilePilotHere'
  );
end;

procedure RefreshExplorer;
begin
  SHChangeNotify(SHCNE_ASSOCCHANGED, SHCNF_IDLIST, nil, nil);
end;

///////////////////////////////////////
procedure WriteDefaultValue(
  Root: HKEY;
  const KeyPath: string;
  const Value: string
);
var
  Key: HKEY;
begin
  if RegCreateKeyExW(
       Root,
       PWideChar(KeyPath),
       0,
       nil,
       REG_OPTION_NON_VOLATILE,
       KEY_WRITE,
       nil,
       Key,
       nil
     ) <> ERROR_SUCCESS then
    RaiseLastOSError;

  try
    RegSetValueExW(
      Key,
      nil,
      0,
      REG_SZ,
      PByte(PWideChar(Value)),
      (Length(Value) + 1) * SizeOf(WideChar)
    );
  finally
    RegCloseKey(Key);
  end;
end;

procedure WriteDelegateExecuteEmpty(
  Root: HKEY;
  const KeyPath: string
);
var
  Key: HKEY;
  Empty: WideChar;
begin
  Empty := #0;

  if RegCreateKeyExW(
       Root,
       PWideChar(KeyPath),
       0,
       nil,
       REG_OPTION_NON_VOLATILE,
       KEY_WRITE,
       nil,
       Key,
       nil
     ) <> ERROR_SUCCESS then
    RaiseLastOSError;

  try
    RegSetValueExW(
      Key,
      'DelegateExecute',
      0,
      REG_SZ,
      @Empty,
      SizeOf(WideChar)
    );
  finally
    RegCloseKey(Key);
  end;
end;

procedure SetShellOpenCommands(const ExePath: string);
var
  Command: string;
begin
  Command := '"' + ExePath + '" "%1"';

  // Drive open
  WriteDefaultValue(
    HKEY_CURRENT_USER,
    'Software\Classes\Drive\shell',
    'open'
  );

  WriteDefaultValue(
    HKEY_CURRENT_USER,
    'Software\Classes\Drive\shell\open\command',
    Command
  );

  // Directory open
  WriteDefaultValue(
    HKEY_CURRENT_USER,
    'Software\Classes\Directory\shell',
    'open'
  );

  WriteDefaultValue(
    HKEY_CURRENT_USER,
    'Software\Classes\Directory\shell\open\command',
    Command
  );

  // Explorer "Open in new window"
  WriteDefaultValue(
    HKEY_CURRENT_USER,
    'Software\Classes\CLSID\{52205fd8-5dfb-447d-801a-d0b52f2e83e1}\shell\opennewwindow\command',
    Command
  );

  WriteDelegateExecuteEmpty(
    HKEY_CURRENT_USER,
    'Software\Classes\CLSID\{52205fd8-5dfb-447d-801a-d0b52f2e83e1}\shell\opennewwindow\command'
  );
end;


function ReadDefaultValue(Root: HKEY; const KeyPath: string): string;
var
  Key: HKEY;
  BufSize, RegType: DWORD;
begin
  Result := '';

  if RegOpenKeyExW(Root, PWideChar(KeyPath), 0, KEY_READ, Key) <> ERROR_SUCCESS then
    Exit;

  try
    BufSize := 0;
    if RegQueryValueExW(Key, nil, nil, @RegType, nil, @BufSize) <> ERROR_SUCCESS then
      Exit;

    if RegType <> REG_SZ then
      Exit;

    SetLength(Result, BufSize div SizeOf(WideChar));
    RegQueryValueExW(Key, nil, nil, nil, PByte(PWideChar(Result)), @BufSize);
    Result := PWideChar(Result); // trim null
  finally
    RegCloseKey(Key);
  end;
end;

procedure DeleteKeyIfOwned(
  Root: HKEY;
  const KeyPath: string;
  const ExpectedCommand: string
);
var
  Current: string;
begin
  Current := ReadDefaultValue(Root, KeyPath);

//  if SameText(Current, ExpectedCommand) then
//    RegDeleteTreeW(Root, PWideChar(KeyPath));
end;

procedure DeleteValueIfExists(
  Root: HKEY;
  const KeyPath, ValueName: string
);
var
  Key: HKEY;
begin
  if RegOpenKeyExW(Root, PWideChar(KeyPath), 0, KEY_SET_VALUE, Key) <> ERROR_SUCCESS then
    Exit;

  try
    RegDeleteValueW(Key, PWideChar(ValueName));
  finally
    RegCloseKey(Key);
  end;
end;

procedure UnsetShellOpenCommands(const ExePath: string);
var
  Command: string;
begin
  Command := '"' + ExePath + '" "%1"';

  // Drive
  DeleteKeyIfOwned(
    HKEY_CURRENT_USER,
    'Software\Classes\Drive\shell\open\command',
    Command
  );

  // Directory
  DeleteKeyIfOwned(
    HKEY_CURRENT_USER,
    'Software\Classes\Directory\shell\open\command',
    Command
  );

  // Explorer "Open in new window"
  DeleteKeyIfOwned(
    HKEY_CURRENT_USER,
    'Software\Classes\CLSID\{52205fd8-5dfb-447d-801a-d0b52f2e83e1}\shell\opennewwindow\command',
    Command
  );

  DeleteValueIfExists(
    HKEY_CURRENT_USER,
    'Software\Classes\CLSID\{52205fd8-5dfb-447d-801a-d0b52f2e83e1}\shell\opennewwindow\command',
    'DelegateExecute'
  );
end;

//procedure DeleteKeyTreeSafe(Root: HKEY; const KeyPath: string);
//var
//  Status: Longint;
//begin
//  Status := RegDeleteTreeW(Root, PWideChar(KeyPath));
//  if (Status <> ERROR_SUCCESS) and (Status <> ERROR_FILE_NOT_FOUND) then
//    RaiseLastOSError(Status);
//end;
procedure RestoreExplorerOpenVerb;
begin
  // Directory
  DeleteKeyTreeSafe(
    HKEY_CURRENT_USER,
    'Software\Classes\Directory\shell\open'
  );

  // Drive
  DeleteKeyTreeSafe(
    HKEY_CURRENT_USER,
    'Software\Classes\Drive\shell\open'
  );

  // Explorer "open new window" CLSID override
  DeleteKeyTreeSafe(
    HKEY_CURRENT_USER,
    'Software\Classes\CLSID\{52205fd8-5dfb-447d-801a-d0b52f2e83e1}'
  );
end;



end.
