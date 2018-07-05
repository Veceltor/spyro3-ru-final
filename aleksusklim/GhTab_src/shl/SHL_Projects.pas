unit SHL_Projects; // SpyroHackingLib is licensed under WTFPL

interface

uses
  Windows, SHL_Files, SHL_Types;

function Project(Process: MProcess; const ShowHelp: TextString = ''): Boolean; overload;

function Project(Process: MProcessArgs; const ShowHelp: TextString = ''):
  Boolean; overload;

procedure Proj_Null(const Name: WideString);

procedure Proj_JapTab(const Name: WideString);

procedure Proj_GhTab(const Name: WideString);

procedure Proj_JapFont(const Name: WideString);

procedure Proj_SavestateDump(const Name: WideString);

procedure Proj_RepackS1Models(const Name: WideString);

procedure Proj_Spyro1Gui(const Name: WideString);

procedure Proj_ObjTextureToColor(const Name: WideString);

procedure Proj_SpyroModelGet(const Name: WideString);

function Proj_SaveWad(const Args: ArrayOfWide): Boolean;

procedure Proj_SaveWadAuto(const Name: WideString);

implementation

uses
  SysUtils, Classes, Graphics, SHL_VramManager, SHL_Bitmaps, SHL_TextureManager,
  SHL_GoldenFont, SHL_PlayStream, SHL_SavestateReader, SHL_Gzip,
  SHL_ProcessStream, SHL_LameStream, SHL_WaveStream, SHL_IsoReader, SHL_Progress,
  SHL_XaMusic, SHL_EccEdc, SHL_GmlModel, SHL_ObjModel, SHL_BufferedStream,
  SHL_Models3D, SHL_WadManager, SHL_TextUtils, SHL_PosWriter, SHL_MemoryManager,
  SHL_Knapsack, SHL_LevelData, SHL_ModelS1;

function Project(Process: MProcess; const ShowHelp: TextString = ''): Boolean;
begin
  Result := SFiles.ProcessArguments(Process, ShowHelp);
end;

function Project(Process: MProcessArgs; const ShowHelp: TextString = ''): Boolean;
begin
  Result := SFiles.ProcessArgumentsArray(Process, ShowHelp);
end;

procedure Proj_Null(const Name: WideString);
begin
  Cast(Name);
end;

//

type
  PJapTab = ^RJapTab;

  RJapTab = record
    V1, V2, V3, Text, Data, V4: Integer;
  end;

procedure Proj_JapTab(const Name: WideString);
var
  Level: TLevelData;
  Index, Active, Total, Cnt, Offset, Size, Len, Need: Integer;
  Data: DataString;
  Vars, From: Pointer;
  Objs: PLevelObjectsArr;
  Knap: TKnapsack;
  Line, Load: DataString;
  KOffset, KName, KSize: Integer;
  KAddr, Save: Pointer;
  KFit: Boolean;
  Obj: PLevelObject;
  Jap: PJapTab;
  Wad: TWadManager;
  Use: Boolean;
  Replace: TStringList;
  Stream: THandleStream;
const
  Mb = 8 * 1024 * 1024;
begin
  Writeln(Name);
  Level := nil;
  Knap := nil;
  Wad := nil;
  Replace := nil;
  Stream := nil;
  try
    Wad := TWadManager.Create();
    Knap := TKnapsack.Create();
    Level := TLevelData.Create();
    Replace := TStringList.Create();
    Stream := SFiles.OpenRead(Name + '.txt');
    if Stream <> nil then
    begin
      Replace.LoadFromStream(Stream);
      FreeAndNil(Stream);
    end;
    Use := Replace.Count > 0;
    Data := SFiles.ReadEntireFile(Name, Mb);
    Assure(Data <> '');
    SFiles.DeleteFile(Name + '.new');
    Wad.UseLevelSub(Data);
    From := Wad.LevelGetSublevelText(1, Len);
    Level.OpenData(From, GameSpyro1);
    Vars := Level.GetVariables(Offset, Size);
    Objs := Level.GetObjects(Active, Total);
    Writeln('Objects: active - ', Active, ', empty - ', Total - Active);
    Cnt := 0;
    for Index := 0 to Active - 1 do
    begin
      Obj := @Objs[Index];
      if Obj.Entity <> 71 then
        Continue;
      Jap := Cast(Vars, Obj.Variables - Offset);
      if (Jap.V1 <> 0) or (Jap.V2 <> 0) or (Jap.V3 <> 0) or (Jap.V4 <> 0) or (Jap.Data
        <> Obj.Variables + 20) then
        Writeln('STRANGE DATA!');
      Line := DataString(CastChar(Vars, Jap.Text - Offset));
      if Use then
      begin
        if Cnt >= Replace.Count then
        begin
          Writeln('Need more strings?');
          Abort;
        end;
        Load := STextUtils.HexToStr(Replace[Cnt]);
        Knap.AddItem(nil, Index, SizeOf(RJapTab), 4);
        Knap.AddSpace(Obj.Variables, SizeOf(RJapTab));
        Knap.AddSpace(Jap.Text, AlignValue(Length(Line) + 1, 4));
        ZeroMem(Cast(Vars, Jap.Text - Offset), Length(Line));
        ZeroMem(Cast(Vars, Obj.Variables - Offset), SizeOf(RJapTab));
        Knap.AddItem(nil, -1, Length(Load) + 1, 1);
      end
      else
      begin
        Replace.Add(STextUtils.StrToHex(Line));
      end;
      Inc(Cnt);
    end;
    Writeln('Tables: ', Cnt);
    if Use then
    begin
      Need := Knap.Compute();
      if Need > 0 then
      begin
        Need := AlignDiv(Need, 88);
        if Need > Total - Active then
        begin
          Writeln('Text too long! Need empty objects: ', Need);
          Abort;
        end;
        Need := Level.TakeSomeObjects(Need);
        Vars := Level.GetVariables(Offset, Size);
        Objs := Level.GetObjects(Active, Total);
        Writeln('Text takes objects: ', Need div 88);
      end
      else
        Writeln('Text OK');

      Cnt := 0;
      Jap := nil;
      for Index := 0 to Knap.ItemCount - 1 do
      begin
        Knap.GetItem(Index, KAddr, KOffset, KName, KSize, KFit);
        if not KFit then
          Inc(KOffset, Offset);
        if KName <> -1 then
        begin
          Level.ListChangePointer(Objs[KName].Variables + 12, KOffset + 12);
          Level.ListChangePointer(Objs[KName].Variables + 16, KOffset + 16);
          Objs[KName].Variables := KOffset;
          Jap := Cast(Vars, KOffset - Offset);
          ZeroMem(Jap, KSize);
          Jap.Data := KOffset + 20;
        end
        else
        begin
          Jap.Text := KOffset;
          Save := Cast(Vars, KOffset - Offset);
          Load := STextUtils.HexToStr(Replace[Cnt]);
          Inc(Cnt);
          CopyMem(Cast(Load), Save, KSize);
        end;
      end;
      Level.SaveData(From);
      SFiles.WriteEntireFile(Name + '.new', Data);
    end
    else
    begin
      Stream := SFiles.OpenNew(Name + '.txt');
      Replace.SaveToStream(Stream);
      FreeAndNil(Stream);
    end;
    if Use then
      Writeln('Import done!')
    else
      Writeln('Export done.')
  except
    Writeln('ERROR!');
  end;
  if Replace <> nil then
  begin
    Line := '';
    for Index := 0 to Replace.Count - 1 do
      Line := Line + Replace[Index] + '00';
    SFiles.WriteEntireFile(Name + '.bin', STextUtils.HexToStr(Line));
  end;
  Level.Free();
  Knap.Free();
  Wad.Free();
  Replace.Free();
  Stream.Free();
end;

//

procedure Proj_GhTab(const Name: WideString);

  function WrongString(From: Pointer; Line: Boolean): Boolean;
  var
    Tgt: PByte;
    Len: Integer;
  begin
    Result := True;
    Len := 0;
    Tgt := From;
    if Line then
    begin
      if Tgt^ = 0 then
        Exit;
      if Tgt^ > 48 then
        Exit;
      Inc(Tgt, Tgt^);
    end;
    while Tgt^ <> 0 do
    begin
      if Tgt^ < 32 then
        Exit;
      if Tgt^ > 126 then
        Exit;
      Inc(Len);
      Inc(Tgt);
    end;
    if Len < 2 then
      Exit;
    Result := False;
  end;

var
  Index, Can, Order, Active, Total, Cnt, Offset, Size, Take, Len, Need, Next,
    Tex: Integer;
  Data: DataString;
  Vars, From: Pointer;
  Objs: PLevelObjectsArr;
  Knap: TKnapsack;
  Load: DataString;
  Line: TextString;
  KOffset, KName, KSize: Integer;
  KAddr, Save: Pointer;
  KFit: Boolean;
  Obj: PLevelObject;
  Wad: TWadManager;
  Use: Boolean;
  Replace, Rus: TStringList;
  Stream: THandleStream;
  Character: PLevelCharacter;
  Skip: Byte;
  Lev, Tgt: Integer;
  Levels: array[1..5] of TLevelData;
  List, Dups, Have: TList;
  Who, How, It: Integer;
  Where: Pointer;
  Me: PByte;
  Imp, Fit: Boolean;
  RepFile, Ext: WideString;
  Arr: ArrayOfData;
  RepList: array of record
    Search, Replace: TextString;
  end;
  RepSize, Sym: Integer;
  WorkOld, WorkNew: TextString;
  Failed: Boolean;
  Ch: TextString;
const
  Mb = 8 * 1024 * 1024;
  Rounds: array[0..16] of TextString = (#$E2#$93#$AA, #$E2#$91#$A0, #$E2#$91#$A1,
    #$E2#$91#$A2, #$E2#$91#$A3, #$E2#$91#$A4, #$E2#$91#$A5, #$E2#$91#$A6,
    #$E2#$91#$A7, #$E2#$91#$A8, #$E2#$92#$B6, #$E2#$92#$B7, #$E2#$92#$B8,
    #$E2#$92#$B9, #$E2#$92#$BA, #$E2#$92#$BB, #$E2#$80#$89);
  Hexs: array[0..16] of TextString = ('0', '1', '2', '3', '4', '5', '6', '7',
    '8', '9', 'A', 'B', 'C', 'D', 'E', 'F', '');
begin
  Writeln(SFiles.GetLastSlash(Name, True));
  ZeroMem(@Levels[1], SizeOf(Levels));
  Knap := nil;
  Wad := nil;
  Replace := nil;
  Stream := nil;
  List := nil;
  Dups := nil;
  Vars := nil;
  Objs := nil;
  Have := nil;
  Rus := nil;
  SetLength(RepList, 0);
  SetLength(Arr, 0);
  try
    Have := TList.Create();
    Dups := TList.Create();
    List := TList.Create();
    Rus := TStringList.Create();
    Wad := TWadManager.Create();
    Knap := TKnapsack.Create();
    Replace := TStringList.Create();
    RepFile := SFiles.RemoveExtension(SFiles.GetExecutable()) + WideString('.txt');
    RepSize := 0;
    Stream := SFiles.OpenRead(RepFile);
    if Stream <> nil then
    begin
      Replace.LoadFromStream(Stream);
      SFiles.CloseStream(Stream);
      WorkOld := STextUtils.Utf8BomDel(Replace.Text);
      for Index := 0 to 16 do
        WorkOld := StringReplace(WorkOld, Rounds[Index], '', [rfReplaceAll]);
      Replace.Text := WorkOld;
      SetLength(RepList, Replace.Count);
      for Index := 0 to Replace.Count - 1 do
      begin
        Arr := STextUtils.SplitChar(Replace[Index], ['=']);
        if (Length(Arr) > 1) and (Arr[0] <> '') then
        begin
          RepList[RepSize].Search := Arr[0];
          RepList[RepSize].Replace := Arr[1];
          Inc(RepSize);
        end;
      end;
    end
    else
    begin
      SetLength(RepList, 126 - 32 + 1);
      Replace.Add(STextUtils.Utf8BomAdd());
      for Index := 32 to 126 do
      begin
        RepList[RepSize].Search := Chr(Index);
        RepList[RepSize].Replace := '$' + IntToHex(Index, 2);
        Replace.Add(RepList[RepSize].Search + '=' + RepList[RepSize].Replace + '= ');
        Inc(RepSize);
      end;
      Stream := SFiles.OpenNew(RepFile);
      if Stream <> nil then
      begin
        Replace.SaveToStream(Stream);
        SFiles.CloseStream(Stream);
      end;
    end;
    for Index := 0 to RepSize - 1 do
    begin
      WorkOld := UpperCase(Trim(RepList[Index].Replace));
      Sym := 1;
      WorkNew := '';
      Len := Length(WorkOld);
      while Sym <= Len do
      begin
        if (Sym < Len - 1) and (WorkOld[Sym] = '$') and (WorkOld[Sym + 1] in ['0'
          ..'9', 'A'..'F', 'a'..'f']) and (WorkOld[Sym + 2] in ['0'..'9', 'A'..
          'F', 'a'..'f']) then
        begin
          Ch := UpperCase(Copy(WorkOld, Sym + 1, 2));
          Cnt := Ord(Ch[1]) - Ord('0');
          if Cnt > 9 then
            Cnt := 10 + Ord(Ch[1]) - Ord('A');
          WorkNew := WorkNew + Rounds[16] + Rounds[Cnt];
          Cnt := Ord(Ch[2]) - Ord('0');
          if Cnt > 9 then
            Cnt := 10 + Ord(Ch[2]) - Ord('A');
          WorkNew := WorkNew + Rounds[Cnt] + Rounds[16];
          Inc(Sym, 3);
        end
        else
        begin
          WorkNew := WorkNew + WorkOld[Sym];
          Inc(Sym);
        end;
      end;
      RepList[Index].Replace := WorkNew;
      if Length(StringReplace(RepList[Index].Replace, RepList[Index].Search,
        RepList[Index].Replace, [rfReplaceAll])) > Length(RepList[Index].Replace) then
        RepList[Index].Search := '';
    end;
    Replace.Clear();
    if UpperCase(TextString(SFiles.GetExtension(Name))) = '.TXT' then
    begin
      SFiles.DeleteFile(Name + '.new');
      SFiles.DeleteFile(Name + '.text');
      SFiles.DeleteFile(Name + '.log');
      Imp := True;
      Data := SFiles.ReadEntireFile(SFiles.RemoveExtension(Name), Mb);
      Stream := SFiles.OpenRead(Name);
      Replace.LoadFromStream(Stream);
      SFiles.CloseStream(Stream);
      if Replace.Count > 0 then
        Replace[0] := STextUtils.Utf8BomDel(Replace[0]);
      Cnt := 0;
      for Index := 0 to Replace.Count - 1 do
      begin
        Line := Trim(Replace.Strings[Index]);
        if Line = '' then
          Continue;
        case Line[1] of
          '>', '+':
            Inc(Cnt);
          '$':
            begin
              Delete(Line, 1, 1);
              Line := Trim(Line);
              if Line <> '' then
              begin
                if (Rus.Count < 1) or (Integer(Pointer((Rus.Objects[Rus.Count -
                  1]))) <> Cnt) then
                  Rus.AddObject(Line, Pointer(Cnt));
              end;
            end;
        end;
      end;
      WorkOld := Rus.Text;
      for Index := 0 to RepSize - 1 do
        if RepList[Index].Search <> '' then
          while True do
          begin
            WorkNew := StringReplace(WorkOld, RepList[Index].Search, RepList[Index].Replace,
              [rfReplaceAll]);
            if WorkNew = WorkOld then
              Break;
            WorkOld := WorkNew
          end;
      Replace.Text := WorkNew;
      Failed := False;
      for Index := 0 to Rus.Count - 1 do
      begin
        WorkOld := Replace[Index];
        WorkNew := WorkOld;
        for Cnt := 0 to 16 do
        begin
          WorkOld := StringReplace(WorkOld, Rounds[Cnt], Hexs[Cnt], [rfReplaceAll]);
          WorkNew := StringReplace(WorkNew, Rounds[Cnt], '', [rfReplaceAll]);
        end;
        if WorkNew <> '' then
          Failed := True;
        Rus.Strings[Index] := WorkOld;
      end;
      if Failed then
      begin
        Rus.Text := STextUtils.Utf8BomAdd(Replace.Text);
        Ext := '.log';
      end
      else
      begin
        Replace.Clear();
        for Index := 0 to Rus.Count - 1 do
          Rus.Strings[Index] := STextUtils.HexToStr(Rus.Strings[Index]);
        Ext := '.text';
      end;
      Stream := SFiles.OpenNew(Name + Ext);
      if Stream <> nil then
        Rus.SaveToStream(Stream);
      SFiles.CloseStream(Stream);
      Replace.Clear();
      Assure(not Failed);
    end
    else
    begin
      SFiles.DeleteFile(Name + '.txt');
      Imp := False;
      Data := SFiles.ReadEntireFile(Name, Mb);
    end;
    Assure(Data <> '');
    Wad.UseLevelSub(Data);
    Assure(Wad.Game in [GameSpyro2, GameSpyro3]);
    Order := 0;
    Cnt := 0;
    It := 0;
    for Lev := 1 to 5 do
    begin
      From := Wad.LevelGetSublevelText(Lev, Len);
      if From = nil then
        Break;
      Have.Clear();
      Levels[Lev] := TLevelData.Create();
      Levels[Lev].OpenData(From, Wad.Game);
      Vars := Levels[Lev].GetVariables(Offset, Size);
      Objs := Levels[Lev].GetObjects(Active, Total);
      List.Clear();
      Dups.Clear();
      for Index := 0 to Active - 1 do
      begin
        Tgt := Objs[Index].Variables - Offset;
        if (Tgt < 0) or (Tgt > Size) then
          Continue;
        List.Add(Pointer(Tgt));
      end;
      for Index := 0 to Active - 1 do
      begin
        Tgt := Objs[Index].Variables - Offset + 12;
        if (Tgt < 0) or (Tgt > Size) then
          Continue;
        if List.IndexOf(Pointer(Tgt)) <> -1 then
          Continue;
        if not Levels[Lev].ListChangePointer(Tgt + Offset) then
          Continue;
        Who := CastInt(Vars, Tgt)^ - Offset;
        if (Who < 0) or (Who > Size) then
          Continue;
        Where := Cast(Vars, Who);
        if (CastByte(Where)^ <> 255) and WrongString(Where, False) then
          Continue;
        if Dups.IndexOf(Where) <> -1 then
          Continue;
        Dups.Add(Where);
        Have.Add(Pointer(Tgt or Integer($80000000)));
        How := 0;
        while True do
        begin
          Inc(Tgt, 4);
          if Tgt > Size then
            Break;
          if List.IndexOf(Pointer(Tgt)) <> -1 then
            Break;
          if not Levels[Lev].ListChangePointer(Tgt + Offset) then
            Break;
          Who := CastInt(Vars, Tgt)^ - Offset;
          if (Who < 0) or (Who > Size) then
            Break;
          Where := Cast(Vars, Who);
          Me := Where;
          if (Me^ = 0) or (Me^ = 255) then
            Continue;
          Inc(Me, Me^);
          if Me^ = 0 then
            Continue;
          if WrongString(Where, True) then
            Break;
          if Dups.IndexOf(Where) <> -1 then
            Continue;
          Dups.Add(Where);
          Have.Add(Pointer(Tgt));
          Inc(How);
        end;
        if How = 0 then
          Have.Delete(Have.Count - 1);
      end;
      Knap.Clear();
      Replace.Add('');
      Replace.Add('* ' + IntToStr(Lev));
      for Index := 0 to Have.Count - 1 do
      begin
        Inc(Order);
        while (Cnt < Rus.Count) and (It < Order) do
        begin
          It := Integer(Pointer(Rus.Objects[Cnt]));
          Inc(Cnt);
        end;
        Tgt := Integer(Have[Index]);
        Who := CastInt(Vars, Tgt and $7fffffff)^ - Offset;
        Where := Cast(Vars, Who);
        if (Tgt and $80000000) <> 0 then
        begin
          Tgt := Tgt and $7fffffff;
          Len := AlignValue(StrLen(Where) + 1, 4);
          Replace.Add('');
          if CastByte(Where)^ = 255 then
            Replace.Add('>')
          else
          begin
            Replace.Add('> ' + TextString(CastChar(Where)));
            Replace.Add('$ ');
          end;
        end
        else
        begin
          Me := Where;
          Len := AlignValue(Me^ + StrLen(CastChar(Where, Me^)) + 1, 4);
          if It = Order then
            Rus.Strings[Cnt - 1] := DataStr(Me, Me^) + Rus.Strings[Cnt - 1];
          Replace.Add('+ ' + TextString(CastChar(Me, Me^)));
          Replace.Add('$ ');
        end;
        if It = Order then
        begin
          Knap.AddSpace(Who, Len);
          ZeroMem(Where, Len);
          CastInt(Vars, Tgt)^ := $2d2d2d2d;
          Can := Rus.IndexOf(Rus.Strings[Cnt - 1]);
          if (Can >= 0) and (Can < Cnt - 1) then
            Knap.AddItem(Pointer(Can), Tgt, 0, 1)
          else
            Knap.AddItem(Pointer(Cnt - 1), Tgt, Length(Rus.Strings[Cnt - 1]) + 1, 1);
        end;
      end;
      if Imp then
      begin
        Knap.Compute();
        Take := AlignDiv(Knap.ExtraSpace(), 88);
        Assure(Total - Active - Take > 8);
        Take := Levels[Lev].TakeSomeObjects(Take);
        Vars := Levels[Lev].GetVariables(Offset, Size);
        for Index := 0 to Knap.ItemCount - 1 do
        begin
          Knap.GetItem(Index, Pointer(Cnt), Who, Tgt, Len, Fit);
          if Len = 0 then
          begin
            Can := Integer(Pointer(Rus.Objects[Cnt]));
          end
          else if Fit then
          begin
            Can := Who + Offset + Take;
            CopyMem(Cast(Rus.Strings[Cnt]), Cast(Vars, Who + Take), Len);
          end
          else
          begin
            Can := Who + Offset;
            CopyMem(Cast(Rus.Strings[Cnt]), Cast(Vars, Who), Len);
          end;
          CastInt(Vars, Tgt + Take)^ := Can;
          Rus.Objects[Cnt] := Pointer(Can);
        end;
      end;
      Levels[Lev].SaveData(From);
    end;
    if Imp then
    begin
      SFiles.WriteEntireFile(Name + '.new', Data);
    end
    else
    begin
      if Replace.Count > 0 then
        Replace[0] := STextUtils.Utf8BomAdd(Replace[0]);
      Stream := SFiles.OpenNew(Name + '.txt');
      Replace.SaveToStream(Stream);
      FreeAndNil(Stream);
    end;
  except
    Writeln('ERROR!');
  end;
  for Index := 1 to 5 do
    Levels[Index].Free();
  Knap.Free();
  Wad.Free();
  Replace.Free();
  Stream.Free();
  List.Free();
  Dups.Free();
  Have.Free();
  Rus.Free();
end;

//

procedure Proj_JapFont(const Name: WideString);
var
  Stream: THandleStream;
  Size: Int64;
  Vram, Font: TVram;
  Palette: RPalette;
  Bitmap: TBitmap;
  Savestate: TSavestateReader;
begin
  Stream := nil;
  Vram := nil;
  Bitmap := nil;
  Font := nil;
  Savestate := nil;
  try
    if LowerCase(TextString(SFiles.GetExtension(Name))) = '.bmp' then
    begin
      Bitmap := SBitmaps.FromFile(Name);
      Assure(Bitmap <> nil);
      Assure((Bitmap.PixelFormat = pf8bit) and (Bitmap.Width = 2048) and (Bitmap.Height
        = 40));
      SBitmaps.GetPalette(Bitmap, Palette);
      Vram := TVram.Create();
      Assure(Vram.LoadIndex(Bitmap));
      Font := TVram.Create();
      Assure(Font.Convert(Vram, 4, 15));
      Assure(Font.SetPalette(352, 39, 16, Palette));
      Font.SaveAs(Name + WideString('.sub'), 0);
      Savestate := TSavestateReader.Create();
      Assure(Savestate.ReadFrom(SFiles.RemoveExtension(Name)));
      Vram.Open(1024, 512);
      Assure(Vram.ReadFrom(Savestate.Vram, Savestate.VramSize));
      Assure(Vram.DrawRect(Font, 0, 512 - 40));
      Vram.SaveTo(Savestate.Vram, Savestate.VramSize);
      Savestate.WriteTo(Name + WideString('.sav'));
    end
    else
    begin
      Stream := SFiles.OpenRead(Name);
      Assure(Stream <> nil);
      Size := Stream.Size;
      if Size = 512 * 40 * 2 then
      begin
        Vram := TVram.Create();
        Assure(Vram.Open(512, 40));
        Assure(Vram.ReadFrom(Stream));
        Assure(Vram.GetPalette(352, 39, 16, Palette));
        Font := TVram.Create();
        Assure(Font.Convert(Vram, 15, 4));
        Bitmap := TBitmap.Create();
        Font.RenderIndex(Bitmap, True, Palette);
        SBitmaps.ToFile(Bitmap, Name + WideString('.bmp'));
      end
      else
      begin
        Savestate := TSavestateReader.Create();
        Assure(Savestate.ReadFrom(Stream));
        Vram := TVram.Create();
        Assure(Vram.Open(1024, 512));
        Assure(Vram.ReadFrom(Savestate.Vram, Savestate.VramSize));
        Assure(Vram.GetPalette(352, 511, 16, Palette));
        Font := TVram.Create();
        Font.Open(512, 40);
        Font.CopyRect(Vram, 0, 512 - 40);
        Assure(Vram.Convert(Font, 15, 4));
        Bitmap := TBitmap.Create();
        Vram.RenderIndex(Bitmap, True, Palette);
        SBitmaps.ToFile(Bitmap, Name + WideString('.bmp'));
      end;
    end;
  finally
    SFiles.CloseStream(Stream);
    Vram.Free();
    Bitmap.Free();
    Font.Free();
    Savestate.Free();
  end;
end;

//

procedure Proj_SavestateDump(const Name: WideString);
var
  Ss: TSavestateReader;
begin
  Ss := nil;
  try
    Ss := TSavestateReader.Create();
    if LowerCase(ExtractFileExt(Name)) = '.mem' then
    begin
      if Ss.ReadFrom(SFiles.RemoveExtension(Name)) then
      begin
        CopyMem(Cast(SFiles.ReadEntireFile(Name, Ss.MemorySize, Ss.MemorySize)),
          Ss.Memory, Ss.MemorySize);
        Ss.WriteTo(Name + '.sav');
      end;
    end
    else if LowerCase(ExtractFileExt(Name)) = '.gpu' then
    begin
      if Ss.ReadFrom(SFiles.RemoveExtension(Name)) then
      begin
        CopyMem(Cast(SFiles.ReadEntireFile(Name, Ss.VramSize, Ss.VramSize)), Ss.Vram,
          Ss.VramSize);
        Ss.WriteTo(Name + '.sav');
      end;
    end
    else if Ss.ReadFrom(Name) then
    begin
      SFiles.WriteEntireFile(Name + '.mem', Ss.Memory, Ss.MemorySize);
      SFiles.WriteEntireFile(Name + '.gpu', Ss.Vram, Ss.VramSize);
    end;
  except
  end;
  Ss.Free();
end;

//

procedure Proj_RepackS1Models(const Name: WideString);
var
  Src, Base, Dst, Txt: WideString;
  Index: Integer;
  Wad: TWadManager;
  Arr: AJap022Data;
  Strs: ArrayOfData;
  Line: TextString;
  Flag, Num: PTextChar;
const
  Max = 1024 * 1024;
begin
  Wad := nil;
  SetLength(Arr, 0);
  with SFiles, STextUtils do
  try
    Src := NoBackslash(GetFullName(Name));
    Base := GetLastSlash(Src, True);
    if IsDirectory(Src) then
    begin
      Src := Src + WideString('\') + RemoveExtension(Base);
      Txt := Src + WideString('.txt');
      Dst := Src + WideString('.new');
      DeleteFile(Dst);
      Strs := SplitChar(ReadEntireFile(Txt, Max), [#13, #10, #0]);
      Assure(Length(Strs) > 0);
      SetLength(Arr, Length(Strs));
      for Index := 0 to Length(Strs) - 1 do
      begin
        Line := Strs[Index];
        Flag := Cast(Line);
        Num := StringToken(Flag, [' ', #9]);
        Arr[Index].Flag := StrToInt64(Trim(TextString(Flag)));
        Arr[Index].Data := ReadEntireFile(Src + Trim(TextString(Num)), Max);
        Assure(Arr[Index].Data <> '');
      end;
      WriteEntireFile(Dst, Wad.Jap022Save(Arr));
    end
    else
    begin
      Dst := Src + '.jap' + WideString('\');
      Txt := Dst + Base + WideString('.txt');
      CreateDirectory(Dst);
      Assure(IsDirectory(Dst));
      DeleteFile(Txt);
      Arr := Wad.Jap022Load(ReadEntireFile(Src, Max, 8));
      Assure(Length(Arr) > 0);
      SetLength(Strs, Length(Arr));
      for Index := 0 to Length(Arr) - 1 do
      begin
        Assure(WriteEntireFile(Dst + Base + WideString('_' + IntToStrPad(Index,
          3)), Arr[Index].Data));
        Strs[Index] := '_' + IntToStrPad(Index, 3) + #9 + IntToStr(Arr[Index].Flag);
      end;
      WriteEntireFile(Txt, JoinString(Strs, #13#10, True));
    end;
  except
  end;
end;

//

procedure Proj_Spyro1Gui(const Name: WideString);
var
  Mdl: TModelS1;
  Obj: TObjModel;
  Data: DataString;
  Target: WideString;
const
  Max = 1024 * 1024;
begin
  Target := '';
  Obj := nil;
  Mdl := nil;
  with SFiles, STextUtils do
  try
    if LowerCase(TextString(GetExtension(Name))) = '.obj' then
    begin
      Target := Name + WideString('.sp1');
      Obj := TObjModel.Create();
      Obj.ReadFrom(Name);
      Mdl := TModelS1.Create();
      Assure(Mdl.LoadObj(Obj));
      WriteEntireFile(Target, Mdl.RawData());
    end
    else
    begin
      Target := Name + WideString('.obj');
      Data := ReadEntireFile(Name, Max, 16);
      Assure(Data <> '');
      Mdl := TModelS1.Create();
      Mdl.OpenRead(Data);
      Obj := TObjModel.Create();
      Assure(Mdl.SaveObj(Obj));
      Obj.WriteTo(Target);
    end;
  except
    if Target <> '' then
      DeleteFile(Target);
  end;
  Mdl.Free();
  Obj.Free();
end;

//

procedure Proj_ObjTextureToColor(const Name: WideString);
var
  Obj: TObjModel;
begin
  Obj := nil;
  try
    Obj := TObjModel.Create();
    Obj.ReadFrom(Name);
    Obj.TextureToColor();
    Obj.WriteTo(Name + WideString('.vc.obj'));
  except
  end;
  Obj.Free();
end;

//

procedure Proj_SpyroModelGet(const Name: WideString);
var
  Buffer: DataString;
  Data: Pointer;
  Index, Mdl: Integer;
  Vram, Egg: TVram;
  Wad: TWadManager;
  Size, Entity: Integer;
  Model: Pointer;
  Gold: TGoldenFont;
  Man: TTextureManager;
  Bitmap: TBitmap;
  Base, Path: WideString;
  Sub, X, Y: Integer;
  Arr: ALevelData;
  Files: ArrayOfWide;
  Obj: TObjModel;
  Clears: Boolean;
begin
  Egg := nil;
  Bitmap := nil;
  Man := nil;
  Vram := nil;
  Wad := nil;
  Gold := nil;
  Obj := nil;
  SetLength(Arr, 0);
  SetLength(Files, 0);
  Path := SFiles.NoBackslash(SFiles.GetFullName(Name));
  if SFiles.IsDirectory(Name) then
  begin
    Writeln('Textures: ', ExtractFileName(TextString(Path)));
    Base := Path + WideString('\');
    Path := Base + WideString('textures');
    Vram := TVram.Create();
    Egg := TVram.Create();
    if Vram.ReadAs(Path, 0, 512, 512) then
    begin
      Bitmap := TBitmap.Create();
      Man := TTextureManager.Create();
      Files := SFiles.GetAllFiles(Base);
      for Index := 0 to Length(Files) - 1 do
        if LowerCase(TextString(SFiles.GetExtension(Files[Index]))) = '.mdl' then
        begin
          try
            Path := Base + Files[Index];
            Buffer := SFiles.ReadEntireFile(Path);
            Assure(Buffer <> '');
            Path := SFiles.RemoveExtension(Path);
            Gold := TGoldenFont.Create(Cast(Buffer));
            Man.Clear();
            Gold.Textures(Man);
            SBitmaps.SetSize(Bitmap, 0, 0);
            if Egg.ReadAs(Path + WideString('.texture'), 0, 64, 96) then
              Vram.DrawRect(Egg, 384, 256);
            Man.Render(Vram, Bitmap);
            SBitmaps.ToFile(Bitmap, Path + WideString('.bmp'));
          except
            Writeln('Error!');
          end;
          FreeAndNil(Gold);
        end;
    end;
  end
  else
  try
    Egg := TVram.Create();
    Bitmap := TBitmap.Create();
    Man := TTextureManager.Create();
    Wad := TWadManager.Create();
    Buffer := SFiles.ReadEntireFile(Name);
    Assure(CastInt(Buffer, 4)^ > 0);
    Base := Path + WideString('.models');
    SFiles.CreateDirectory(Base);
    Assure(SFiles.IsDirectory(Base));
    if CastInt(Buffer, 4)^ < 2048 then
    begin
      Writeln('Cutscene: ', ExtractFileName(TextString(Path)));
      Base := Base + SFiles.GetLastSlash(Path);
      Arr := Wad.CutSubfileExportTracks(Wad.CutSubfileExportBlocks(Cast(Buffer),
        Length(Buffer)));
      Sub := 1;
      while True do
      begin
        Index := Wad.CutSubfileGetModel(Arr, Sub);
        if Index < 0 then
          Break;
        Model := Cast(Arr[Index].Data);
        Path := Base + WideString('_mdl_cut_' + IntToStr(Sub)) + '_' +
          WideString(IntToStr(Wad.ModelFrames(Model)));
        SFiles.WriteEntireFile(Path + WideString('.mdl'), Model, Length(Arr[Index].Data));
        Inc(Sub);
      end;
    end
    else
    begin
      Writeln('Level: ', ExtractFileName(TextString(Path)));
      Assure(Wad.UseLevelSub(Buffer));
      Wad.LoadLevelParts();
      Data := Wad.LevelGetVram(Size);
      SFiles.WriteEntireFile(Base + '\' + WideString('textures'), Data, Size);
      Base := Base + SFiles.GetLastSlash(Path);
      Vram := TVram.Create();
      Vram.Open(512, 512);
      Assure(Vram.ReadFrom(Data, Size));
      for Index := 1 to 8 do
      begin
        Model := Wad.LevelGetEggModel(Size, Index);
        if (Model = nil) or (Size < 4) then
          Break;
        try
          Path := Base + WideString('_mdl_egg_' + IntToStr(Index)) + '_' +
            WideString(IntToStr(Wad.ModelFrames(Model)));
          Gold := TGoldenFont.Create(Model);
          SFiles.WriteEntireFile(Path + WideString('.mdl'), Model, Size);
          Assure(Wad.LevelGetEggTexture(Index, Egg, X, Y));
          Assure(Vram.DrawRect(Egg, X, Y));
          Man.Clear();
          Gold.Textures(Man);
          SBitmaps.SetSize(Bitmap, 0, 0);
          Man.Render(Vram, Bitmap);
          SBitmaps.ToFile(Bitmap, Path + WideString('.bmp'));
          Egg.SaveAs(Path + WideString('.texture'), 0);
          //Obj := TObjModel.Create();
          //Gold.SaveObj(Obj, 0, Man);
          //Obj.WriteTo(Path + WideString('.obj'), 15, True);
          Obj := TObjModel.Create();
          for Mdl := 0 to Gold.ModelCount() - 1 do
          begin
            Gold.SaveObj(Obj, Mdl, Man);
            Obj.Optimize();
            Obj.WriteTo(Path + WideString('.' + STextUtils.IntToStrPad(Mdl + 1,
              2) + '.obj'), 4);
          end;
        except
        end;
        FreeAndNil(Gold);
        FreeAndNil(Obj);
      end;
      for Sub := 1 to 5 do
      begin
        Index := 0;
        while True do
        begin
          try
            Model := Wad.LevelGetModel(Size, Index, Entity, Sub);
            if (Model = nil) or (Size < 4) then
              Break;
            Assure(Entity <> 0);
            Path := Base + WideString('_mdl_' + IntToStr(Sub) + '_' + STextUtils.IntToStrPad
              (Index, 2) + '_' + IntToStr(Entity));
            if Wad.ModelAnimated(Model) then
              Path := Path + WideString('_A')
            else
              Path := Path + WideString('_S');
            Path := Path + WideString(IntToStr(Wad.ModelFrames(Model)));
            Gold := TGoldenFont.Create(Model);
            SFiles.WriteEntireFile(Path + WideString('.mdl'), Model, Size);
            Man.Clear();
            Gold.Textures(Man);
            SBitmaps.SetSize(Bitmap, 0, 0);
            Man.Render(Vram, Bitmap);
            SBitmaps.ToFile(Bitmap, Path + WideString('.bmp'));
            Clears := False;
            for Mdl := 0 to Gold.ModelCount() - 1 do
              if Gold.ModelFrames(Mdl) <> 1 then
                Clears := True;
            Obj := TObjModel.Create();
            for Mdl := 0 to Gold.ModelCount() - 1 do
            begin
              if Clears then
                Obj.Clear();
              Gold.SaveObj(Obj, Mdl, Man);
              if Clears then
              begin
                Obj.Optimize();
                Obj.WriteTo(Path + WideString('.' + STextUtils.IntToStrPad(Mdl +
                  1, 2) + '.obj'), 4);
              end;
            end;
            if not Clears then
            begin
              Obj.Optimize();
              Obj.WriteTo(Path + WideString('.00.obj'), 4);
            end;
          except
          end;
          FreeAndNil(Gold);
          FreeAndNil(Obj);
          Inc(Index);
        end;
      end;
    end;

  except
    Writeln('Error!');
  end;
  Gold.Free();
  Vram.Free();
  Wad.Free();
  Man.Free();
  Bitmap.Free();
  Egg.Free();
  Obj.Free();
end;

//

function Proj_SaveWad(const Args: ArrayOfWide): Boolean;
var
  Cnt: Integer;
//  Save: Boolean;
  Iso: TIsoReader;
  Format: TextString;
  List: AIsoFileList;
  Index: Integer;
  Seek: TextString;
  Lba, Size: Integer;
  Buffer: DataString;
  Mem: Pointer;
  Count: Integer;
  Buf: THandleStream;
  Save: TBufferedWrite;
  Load: TBufferedRead;
  Ecc: TEccEdc;
  Old: Integer;
  Progress: TConsoleProgress;
const
  BufferSectors = 60;
begin
  SetLength(List, 0);
  Result := True;
  Cnt := Length(Args) - 1;
  if (Cnt < 1) or (Cnt > 4) or ((Cnt = 4) and (Args[3] <> '>')) then
  begin
    Result := False;
    Exit;
  end;
  Iso := nil;
  Save := nil;
  Buf := nil;
  Load := nil;
  Ecc := nil;
  Progress := nil;
  SetLength(Format, 4);
  try
    case Cnt of
      1:
        begin
          Iso := TIsoReader.Create(Cnt = 3, Args[1]);
          Iso.GuessImageFormat(Cast(Format));
          List := Iso.GetFileList();
          for Index := 0 to Length(List) - 1 do
            Writeln('"', List[Index].Name, '" - LBA = ', List[Index].Lba,
              ', Size = ', List[Index].Size);
        end;
      2, 4:
        begin
          Iso := TIsoReader.Create(Cnt = 3, Args[1]);
          Iso.GuessImageFormat(Cast(Format));
          List := Iso.GetFileList();
          if Cnt = 4 then
            Buf := SFiles.OpenNew(Args[4])
          else
            Buf := THandleStream.Create(GetStdHandle(STD_OUTPUT_HANDLE));
          Save := TBufferedWrite.Create(128 * 1024);
          Save.Open(Buf);
          Seek := UpperCase(Args[2]);
          Lba := -1;
          Size := 0;
          if Seek <> '' then
            for Index := 0 to Length(List) - 1 do
              if Pos(Seek, UpperCase(List[Index].Name)) > 0 then
              begin
                Assure(Lba = -1);
                Lba := List[Index].Lba;
                Size := List[Index].Size;
              end;
          Assure(Lba <> -1);
          SetLength(Buffer, BufferSectors * Iso.Total);
          Iso.SeekToSector(Lba);
          while Size > 0 do
          begin
            Mem := Cast(Buffer);
            Count := AlignValue(Size, 2048) div 2048;
            if Count > BufferSectors then
              Count := BufferSectors;
            Iso.ReadSectors(Mem, Count);
            Adv(Mem, 8);
            for Index := 1 to Count do
            begin
              if Size > 2048 then
              begin
                Save.WriteBuffer(Mem^, 2048);
                Dec(Size, 2048);
              end
              else
              begin
                Save.WriteBuffer(Mem^, Size);
                Size := 0;
                Break;
              end;
              Adv(Mem, Iso.Total);
            end;
          end;
        end;
      3:
        try
          Iso := TIsoReader.Create(Cnt = 3, Args[1]);
          Iso.GuessImageFormat(Cast(Format));
          List := Iso.GetFileList();
          Writeln('Iso: "', Args[1], '"');
          Seek := UpperCase(Args[2]);
          Writeln('Seek: "', Seek, '"');
          Writeln('From: "', Args[3], '"');
          Ecc := TEccEdc.Create();
          Buf := SFiles.OpenRead(Args[3]);
          Load := TBufferedRead.Create(128 * 1024, 0);
          Load.Open(Buf);
          Writeln('Size: ', Buf.Size);
          Lba := -1;
          Size := 0;
          if Seek <> '' then
            for Index := 0 to Length(List) - 1 do
              if Pos(Seek, UpperCase(List[Index].Name)) > 0 then
              begin
                Size := List[Index].Size;
                Writeln('Found: "', List[Index].Name, '", size - ', Size);
                Assure(Lba = -1);
                Lba := List[Index].Lba;
              end;
          Assure((Lba <> -1) and (Size = Buf.Size));
          SetLength(Buffer, BufferSectors * Iso.Total);
          Iso.SeekToSector(Lba);
          Writeln('Working...');
          Progress := TConsoleProgress.Create(0, Size);
          Progress.Show(Size);
          while Size > 0 do
          begin
            Old := Iso.Sector;
            Mem := Cast(Buffer);
            Count := AlignValue(Size, 2048) div 2048;
            if Count > BufferSectors then
              Count := BufferSectors;
            Iso.ReadSectors(Mem, Count);
            Adv(Mem, 8);
            for Index := 1 to Count do
            begin
              if Size > 2048 then
              begin
                Load.ReadBuffer(Mem^, 2048);
                Dec(Size, 2048);
              end
              else
              begin
                ZeroMem(Mem, 2048);
                Load.ReadBuffer(Mem^, Size);
                Size := 0;
                Break;
              end;
              Adv(Mem, Iso.Total);
            end;
            Progress.Show(Size);
            Mem := Cast(Buffer);
            for Index := 1 to Count do
            begin
              Ecc.ecc_edc_mode2(Mem);
              Adv(Mem, Iso.Total);
            end;
            Iso.SeekToSector(Old);
            Iso.WriteSectors(Cast(Buffer), Count);
          end;
          Progress.Success();
          Writeln('Done!');
        except
          Writeln('ERROR');
          if Args[0] <> '' then
            Halt(1);
        end;
    end;
  finally
    Progress.Free();
    Ecc.Free();
    Iso.Free();
    Save.Free();
    Load.Free();
    if Cnt = 4 then
      SFiles.CloseStream(Buf)
    else
      Buf.Free();
  end;
end;

//

procedure Proj_SaveWadAuto(const Name: WideString);
var
  Test: THandleStream;
  Wait: TextString;
  Files: ArrayOfWide;
  Index, Size: Integer;
  Bin, Iso, Dir, Seek: WideString;
  Ext: TextString;
  Image: TIsoReader;
  List: AIsoFileList;

  procedure ShowAndExit(Text: TextString = '');
  begin
    Writeln(Text);
    Abort;
  end;

begin
  SetLength(List, 0);
  SetLength(Files, 0);
  try
    Bin := '';
    Iso := '';
    Dir := SFiles.GetProgramDirectory();
    Files := SFiles.GetAllFiles(Dir, Exclude);
    for Index := 0 to Length(Files) - 1 do
    begin
      Ext := UpperCase(TextString(SFiles.GetExtension(Files[Index])));
      if Ext = '.BIN' then
      begin
        if Bin <> '' then
          Bin := '?'
        else
          Bin := Files[Index];
      end
      else if Ext = '.ISO' then
      begin
        if Iso <> '' then
          Iso := '?'
        else
          Iso := Files[Index];
      end;
    end;
    if Iso = '' then
      Iso := Bin;
    if (Iso = '') or (Iso = '?') then
    begin
      if Iso = '?' then
        ShowAndExit('More than one .iso/.bin are in "' + Dir + '"')
      else
        ShowAndExit('No .iso/.bin image is found in "' + Dir + '"');
    end;
    Iso := Dir + Iso;
    if SFiles.GetFullName(Name) = SFiles.GetFullName(Iso) then
    begin
      Writeln('= Info mode =');
      Writeln('Image: "', Iso, '"');
      Writeln('');
      try
        Proj_SaveWad(MakeArray(['', Iso]));
        Writeln('');
        Writeln('Done!');
      except
        Writeln('');
        Writeln('ERROR');
      end;
      ShowAndExit();
    end;
    if SFiles.IsDirectory(Name) then
    begin
      Writeln('= List mode =');
      Writeln('');
      Writeln('Create in: "', Iso, '"');
      Writeln('');
      Dir := SFiles.NoBackslash(SFiles.GetFullName(Name)) + WideString('\');
      Image := nil;
      try
        Image := TIsoReader.Create(False, Iso);
        Image.GuessImageFormat();
        List := Image.GetFileList();
        FreeAndNil(Image);
        for Index := 0 to Length(List) - 1 do
        begin
          Bin := Trim(List[Index].Name);
          Bin := StringReplace(Bin, '\', '~', [rfReplaceAll]);
          Writeln('"', List[Index].Name, '" - "', Bin, '"');
          SFiles.TouchFile(Dir + Bin);
        end;
        Writeln('');
        Writeln('Done!');
      except
        Writeln('');
        Writeln('ERROR');
      end;
      Image.Free();
      ShowAndExit('');
    end;

    Test := SFiles.OpenRead(Name);
    if Test = nil then
      ShowAndExit('Can''t open your "' + Name + '"');
    Size := Test.Size;
    SFiles.CloseStream(Test);
    Seek := StringReplace(SFiles.GetLastSlash(Name, True), '~', '\', [rfReplaceAll]);
    if Size = 0 then
    begin
      Writeln('= Export mode =');
      Writeln('');
      Writeln('Image: "', Iso, '"');
      Writeln('Seek for: "', UpperCase(TextString(Seek)), '"');
      Writeln('Save to: "', Name, '"');
      try
        Proj_SaveWad(MakeArray(['', Iso, Seek, '>', Name]));
        Writeln('');
        Writeln('Done!');
      except
        Writeln('');
        Writeln('ERROR');
      end;
      ShowAndExit('');
    end;
    Writeln('= Import mode =');
    Writeln('');
    try
      Proj_SaveWad(MakeArray(['', Iso, Seek, Name]));
    except
    end;
    ShowAndExit('');
  except
  end;
  SFiles.CloseStream(Test);
end;

//

end.

