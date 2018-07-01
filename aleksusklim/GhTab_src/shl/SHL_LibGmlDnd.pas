unit SHL_LibGmlDnd; // SpyroHackingLib is licensed under WTFPL

interface

uses
  Windows, Messages, SysUtils, ShellAPI, SHL_WindowIPC, SHL_Types;

function LibGmlDndFile(): WideString;

procedure LibGmlDndSim(Drag: WideString);

implementation

var
  GuiActive: Boolean = False;
  GmlHandle: THandle = 0;
  OldWinProc: Integer = 0;
  OldWinExst: Integer = 0;
  FilePathAnsi: array[0..MAX_PATH] of TextChar;
  FilePathWide: WideString;
  HaveFile: Boolean = False;

type
  TWindowProc = function(hwnd: HWND; uMsg: UINT; wParam: WPARAM; lParam: LPARAM):
    Integer; stdcall;

const
  GWLP_WNDPROC = -4;
  GWL_EXSTYLE = -20;

function LibGmlDndFile(): WideString;
begin
  Result := WideString(PWideChar(FilePathWide));
  FilePathWide := '';
end;

procedure LibGmlDndSim(Drag: WideString);
var
  Ansi: TextString;
begin
  FilePathWide := Drag;
  Ansi := TextString(FilePathWide);
  FilePathAnsi[0] := #0;
  if Ansi <> '' then
    CopyMem(Cast(Ansi), @FilePathAnsi[0], Length(Ansi) + 1);
  HaveFile := True;
end;

function MyWindowProc(hwnd: HWND; uMsg: UINT; wParam: WPARAM; lParam: LPARAM):
  Integer; stdcall;
begin
  if uMsg = WM_DROPFILES then
  begin
    if DragQueryFileA(wParam, $FFFFFFFF, nil, 0) > 0 then
    begin
      FilePathAnsi[0] := #0;
      if DragQueryFileA(wParam, 0, FilePathAnsi, MAX_PATH) <> 0 then
        HaveFile := True;
    end;
    if DragQueryFileW(wParam, $FFFFFFFF, nil, 0) > 0 then
    begin
      SetLength(FilePathWide, DragQueryFileW(wParam, 0, nil, 0) + 1);
      DragQueryFileW(wParam, 0, PWideChar(FilePathWide), Length(FilePathWide));
    end;
    DragFinish(wParam);
  end;
  Result := TWindowProc(OldWinProc)(hwnd, uMsg, wParam, lParam);
end;

function LibGmlDndTest(): Double; stdcall;
begin
  Result := 0;
  if HaveFile then
    Result := 1;
end;

function LibGmlDndName(): PTextChar; stdcall;
begin
  if HaveFile then
    Result := @FilePathAnsi[0]
  else
    Result := nil;
  HaveFile := False;
end;

function LibGmlDndInit(window_handle: Double): Double; stdcall;
begin
  Result := 0;
  if GuiActive then
    Exit;
  Result := 1;
  GuiActive := True;
  GmlHandle := Round(window_handle);
  OldWinProc := GetWindowLong(GmlHandle, GWLP_WNDPROC);
  OldWinExst := GetWindowLong(GmlHandle, GWL_EXSTYLE);
  SetWindowLong(GmlHandle, GWLP_WNDPROC, Integer(@MyWindowProc));
  SetWindowLong(GmlHandle, GWL_EXSTYLE, OldWinExst or WS_EX_ACCEPTFILES);
end;

function LibGmlDndFree(): Double; stdcall;
begin
  Result := 0;
  if not GuiActive then
    Exit;
  Result := 1;
  GuiActive := False;
  SetWindowLong(GmlHandle, GWLP_WNDPROC, OldWinProc);
  SetWindowLong(GmlHandle, GWL_EXSTYLE, OldWinExst);
  OldWinProc := 0;
  OldWinExst := 0;
  GmlHandle := 0;
end;

exports
  LibGmlDndInit,
  LibGmlDndFree,
  LibGmlDndTest,
  LibGmlDndName;

end.

