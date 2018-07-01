unit SHL_WindowIPC; // SpyroHackingLib is licensed under WTFPL

interface

uses
  Windows, Messages, SysUtils, ShellAPI, ShlObj, SHL_WideRegistry, SHL_Files,
  SHL_Types;

type
  RWindowIPC = record
    Next: Pointer;
    Window: HWND;
    ID: Integer;
    Length: Integer;
    Data: Cardinal;
  end;

  PWindowIPC = ^RWindowIPC;

  TWindowIPC = class(TObject)
    constructor Create(From: HWND; Name: TextString);
    destructor Destroy(); override;
  public
    class procedure AssociateFileType(const DllName, Product, Extension, Restore,
      Caption, Execute, Icon, Action: WideString; ShowExt: Boolean);
    class procedure AssociateTypeCancel(const DllName, Product, Extension,
      Restore: WideString);
    class function AssociateInEffect(const DllName, Product, Extension, Execute:
      WideString; out Working: Boolean): Boolean;
    class procedure PopupWindow(Handle: HWND);
  private
    procedure Push(Window: HWND; CopyData: PCopyDataStruct);
  public
    function ServerStart(Message: Integer; Param: Integer): Boolean;
    function ClientSend(ID: Integer; Data: DataString): Boolean;
    function Recieve(out Data: DataString): Integer;
  private
    FOwner, FWindow: HWND;
    FClass: TextString;
    FData: PWindowIPC;
    FMessage, FParam: Integer;
  end;

implementation

function TWindowIPC_WindowProc(hwnd: Integer; uMsg: Integer; wParam: Integer;
  lParam: Integer): Integer; stdcall;
var
  IPC: TWindowIPC;
begin
  if hwnd <> 0 then
    if uMsg = WM_COPYDATA then
    begin
      IPC := TWindowIPC(Pointer(GetWindowLong(hwnd, GWL_USERDATA)));
      if IPC <> nil then
      begin
        IPC.Push(wParam, Pointer(lParam));
        Result := 1;
        Exit;
      end;
    end;
  Result := DefWindowProc(hwnd, uMsg, wParam, lParam);
end;

constructor TWindowIPC.Create(From: HWND; Name: TextString);
begin
  inherited Create();
  FOwner := From;
  FClass := Name;
end;

destructor TWindowIPC.Destroy();
var
  Old: Pointer;
begin
  DestroyWindow(FWindow);
  while FData <> nil do
  begin
    Old := FData;
    FData := FData.Next;
    FreeMem(Old);
  end;
  inherited Destroy();
end;

function TWindowIPC.ServerStart(Message: Integer; Param: Integer): Boolean;
const
  HWND_MESSAGE = -3;
var
  Cls: TWndClassExA;
begin
  FMessage := Message;
  FParam := Param;
  ZeroMem(@Cls, SizeOf(Cls));
  Cls.cbSize := SizeOf(Cls);
  Cls.lpfnWndProc := @TWindowIPC_WindowProc;
  Cls.hInstance := HInstance;
  Cls.lpszClassName := PTextChar(FClass);
  RegisterClassExA(Cls);
  FWindow := CreateWindowEx(0, Cls.lpszClassName, nil, WS_OVERLAPPEDWINDOW, 0, 0,
    256, 256, System.Cardinal(HWND_MESSAGE), 0, HInstance, nil);
  SetWindowLong(FWindow, GWL_USERDATA, Integer(Pointer(Self)));
  Result := FWindow <> 0;
end;

function TWindowIPC.ClientSend(ID: Integer; Data: DataString): Boolean;
var
  CopyData: TCopyDataStruct;
  Res: System.Cardinal;
const
  SMTO_NOTIMEOUTIFNOTHUNG = 8;
begin
  Result := False;
  if ID = 0 then
    Exit;
  CopyData.dwData := ID;
  CopyData.cbData := Length(Data);
  CopyData.lpData := Cast(Data);
  Res := 0;
  if SendMessageTimeout(FindWindow(PTextChar(FClass), nil), WM_COPYDATA, FOwner,
    Integer(@CopyData), SMTO_BLOCK or SMTO_NOTIMEOUTIFNOTHUNG, 2000, Res) = 0 then
    Exit;
  Result := Res <> 0;
end;

procedure TWindowIPC.Push(Window: HWND; CopyData: PCopyDataStruct);
var
  Memory: PWindowIPC;
begin
  if (Window = 0) or (CopyData.dwData = 0) or (Integer(CopyData.cbData) < 0) then
    Exit;
  GetMem(Memory, SizeOf(RWindowIPC) + CopyData.cbData - 4);
  Memory.Next := nil;
  Memory.Window := Window;
  Memory.ID := CopyData.dwData;
  Memory.Length := CopyData.cbData;
  if CopyData.cbData <> 0 then
    CopyMem(CopyData.lpData, @Memory.Data, CopyData.cbData);
  if FData = nil then
    FData := Memory
  else
    FData.Next := Memory;
  PostMessage(FOwner, FMessage, FParam, Window);
end;

function TWindowIPC.Recieve(out Data: DataString): Integer;
var
  Old: Pointer;
begin
  Result := 0;
  if FData = nil then
    Exit;
  if FData.Length <= 0 then
    Data := ''
  else
    SetString(Data, CastChar(@FData.Data), FData.Length);
  Result := FData.ID;
  Old := FData;
  FData := FData.Next;
  FreeMem(Old);
end;

class procedure TWindowIPC.AssociateFileType(const DllName, Product, Extension,
  Restore, Caption, Execute, Icon, Action: WideString; ShowExt: Boolean);
var
  Reg: TWideRegistry;
  ProgID: WideString;
  Key, Old: WideString;
begin
//  AssociateTypeCancel(DllName, Product, Extension, Restore);
  ProgID := Product + Extension;
  Reg := TWideRegistry.Create();
  Reg.SetRoot(RegHKCU);
  Reg.OpenKeyWrite('Software\Classes\' + Extension);
  Old := Reg.ReadString('');
  if Old <> ProgID then
    Reg.WriteString(Restore, Old);
  Reg.WriteString('', ProgID);
  Reg.OpenKeyWrite('Software\Classes\' + ProgID);
  Reg.WriteString('', Caption);
  if ShowExt then
    Reg.WriteString('AlwaysShowExt', '')
  else
    Reg.DeleteValue('AlwaysShowExt');
  Reg.WriteInteger('BrowserFlags', 8);
  Reg.WriteInteger('EditFlags', $150001);
  Key := 'Software\Classes\' + ProgID;
  Reg.OpenKeyWrite(Key + '\shell');
  Reg.WriteString('', 'open');
  Reg.OpenKeyWrite(Key + '\shell\open');
  Reg.WriteString('', Action);
  Reg.OpenKeyWrite(Key + '\shell\open\command');
  Reg.WriteString('', Execute);
  Reg.OpenKeyWrite(Key + '\DefaultIcon');
  Reg.WriteString('', Icon);
  Reg.OpenKeyWrite('Software\Classes\Applications\' + Sfiles.GetLastSlash(DllName, True));
  Reg.WriteString('NoOpenWith', '');
  Key := 'Software\Microsoft\Windows\CurrentVersion\Explorer\FileExts\' + Extension;
  if Reg.KeyExists(Key) then
  begin
    Reg.OpenKeyWrite(Key);
    Reg.DeleteValue('Application');
    Reg.DeleteValue('Progid');
  end;
  Reg.Free();
  SHChangeNotify(SHCNE_ASSOCCHANGED, SHCNF_IDLIST, nil, nil);
end;

class procedure TWindowIPC.AssociateTypeCancel(const DllName, Product, Extension,
  Restore: WideString);
var
  Reg: TWideRegistry;
  ProgID: WideString;
  Key, Old: WideString;
begin
  if (Extension = '') or (Extension[1] <> '.') or (Product = '') or (DllName =
    '') or (Restore = '') then
    Exit;
  ProgID := Product + Extension;
  Reg := TWideRegistry.Create();
  Reg.SetRoot(RegHKCU);
  Key := 'Software\Classes\' + ProgID;
  Reg.DeleteKey(Key + '\shell\open\command');
  Reg.DeleteKey(Key + '\shell\open');
  Reg.DeleteKey(Key + '\shell');
  Reg.DeleteKey(Key + '\DefaultIcon');
  Reg.DeleteKey(Key);
  Reg.DeleteKey('Software\Classes\Applications\' + Sfiles.GetLastSlash(DllName, True));
  Key := 'Software\Classes\' + Extension;
  if Reg.KeyExists(Key) then
  begin
    Reg.OpenKeyWrite(Key);
    if Reg.ReadString('') = ProgID then
    begin
      Old := '';
      if Reg.ValueExists(Restore) then
      begin
        Old := Reg.ReadString(Restore);
        Reg.DeleteValue(Restore);
        Reg.WriteString('', Old);
      end;
      if Old = '' then
        Reg.DeleteKey(Key);
    end;
  end;
  Key := 'Software\Microsoft\Windows\CurrentVersion\Explorer\FileExts\' + Extension;
  if Reg.KeyExists(Key) then
  begin
    Reg.OpenKeyWrite(Key);
    Reg.DeleteValue('Application');
    Reg.DeleteValue('Progid');
  end;
  Reg.Free();
  SHChangeNotify(SHCNE_ASSOCCHANGED, SHCNF_IDLIST, nil, nil);
end;

class function TWindowIPC.AssociateInEffect(const DllName, Product, Extension,
  Execute: WideString; out Working: Boolean): Boolean;
var
  Reg: TWideRegistry;
  ProgID: WideString;
begin
  Working := False;
  Result := False;
  if (Extension = '') or (Extension[1] <> '.') or (Product = '') or (DllName = '') then
    Exit;
  ProgID := Product + Extension;
  Reg := TWideRegistry.Create();
  Reg.SetRoot(RegHKCU);
  Reg.OpenKeyRead('Software\Classes\' + Extension);
  if Reg.ReadString('') = ProgID then
  begin
    Result := True;
    Reg.OpenKeyRead('Software\Classes\' + ProgID + '\shell\open\command');
    if Reg.ReadString('') = Execute then
    begin
      Working := True;
      Reg.OpenKeyRead('Software\Microsoft\Windows\CurrentVersion\Explorer\FileExts\'
        + Extension);
      if Reg.ValueExists('Application') or Reg.ValueExists('Progid') then
        Working := False;
    end;
  end;
  Reg.Free();
end;

class procedure TWindowIPC.PopupWindow(Handle: HWND);
begin
//  SetWindowPos(Handle, HWND_TOP, 0, 0, 0, 0, SWP_NOMOVE or SWP_NOSIZE);

//  ShowWindow(Handle, SW_HIDE);
//  ShowWindow(Handle, SW_SHOW);
//GetWindowInfo()
  if IsIconic(Handle) or ((GetWindowLong(Handle, GWL_STYLE) and WS_MINIMIZE) <> 0) then
    ShowWindow(Handle, SW_RESTORE);
//  SetWindowPos(Handle, HWND_TOPMOST, 0, 0, 0, 0, SWP_NOMOVE or SWP_NOSIZE);
//  SetWindowPos(Handle, HWND_NOTOPMOST, 0, 0, 0, 0, SWP_NOMOVE or SWP_NOSIZE);
//SetWindowL
  SetWindowPos(Handle, HWND_TOP, 0, 0, 0, 0, SWP_NOMOVE or SWP_NOSIZE);
  SetForegroundWindow(Handle);
  SetActiveWindow(Handle);
end;

end.

