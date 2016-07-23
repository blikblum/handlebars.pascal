unit DataContext;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, fpjson;

type

  { TDataContext }

  TDataContext = class
  private
    FParent: TDataContext;
  public
    function ResolvePath(const Path: array of String): Variant; virtual; abstract;
    property Parent: TDataContext read FParent;
  end;

  { TRTTIDataContext }

  TRTTIDataContext = class(TDataContext)
  private
    FInstance: TObject;
  public
    constructor Create(Instance: TObject);
    function ResolvePath(const Path: array of String): Variant; override;
  end;

  { TJSONDataContext }

  TJSONDataContext = class(TDataContext)
  private
    FData: TJSONData;
  public
    constructor Create(Data: TJSONData);
    function ResolvePath(const Path: array of String): Variant; override;
  end;

function CreateContext(Instance: TObject): TDataContext;

implementation

uses
  typinfo;

function CreateContext(Instance: TObject): TDataContext;
begin
  if Instance is TJSONData then
    Result := TJSONDataContext.Create(TJSONData(Instance))
  else
    Result := TRTTIDataContext.Create(Instance);
end;

{ TJSONDataContext }

constructor TJSONDataContext.Create(Data: TJSONData);
begin
  FData := Data;
end;

function TJSONDataContext.ResolvePath(const Path: array of String): Variant;
var
  i: Integer;
  ObjData: TJSONObject;
  PropData: TJSONData;
  PropName: String;
begin
  Result := Unassigned;
  if FData.JSONType = jtObject then
  begin
    ObjData := TJSONObject(FData);
    for i := Low(Path) to High(Path) do
    begin
      PropName := Path[i];
      if i = High(Path) then
        Result := ObjData.Get(PropName)
      else
      begin
        PropData := ObjData.Find(PropName, jtObject);
        if PropData <> nil then
          ObjData := TJSONObject(PropData)
        else
          break;
      end;
    end;
  end;
end;

{ TRTTIDataContext }

constructor TRTTIDataContext.Create(Instance: TObject);
begin
  FInstance := Instance;
end;

function TRTTIDataContext.ResolvePath(const Path: array of String): Variant;
var
  i: Integer;
  PropName: String;
  PropInfo: PPropInfo;
  Obj: TObject;
begin
  Result := Unassigned;
  Obj := FInstance;
  for i := Low(Path) to High(Path) do
  begin
    PropName := Path[i];
    PropInfo := GetPropInfo(Obj, PropName);
    if PropInfo = nil then
      break;
    if i = High(Path) then
      Result := GetPropValue(Obj, PropName)
    else
    begin
      if PropInfo^.PropType^.Kind = tkClass then
      begin
        Obj := GetObjectProp(Obj, PropInfo);
        if Obj = nil then
          break;
      end
      else
        break;
    end;
  end;
end;

end.

