unit SHL_WideRegistry; // SpyroHackingLib is licensed under WTFPL

interface

uses
  Windows, SysUtils, SHL_Types;

type
  NRegRoot = (RegNone, RegHKLM, RegHKCU, RegHKCR);

type
  TWideRegistry = class(TObject)
  private
    FRootKey, FCurrentKey: HKEY;
  private
    procedure CloseKey();
    function GetData(const Name: WideString; Buffer: Pointer; BufSize: Integer;
      out RegData: Integer): Integer;
    function PutData(const Name: WideString; Buffer: Pointer; BufSize: Integer;
      RegData: Integer): Boolean;
  public
    constructor Create();
    destructor Destroy; override;
    procedure SetRoot(Root: NRegRoot);
    function DeleteKey(const Key: WideString): Boolean;
    function DeleteValue(const Name: WideString): Boolean;
    function GetDataInfo(const ValueName: WideString; out RegSize, RegData:
      Integer): Boolean;
    function KeyExists(const Key: WideString): Boolean;
    function OpenKeyWrite(const Key: WideString): Boolean;
    function OpenKeyRead(const Key: WideString): Boolean;
    function ReadBinary(const Name: WideString): DataString;
    function ReadInteger(const Name: WideString; const Def: Integer = 0): Integer;
    function ReadString(const Name: WideString; const Def: WideString = ''): WideString;
    function ValueExists(const Name: WideString): Boolean;
    function WriteBinary(const Name: WideString; Buffer: Pointer; Size: Integer;
      RegType: Integer = REG_BINARY): Boolean; overload;
    function WriteBinary(const Name: WideString; Data: DataString): Boolean; overload;
    function WriteInteger(const Name: WideString; Value: Integer): Boolean;
    function WriteString(const Name, Value: WideString): Boolean;
  public
    class function OneString(HKLM: Boolean; const Key, Name: WideString; Value:
      WideString = #0): WideString;
    class function OneDelete(HKLM: Boolean; const Key: WideString; const Name:
      WideString = #0): WideString;
  end;

implementation

constructor TWideRegistry.Create();
begin
  inherited Create();
end;

destructor TWideRegistry.Destroy;
begin
  CloseKey();
  inherited Destroy();
end;

procedure TWideRegistry.SetRoot(Root: NRegRoot);
begin
  CloseKey();
  case Root of
    RegHKLM:
      FRootKey := HKEY_LOCAL_MACHINE;
    RegHKCU:
      FRootKey := HKEY_CURRENT_USER;
    RegHKCR:
      FRootKey := HKEY_CLASSES_ROOT;
  else
    FRootKey := 0;
  end;
end;

procedure TWideRegistry.CloseKey();
begin
  if FCurrentKey <> 0 then
  begin
    RegCloseKey(FCurrentKey);
    FCurrentKey := 0;
  end;
end;

function TWideRegistry.OpenKeyWrite(const Key: WideString): Boolean;
begin
  CloseKey();
  if (Key = '') or (FRootKey = 0) then
    Result := False
  else
    Result := RegCreateKeyExW(FRootKey, PWideChar(Key), 0, nil,
      REG_OPTION_NON_VOLATILE, KEY_ALL_ACCESS, nil, FCurrentKey, nil) = 0;
end;

function TWideRegistry.OpenKeyRead(const Key: WideString): Boolean;

  function Open(Aceess: Integer): Boolean;
  begin
    Result := RegOpenKeyExW(FRootKey, PWideChar(Key), 0, Aceess, FCurrentKey) = 0;
  end;

begin
  CloseKey();
  if (Key = '') or (FRootKey = 0) then
  begin
    Result := False;
    Exit;
  end;
  Result := Open(KEY_READ);
  if Result then
    Exit;
  Result := Open(STANDARD_RIGHTS_READ or KEY_QUERY_VALUE or KEY_ENUMERATE_SUB_KEYS);
  if Result then
    Exit;
  Result := Open(KEY_QUERY_VALUE);
  if Result then
    Exit;
end;

function TWideRegistry.DeleteKey(const Key: WideString): Boolean;
begin
  CloseKey();
  if (Key = '') or (FRootKey = 0) then
    Result := False
  else
    Result := RegDeleteKeyW(FRootKey, PWideChar(Key)) = 0;
end;

function TWideRegistry.DeleteValue(const Name: WideString): Boolean;
begin
  if (FCurrentKey = 0) or (FRootKey = 0) then
    Result := False
  else
    Result := RegDeleteValueW(FCurrentKey, PWideChar(Name)) = 0;
end;

function TWideRegistry.GetDataInfo(const ValueName: WideString; out RegSize,
  RegData: Integer): Boolean;
begin
  RegSize := -1;
  RegData := 0;
  if (FCurrentKey = 0) or (FRootKey = 0) then
  begin
    Result := False;
    Exit;
  end;
  Result := RegQueryValueExW(FCurrentKey, PWideChar(ValueName), nil, @RegData,
    nil, @RegSize) = 0;
end;

function TWideRegistry.WriteString(const Name, Value: WideString): Boolean;
begin
  if (FCurrentKey = 0) or (FRootKey = 0) then
    Result := False
  else
    Result := PutData(Name, PWideChar(Value), (Length(Value) + 1) * 2, REG_SZ);
end;

function TWideRegistry.ReadString(const Name: WideString; const Def: WideString
  = ''): WideString;
var
  Len, RegData: Integer;
begin
  if (FCurrentKey = 0) or (FRootKey = 0) then
  begin
    Result := Def;
    Exit;
  end;
  GetDataInfo(Name, Len, RegData);
  if Len > 0 then
  begin
    SetString(Result, nil, (Len + 1) div 2);
    GetData(Name, PWideChar(Result), Len, RegData);
    Result := PWideChar(Result);
  end
  else if Len < 0 then
    Result := Def
  else
    Result := '';
end;

function TWideRegistry.WriteInteger(const Name: WideString; Value: Integer): Boolean;
begin
  if (FCurrentKey = 0) or (FRootKey = 0) then
    Result := False
  else
    Result := PutData(Name, @Value, SizeOf(Integer), REG_DWORD);
end;

function TWideRegistry.ReadInteger(const Name: WideString; const Def: Integer =
  0): Integer;
var
  RegData: Integer;
begin
  if (FCurrentKey = 0) or (FRootKey = 0) then
  begin
    Result := Def;
    Exit;
  end;
  if GetData(Name, @Result, 4, RegData) <> 4 then
    Result := Def;
end;

function TWideRegistry.WriteBinary(const Name: WideString; Buffer: Pointer; Size:
  Integer; RegType: Integer = REG_BINARY): Boolean;
begin
  if (FCurrentKey = 0) or (FRootKey = 0) then
    Result := False
  else
    Result := PutData(Name, Buffer, Size, RegType);
end;

function TWideRegistry.WriteBinary(const Name: WideString; Data: DataString): Boolean;
begin
  Result := WriteBinary(Name, Cast(Data), Length(Data));
end;

function TWideRegistry.ReadBinary(const Name: WideString): DataString;
var
  RegSize, RegData: Integer;
begin
  if (FCurrentKey = 0) or (FRootKey = 0) then
  begin
    Result := '';
    Exit;
  end;
  if GetDataInfo(Name, RegSize, RegData) then
  begin
    SetLength(Result, RegSize);
    GetData(Name, Cast(Result), RegSize, RegData);
  end
  else
    Result := '';
end;

function TWideRegistry.PutData(const Name: WideString; Buffer: Pointer; BufSize:
  Integer; RegData: Integer): Boolean;
begin
  Result := RegSetValueExW(FCurrentKey, PWideChar(Name), 0, RegData, Buffer, BufSize) = 0;
end;

function TWideRegistry.GetData(const Name: WideString; Buffer: Pointer; BufSize:
  Integer; out RegData: Integer): Integer;
begin
  Result := -1;
  RegData := REG_NONE;
  if RegQueryValueExW(FCurrentKey, PWideChar(Name), nil, @RegData, PByte(Buffer),
    @BufSize) <> 0 then
    Exit;
  Result := BufSize;
end;

function TWideRegistry.ValueExists(const Name: WideString): Boolean;
var
  RegSize, RegData: Integer;
begin
  Result := GetDataInfo(Name, RegSize, RegData);
end;

function TWideRegistry.KeyExists(const Key: WideString): Boolean;
var
  TempKey: HKEY;
begin
  if FRootKey = 0 then
  begin
    Result := False;
    Exit;
  end;
  TempKey := FCurrentKey;
  FCurrentKey := 0;
  Result := OpenKeyRead(Key);
  CloseKey();
  FCurrentKey := TempKey;
end;

class function TWideRegistry.OneString(HKLM: Boolean; const Key, Name:
  WideString; Value: WideString = #0): WideString;
var
  Reg: TWideRegistry;
begin
  Reg := TWideRegistry.Create();
  if HKLM then
    Reg.SetRoot(RegHKLM)
  else
    Reg.SetRoot(RegHKCU);
  Reg.OpenKeyRead(Key);
  Result := Reg.ReadString(Name);
  if Value <> #0 then
  begin
    Reg.OpenKeyWrite(Key);
    Reg.WriteString(Name, Value);
  end;
  Reg.Free();
end;

class function TWideRegistry.OneDelete(HKLM: Boolean; const Key: WideString;
  const Name: WideString = #0): WideString;
var
  Reg: TWideRegistry;
begin
  Result := '';
  Reg := TWideRegistry.Create();
  if HKLM then
    Reg.SetRoot(RegHKLM)
  else
    Reg.SetRoot(RegHKCU);
  if Name <> #0 then
  begin
    Reg.OpenKeyRead(Key);
    Result := Reg.ReadString(Name);
    Reg.DeleteValue(Name);
  end
  else
    Reg.DeleteKey(Key);
  Reg.Free();
end;

end.

