unit SHL_MemoryManager;

interface

uses
  SHL_Types;

type
  TMemorySimple = class(TObject)
  private
    FPageSize: Integer;
    FLastPage: Pointer;
    FOffset, FLimit: Integer;
  public
    constructor Create(PageSize: Integer = -1);
    destructor Destroy(); override;
  public
    function Alloc(Size: Integer; Align: Integer = 1): Pointer;
    procedure Clear();
    function CopyStr(const Str: TextString): PTextChar;
    function CopyWide(const Str: WideString): PWideChar;
  public
    property PageSize: Integer read FPageSize write FPageSize;
  end;

type
  TBackStack = class(TObject)
  private
    FMemory: TMemorySimple;
    FElemSize: Integer;
  public
    constructor Create(ElemSize: Integer; ElemsOnPage: Integer = -1);
    destructor Destroy(); override;
  public
    function NewElem(Previous: Pointer): Pointer;
    function Next(Elem: Pointer): Pointer;
  end;

type
  TFastStack = class(TObject)
  private
    FElemSize, FPageSize, FPrtOffset, FCount: Integer;
    FMemory, FCache: Pointer;
    FLast: PByte;
  public
    constructor Create(ElemSize: Integer; ElemsOnPage: Integer = -1);
    destructor Destroy(); override;
  public
    procedure Clear();
    function Empty(): Boolean;
    function Peek(): Pointer;
    function Push(): Pointer;
    function Pop(): Pointer;
    procedure Remove(Count: Integer);
  private
    function Next(): PPointer;
    function Last(): Pointer;
  public
    property Count: Integer read FCount;
  end;

implementation

// TMemorySimple

constructor TMemorySimple.Create(PageSize: Integer = -1);
begin
  inherited Create();
  if PageSize < 0 then
    FPageSize := 16348
  else
    FPageSize := PageSize;
end;

destructor TMemorySimple.Destroy();
begin
  Clear();
  inherited Destroy();
end;

function TMemorySimple.Alloc(Size: Integer; Align: Integer = 1): Pointer;
var
  Page: Pointer;
  Have: Integer;
begin
  Result := nil;
  try
    Have := Align - 1;
    Assure((Size >= 0) and (Align > 0) and ((Align and Have) = 0));
    Have := (Integer(FLastPage) + FOffset) and Have;
    if Have <> 0 then
      Inc(FOffset, Align - Have);
    if (FLastPage = nil) or (FOffset + Size > FLimit) then
    begin
      if Size > FPageSize - SizeOf(Pointer) then
        FLimit := Size + SizeOf(Pointer)
      else
        FLimit := FPageSize;
      GetMem(Page, FLimit);
      FOffset := SizeOf(Pointer);
      CastPtr(Page)^ := FLastPage;
      FLastPage := Page;
    end;
    Result := Cast(FLastPage, FOffset);
    Inc(FOffset, Size);
  except
  end;
end;

procedure TMemorySimple.Clear();
var
  Page: Pointer;
begin
  while FLastPage <> nil do
  begin
    Page := FLastPage;
    FLastPage := CastPtr(FLastPage)^;
    FreeMem(Page);
  end;
  FOffset := 0;
  FLimit := 0;
end;

function TMemorySimple.CopyStr(const Str: TextString): PTextChar;
var
  Len: Integer;
begin
  Len := Length(Str) + 1;
  Result := Alloc(Len);
  if Result = nil then
    Exit;
  CopyMem(Cast(Str), Result, Len);
end;

function TMemorySimple.CopyWide(const Str: WideString): PWideChar;
var
  Len: Integer;
begin
  Len := (Length(Str) + 1) * 2;
  Result := Alloc(Len);
  if Result = nil then
    Exit;
  CopyMem(Cast(Str), Result, Len);
end;

// TBackStack

constructor TBackStack.Create(ElemSize: Integer; ElemsOnPage: Integer = -1);
var
  MemSize: Integer;
begin
  if ElemSize < 1 then
    ElemSize := 1;
  FElemSize := AlignValue(ElemSize + SizeOf(Pointer), 8);
  if ElemsOnPage < 1 then
    MemSize := -1
  else
    MemSize := FElemSize * ElemsOnPage;
  FMemory := TMemorySimple.Create(MemSize);
end;

destructor TBackStack.Destroy();
begin
  FMemory.Free();
end;

function TBackStack.NewElem(Previous: Pointer): Pointer;
begin
  Result := FMemory.Alloc(FElemSize);
//  GetMem(Result, FElemSize);
  PPointer(Result)^ := Previous;
  Inc(PPointer(Result));
end;

function TBackStack.Next(Elem: Pointer): Pointer;
begin
  if Elem = nil then
    Result := nil
  else
  begin
    Dec(PPointer(Elem));
    Result := PPointer(Elem)^;
  end;
end;

// TFastStack

constructor TFastStack.Create(ElemSize: Integer; ElemsOnPage: Integer = -1);
begin
  inherited Create();
  if ElemSize < 1 then
    ElemSize := 1;
  if ElemsOnPage < 1 then
  begin
    ElemsOnPage := 16 * 1024 div ElemSize;
    if ElemsOnPage < 8 then
      ElemsOnPage := 8;
  end;
  FElemSize := ElemSize;
  FPageSize := FElemSize * ElemsOnPage;
  FPrtOffset := AlignValue(FPageSize, SizeOf(Pointer));
  Clear();
end;

destructor TFastStack.Destroy();
begin
  Clear();
  inherited Destroy();
end;

function TFastStack.Next(): PPointer;
begin
  Result := FMemory;
  Inc(PByte(Result), FPrtOffset);
end;

function TFastStack.Last(): Pointer;
begin
  Result := FMemory;
  Inc(PByte(Result), FPageSize);
end;

procedure TFastStack.Clear();
begin
  while FMemory <> nil do
  begin
    FLast := Next()^;
    FreeMem(FMemory);
    FMemory := FLast;
  end;
  FCache := nil;
  FLast := nil;
end;

function TFastStack.Empty(): Boolean;
begin
  Result := FCount = 0;
end;

function TFastStack.Peek(): Pointer;
begin
  if FCount = 0 then
    Result := nil
  else
    Result := FLast;
end;

function TFastStack.Push(): Pointer;
begin
  if FCount = 0 then
  begin
    if FMemory = nil then
    begin
      if FCache <> nil then
      begin
        FMemory := FCache;
        FCache := nil;
      end
      else
      try
        GetMem(FMemory, FPrtOffset + SizeOf(Pointer));
      except
        Result := nil;
        Exit;
      end;
    end;
    Next()^ := nil;
    FLast := FMemory;
    Result := FLast;
    FCount := 1;
    Exit;
  end;
  Result := FLast;
  Inc(FLast, FElemSize);
  if Pointer(FLast) = Last() then
  begin
    FLast := FMemory;
    if FCache <> nil then
    begin
      FMemory := FCache;
      FCache := nil;
    end
    else
    try
      GetMem(FMemory, FPrtOffset + SizeOf(Pointer));
    except
      FMemory := FLast;
      FLast := Result;
      Result := nil;
      Exit;
    end;
    Next()^ := FLast;
    FLast := FMemory;
  end;
  Result := FLast;
  Inc(FCount);
end;

function TFastStack.Pop(): Pointer;
begin
  if FCount = 0 then
  begin
    Result := nil;
    Exit;
  end;
  Dec(FCount);
  Result := FLast;
  if FLast = FMemory then
  begin
    if FCache <> nil then
      FreeMem(FCache);
    FCache := FMemory;
    FMemory := Next()^;
    if FMemory = nil then
    begin
      FLast := nil;
      Exit;
    end
    else
      FLast := Last();
  end;
  Dec(FLast, FElemSize);
end;

procedure TFastStack.Remove(Count: Integer);
var
  Have: Integer;
begin
  if (FCount = 0) or (Count < 1) then
    Exit;
  if Count > FCount then
  begin
    FCount := 0;
    if FCache <> nil then
      FreeMem(FCache);
    FCache := FMemory;
    FMemory := Next()^;
    while FMemory <> nil do
    begin
      FLast := Next()^;
      FreeMem(FMemory);
      FMemory := FLast;
    end;
  end;
  while True do
  begin
    Have := (Diff(FLast, FMemory) div FElemSize) + 1;
    if Count < Have then
      Break;
    Dec(Count, Have);
    Dec(FCount, Have);
    if FCache <> nil then
      FreeMem(FCache);
    FCache := FMemory;
    FMemory := Next()^;
    FLast := Last();
  end;
  Dec(FLast, FElemSize * Count);
  Dec(FCount, Count);
end;

end.

