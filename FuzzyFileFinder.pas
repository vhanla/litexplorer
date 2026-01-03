unit FuzzyFileFinder;

interface

uses
  System.SysUtils,
  System.Classes,
  System.Threading,
  System.SyncObjs,
  System.Generics.Collections,
  System.Generics.Defaults;

type
  TFileItem = record
    Path: string;
    FileNameLow: string;
    RelativePathLow: string;
    CharMask: UInt32;
    Modified: TDateTime;
  end;

  TSearchResult = record
    Path: string;
    Score: Integer;
  end;

  TSearchUpdateEvent = procedure(const AResults: TArray<TSearchResult>) of object;

type
  TFilesSnapshot = class
  public
    Files: TArray<TFileItem>;
    constructor Create(const AFiles: TArray<TFileItem>);
  end;

  TResultSnapshot = class
  public
    Results: TArray<TSearchResult>;
    constructor Create(const AResults: TArray<TSearchResult>);
  end;

type
  TDelphiFFF = class
  private
    FFilesSnap: TFilesSnapshot;
    FScanInProgress: Integer;

    function GenerateMask(const S: string): UInt32;
    function FuzzyMatch(const Query, Target: PChar; QLen, TLen: Integer): Integer;
  public
    constructor Create;
    destructor Destroy; override;

    procedure ScanDirectoryAsync(const APath: string);
    function Search(const AQuery: string; AMaxResults: Integer = 100): TArray<TSearchResult>;
  end;

  TFFFUIBridge = class
  private
    FSearchGen: Int64;
    FFFF: TDelphiFFF;
    FCurrentTask: ITask;
    FSnapshot: TResultSnapshot;
    FOnUpdate: TSearchUpdateEvent;
  public
    constructor Create(AFFF: TDelphiFFF; AUpdateEvent: TSearchUpdateEvent);
    destructor Destroy; override;

    procedure AsyncSearch(const AQuery: string);
    function GetResultsSnapshot: TArray<TSearchResult>;
  end;

implementation

{ TFilesSnapshot }

constructor TFilesSnapshot.Create(const AFiles: TArray<TFileItem>);
begin
  Files := AFiles;
end;

{ TResultSnapshot }

constructor TResultSnapshot.Create(const AResults: TArray<TSearchResult>);
begin
  Results := AResults;
end;

{ TDelphiFFF }

constructor TDelphiFFF.Create;
begin
  inherited;
  FScanInProgress := 0;
end;

destructor TDelphiFFF.Destroy;
var
  LOld, LNil: TFilesSnapshot;
begin
  LNil := nil;
  LOld := TInterlocked.Exchange(FFilesSnap, LNil);
  if Assigned(LOld) then
    LOld.Free;
  inherited;
end;

function TDelphiFFF.GenerateMask(const S: string): UInt32;
var
  C: Char;
begin
  Result := 0;
  for C in S do
    if (C >= 'a') and (C <= 'z') then
      Result := Result or (1 shl (Ord(C) - Ord('a')));
end;

procedure TDelphiFFF.ScanDirectoryAsync(const APath: string);
begin
  // Prevenir escaneos concurrentes
  if TInterlocked.CompareExchange(FScanInProgress, 1, 0) <> 0 then
    Exit;

  TTask.Run(procedure
    var
      Temp: TList<TFileItem>;

    procedure Scan(const Dir: string; Depth: Integer = 0);
    var
      SR: TSearchRec;
      Item: TFileItem;
    begin
      if Depth > 15 then Exit; // Limitar profundidad

      try
        if FindFirst(Dir + '\*', faAnyFile, SR) = 0 then
        try
          repeat
            if (SR.Attr and faDirectory) <> 0 then
            begin
              if (SR.Name <> '.') and (SR.Name <> '..') and
                 ((SR.Attr and (faHidden or faSysFile)) = 0) then
                Scan(Dir + '\' + SR.Name, Depth + 1);
            end
            else
            begin
              // Ignorar archivos ocultos/sistema
              if (SR.Attr and (faHidden or faSysFile)) <> 0 then
                Continue;

              Item.Path := Dir + '\' + SR.Name;
              Item.FileNameLow := LowerCase(SR.Name);
              Item.RelativePathLow := LowerCase(ExtractRelativePath(APath, Item.Path));
              Item.CharMask := GenerateMask(Item.FileNameLow);
              Item.Modified := SR.TimeStamp;
              Temp.Add(Item);
            end;
          until FindNext(SR) <> 0;
        finally
          FindClose(SR);
        end;
      except
        // Silenciar errores de acceso (permisos, unidades extraíbles, etc)
      end;
    end;

    var
      NewSnap, OldSnap: TFilesSnapshot;
    begin
      Temp := TList<TFileItem>.Create;
      try
        Scan(ExcludeTrailingPathDelimiter(APath));
        NewSnap := TFilesSnapshot.Create(Temp.ToArray);
        OldSnap := TInterlocked.Exchange(FFilesSnap, NewSnap);
        if Assigned(OldSnap) then
          OldSnap.Free;
      finally
        Temp.Free;
        TInterlocked.Exchange(FScanInProgress, 0);
      end;
    end);
end;

function TDelphiFFF.FuzzyMatch(const Query, Target: PChar; QLen, TLen: Integer): Integer;
var
  Qi, Ti, Score, Run, Gap: Integer;
  WordBoundary: Boolean;
begin
  if QLen > TLen then Exit(0);

  Qi := 0;
  Ti := 0;
  Score := 0;
  Run := 0;
  Gap := 0;

  while (Qi < QLen) and (Ti < TLen) do
  begin
    if Query[Qi] = Target[Ti] then
    begin
      // Bonus por secuencia consecutiva
      Inc(Score, 10 + Run * 5);

      // Bonus por inicio de archivo
      if Ti = 0 then
        Inc(Score, 50);

      // Bonus por inicio de palabra
      if Ti > 0 then
      begin
        WordBoundary := Target[Ti-1] in ['/', '\', '_', '-', ' ', '.'];
        if WordBoundary then
          Inc(Score, 30);
      end;

      // Penalty por gaps entre coincidencias
      if Gap > 0 then
        Dec(Score, Gap * 2);

      Inc(Qi);
      Inc(Run);
      Gap := 0;
    end
    else
    begin
      Run := 0;
      Inc(Gap);
    end;
    Inc(Ti);
  end;

  if Qi = QLen then
    Result := Score
  else
    Result := 0;
end;

function TDelphiFFF.Search(const AQuery: string; AMaxResults: Integer): TArray<TSearchResult>;
var
  Snap: TFilesSnapshot;
  QueryLow: string;
  QMask: UInt32;
  QLen: Integer;
  Results: TList<TSearchResult>;
  LocalBatch: TList<TSearchResult>;
  LastUpdate: Cardinal;
begin
  if AQuery = '' then Exit(nil);

  // Lectura atómica del snapshot
  Snap := TFilesSnapshot(AtomicCmpExchange(Pointer(FFilesSnap), 0, 0));
  if not Assigned(Snap) or (Length(Snap.Files) = 0) then
    Exit(nil);

  QueryLow := LowerCase(AQuery);
  QLen := Length(QueryLow);
  QMask := GenerateMask(QueryLow);

  Results := TList<TSearchResult>.Create;
  LocalBatch := TList<TSearchResult>.Create;
  LastUpdate := TThread.GetTickCount64;
  try
    TParallel.For(0, High(Snap.Files),
      procedure(I: Integer)
      var
        Score: Integer;
        R: TSearchResult;
      begin
        // Filtro rápido por bitmask
        if (Snap.Files[I].CharMask and QMask) <> QMask then Exit;

        // Fuzzy match contra nombre de archivo
        Score := FuzzyMatch(
          PChar(QueryLow),
          PChar(Snap.Files[I].FileNameLow),
          QLen,
          Length(Snap.Files[I].FileNameLow)
        );

        if Score > 0 then
        begin
          R.Path := Snap.Files[I].Path;
          R.Score := Score;
          TMonitor.Enter(Results);
          try
           Results.Add(R);
          finally
            TMonitor.Exit(Results);
          end;
        end;
      end);

    // Ordenar por score descendente
    Results.Sort(
      TComparer<TSearchResult>.Construct(
        function(const L, R: TSearchResult): Integer
        begin
          Result := R.Score - L.Score;
        end));

    if Results.Count > AMaxResults then
      Results.Count := AMaxResults;

    Result := Results.ToArray;
  finally
    Results.Free;
  end;
end;

{ TFFFUIBridge }

constructor TFFFUIBridge.Create(AFFF: TDelphiFFF; AUpdateEvent: TSearchUpdateEvent);
begin
  inherited Create;
  FFFF := AFFF;
  FOnUpdate := AUpdateEvent;
  FSearchGen := 0;
end;

destructor TFFFUIBridge.Destroy;
var
  LOld, LNil: TResultSnapshot;
begin
  if Assigned(FCurrentTask) then
    FCurrentTask.Cancel;

  LNil := nil;
  LOld := TInterlocked.Exchange(FSnapshot, LNil);
  if Assigned(LOld) then
    LOld.Free;

  inherited;
end;

procedure TFFFUIBridge.AsyncSearch(const AQuery: string);
var
  MyGen: Int64;
  LNil: TResultSnapshot;
  LOld: TResultSnapshot;
begin
  if Assigned(FCurrentTask) then
    FCurrentTask.Cancel;

  if AQuery.IsEmpty then
  begin
    LNil := nil;
    LOld := TInterlocked.Exchange(FSnapshot, LNil);
    if Assigned(LOld) then
      LOld.Free;

    if Assigned(FOnUpdate) then
      FOnUpdate(nil);
    Exit;
  end;

  MyGen := TInterlocked.Increment(FSearchGen);

  FCurrentTask := TTask.Run(procedure
    var
      LResults: TArray<TSearchResult>;
      LSnapshot, LOldSnap: TResultSnapshot;
    begin
      if TTask.CurrentTask.Status = TTaskStatus.Canceled then
        Exit;

      LResults := FFFF.Search(AQuery, 100);

      if TTask.CurrentTask.Status = TTaskStatus.Canceled then
        Exit;

      LSnapshot := TResultSnapshot.Create(LResults);

      TThread.Queue(nil, procedure
        begin
          // Publicar solo si es la búsqueda más reciente
          if MyGen = FSearchGen then
          begin
            LOldSnap := TInterlocked.Exchange(FSnapshot, LSnapshot);
            if Assigned(LOldSnap) then
              LOldSnap.Free;

            if Assigned(FOnUpdate) then
              FOnUpdate(LSnapshot.Results);
          end
          else
            LSnapshot.Free; // Descartar resultado obsoleto
        end);
    end);
end;

function TFFFUIBridge.GetResultsSnapshot: TArray<TSearchResult>;
var
  Snap: TResultSnapshot;
begin
  // Lectura atómica
  Snap := TResultSnapshot(AtomicCmpExchange(Pointer(FSnapshot), 0, 0));
  if Assigned(Snap) then
    Result := Copy(Snap.Results)
  else
    SetLength(Result, 0);
end;

end.
