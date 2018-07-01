unit SHL_Projects; // SpyroHackingLib is licensed under WTFPL

interface

uses
  Windows, SHL_Types;

type
  MProcess = procedure(const Param: WideString);

function Project(Process: MProcess; const ShowHelp: TextString = ''): Boolean;

procedure Proj_Null(const Name: WideString);

procedure Proj_JapTab(const Name: WideString);

procedure Proj_GhTab(const Name: WideString);

procedure Proj_JapFont(const Name: WideString);

procedure Proj_SavestateDump(const Name: WideString);

procedure Proj_RepackS1Models(const Name: WideString);

procedure Proj_Spyro1Gui(const Name: WideString);

procedure Proj_ObjTextureToColor(const Name: WideString);

procedure Proj_SpyroModelGet(const Name: WideString);

implementation

uses
  SysUtils, Classes, Graphics, SHL_VramManager, SHL_Bitmaps, SHL_TextureManager,
  SHL_GoldenFont, SHL_PlayStream, SHL_SavestateReader, SHL_Gzip,
  SHL_ProcessStream, SHL_LameStream, SHL_WaveStream, SHL_IsoReader, SHL_Progress,
  SHL_XaMusic, SHL_EccEdc, SHL_GmlModel, SHL_Files, SHL_ObjModel,
  SHL_BufferedStream, SHL_Models3D, SHL_WadManager, SHL_TextUtils, SHL_PosWriter,
  SHL_MemoryManager, SHL_Knapsack, SHL_LevelData, SHL_ModelS1;

function Project(Process: MProcess; const ShowHelp: TextString = ''): Boolean;
begin
  Result := SFiles.ProcessArguments(Process, ShowHelp);
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
        Need := AlignValue(Need, 88) div 88;
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

type
  PGhTab = ^RGhTab;

  RGhTab = record
    V1, V2, V3, Text, Data, V4: Integer;
  end;

procedure Proj_GhTab(const Name: WideString);
var
  Level: TLevelData;
  Index, Active, Total, Cnt, Offset, Size, Len, Need, Next, Tex: Integer;
  Data: DataString;
  Vars, From: Pointer;
  Objs: PLevelObjectsArr;
  Knap: TKnapsack;
  Line, Load: DataString;
  KOffset, KName, KSize: Integer;
  KAddr, Save: Pointer;
  KFit: Boolean;
  Obj: PLevelObject;
  Jap: PGhTab;
  Wad: TWadManager;
  Use: Boolean;
  Replace: TStringList;
  Stream: THandleStream;
  Character: PLevelCharacter;
  Skip: Byte;
const
  Mb = 8 * 1024 * 1024;
begin
  Writeln(Name);
  Level := nil;
  Knap := nil;
  Wad := nil;
  Replace := nil;
  Stream := nil;
  Jap := nil;
  try
    Wad := TWadManager.Create();
    Knap := TKnapsack.Create();
    Level := TLevelData.Create();
    Replace := TStringList.Create();
    Stream := SFiles.OpenRead(Name + '.txt');
    if Stream <> nil then
    begin
     // Replace.LoadFromStream(Stream);
      FreeAndNil(Stream);
    end;
    Use := Replace.Count > 0;
    Data := SFiles.ReadEntireFile(Name, Mb);
    Assure(Data <> '');
    SFiles.DeleteFile(Name + '.new');
    Wad.UseLevelSub(Data);
    Assure(Wad.Game in [GameSpyro2, GameSpyro3]);

    From := Wad.LevelGetSublevelText(1, Len);
    Level.OpenData(From, Wad.Game);
    Vars := Level.GetVariables(Offset, Size);
    Objs := Level.GetObjects(Active, Total);
    Writeln('Objects: active - ', Active, ', empty - ', Total - Active);
    Cnt := 0;
    for Index := 0 to Active - 1 do
      if Level.IsCharacter(Index) then
      begin
        Obj := @Objs[Index];
        Character := Cast(Vars, Obj.Variables - Offset);
        Next := Character.NameOffset - Offset;
        Tex := 0;
        while (Next >= 0) and (Next < Size) do
        begin
//        Writeln(Data);
////      if (Jap.V1 <> 0) or (Jap.V2 <> 0) or (Jap.V3 <> 0) or (Jap.V4 <> 0) or (Jap.Data
//        <> Obj.Variables + 20) then
//        Writeln('STRANGE DATA!');
//      Line := DataString(CastChar(Vars, Jap.Text - Offset));
//      Writeln(Character.What);

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
            Skip := CastByte(Vars, Next)^;
            if Tex > 0 then
            begin
              if Skip = 0 then
                Line := '+ ?'
              else if Skip = 255 then
                Line := '+ -'
              else
                Line := '+ ' + CastChar(Vars, Next + Skip);
            end
            else
            begin
              Replace.Add('');
              if Skip = 0 then
                Line := '> ?'
              else if Skip = 255 then
                Line := '> -'
              else
                Line := '> ' + CastChar(Vars, Next);
            end;
            Replace.Add(Line);
          end;
          Inc(Cnt);
          Inc(Tex);
          Next := Character.TextOffset[Tex] - Offset;
        end;
      end;
    Writeln('Characters: ', Cnt);
    if Use then
    begin
      Need := Knap.Compute();
      if Need > 0 then
      begin
        Need := AlignValue(Need, 88) div 88;
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
  {
  if Replace <> nil then
  begin
    Line := '';
    for Index := 0 to Replace.Count - 1 do
      Line := Line + Replace[Index] + '00';
    SFiles.WriteEntireFile(Name + '.bin', STextUtils.HexToStr(Line));
  end;
  }
  Level.Free();
  Knap.Free();
  Wad.Free();
  Replace.Free();
  Stream.Free();
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

end.
