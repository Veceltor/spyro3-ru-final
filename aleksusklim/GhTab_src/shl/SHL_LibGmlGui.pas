unit SHL_LibGmlGui; // SpyroHackingLib is licensed under WTFPL

interface

uses
  Windows, Forms, Classes, SysUtils, SHL_Types;

procedure LibGmlGuiLoad(MainFormClass: TComponentClass; Horizontal: Boolean);

function LibGmlGuiSize(): Double; stdcall;

var
  GmlHandle: THandle = 0;

implementation

var
  GuiActive: Boolean = False;
  FormClass: TComponentClass;
  MainForm: TForm = nil;
  ConstantHeight: Boolean = False;

procedure LibGmlGuiLoad(MainFormClass: TComponentClass; Horizontal: Boolean);
begin
  FormClass := MainFormClass;
  ConstantHeight := Horizontal;
end;

function LibGmlGuiSize(): Double; stdcall;
var
  Client: TRect;
begin
  Result := 0;
  if not GuiActive then
    Exit;
  GetClientRect(GmlHandle, Client);
  if ConstantHeight then
  begin
    Result := Client.Bottom - MainForm.Height;
    Client.Bottom := MainForm.Height;
  end
  else
  begin
    Result := Client.Right - MainForm.Width;
    Client.Right := MainForm.Width;
  end;
  MainForm.SetBounds(0, 0, Client.Right, Client.Bottom);
end;

function LibGmlGuiInit(window_handle: Double): Double; stdcall;
var
  Client: TRect;
begin
  Result := 0;
  if GuiActive then
    Exit;
  GuiActive := True;
  Application.Initialize;
  Application.ShowMainForm := False;
  MainForm := TForm(FormClass.Create(nil));
  GmlHandle := Round(window_handle);
  Inits(Client);
  LibGmlGuiSize();
  SetParent(MainForm.Handle, GmlHandle);
  MainForm.Show();
  ClientToScreen(GmlHandle, Client.TopLeft);
  if ConstantHeight then
    Result := -MainForm.Height
  else
    Result := MainForm.Width;
end;

function LibGmlGuiFree(): Double; stdcall;
begin
  Result := 0;
  if not GuiActive then
    Exit;
  GuiActive := False;
  MainForm.Close();
  MainForm.Release();
  MainForm := nil;
end;

exports
  LibGmlGuiInit,
  LibGmlGuiSize,
  LibGmlGuiFree;

end.

