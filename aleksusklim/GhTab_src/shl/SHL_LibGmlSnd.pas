unit SHL_LibGmlSnd; // SpyroHackingLib is licensed under WTFPL

interface

implementation

uses
  Windows;

function OpenThread(dwDesiredAccess: Integer; bInheritHandle: Boolean;
  dwThreadId: Integer): Integer; stdcall; external 'kernel32.dll';

function CreateToolhelp32Snapshot(dwFlags, th32ProcessID: Integer): Integer;
  stdcall; external 'kernel32.dll';

function Thread32First(hSnapshot: Integer; lpte: Pointer): Boolean; stdcall;
  external 'kernel32.dll';

function Thread32Next(hSnapshot: Integer; lpte: Pointer): Boolean; stdcall;
  external 'kernel32.dll';

const
  THREAD_SUSPEND_RESUME = $0002;

type
  tagTHREADENTRY32 = record
    dwSize: integer;
    cntUsage: integer;
    th32ThreadID: integer;
    th32OwnerProcessID: integer;
    tpBasePri: integer;
    tpDeltaPri: integer;
    dwFlags: integer;
  end;

const
  MaxThreadCount = 16;

var
  Threads: array[0..MaxThreadCount - 1] of Integer;
  Frozen: Boolean = False;
  Working: Boolean = False;
  Count: Integer = 0;

function LibGmlSndInit(): Double; stdcall;
var
  Process, Handle, Index: Integer;
  Struct: tagTHREADENTRY32;
begin
  Result := 0;
  if Working then
    Exit;
  Handle := CreateToolhelp32Snapshot(4, 0);
  if (Handle = 0) or (Handle = -1) then
    Exit;
  Process := GetCurrentProcessId();
  Struct.dwSize := SizeOf(Struct);
  if not Thread32First(Handle, @Struct) then
  begin
    CloseHandle(Handle);
    Exit;
  end;
  Index := 0;
  repeat
    if (Struct.th32OwnerProcessID = Process) and (Struct.tpBasePri = 15) then
    begin
      Threads[Index] := Struct.th32ThreadID;
      Inc(Index);
    end;
  until (not Thread32Next(Handle, @Struct)) or (Index = MaxThreadCount);
  CloseHandle(Handle);
  Count := Index;
  if Count = 0 then
    Exit;
  for Index := 0 to Count - 1 do
    Threads[Index] := OpenThread(THREAD_SUSPEND_RESUME, False, Threads[Index]);
  Working := True;
  Result := 1;
end;

function LibGmlSndSuspend(): Double; stdcall;
var
  Index: Integer;
begin
  if not Frozen then
  begin
    if Working then
      for Index := 0 to Count - 1 do
        SuspendThread(Threads[Index]);
    Frozen := True;
    Result := 1;
  end
  else
    Result := 0;
end;

function LibGmlSndResume(): Double; stdcall;
var
  Index: Integer;
begin
  if Frozen then
  begin
    if Working then
      for Index := 0 to Count - 1 do
        ResumeThread(Threads[Index]);
    Frozen := False;
    Result := 1;
  end
  else
    Result := 0;
end;

function LibGmlSndFree(): Double; stdcall;
var
  Index: Integer;
begin
  LibGmlSndResume();
  if Working then
    for Index := 0 to Count - 1 do
      CloseHandle(Threads[Index]);
  Working := False;
  Result := 0;
end;

exports
  LibGmlSndInit,
  LibGmlSndSuspend,
  LibGmlSndResume,
  LibGmlSndFree;

end.

