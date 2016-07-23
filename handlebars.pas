unit Handlebars;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, fpjson, HandlebarsParser, DataContext;

type

  { THandlebarsTemplate }

  THandlebarsTemplate = class
  private
    FProgram: THandlebarsProgram;
    FSource: String;
    procedure DoCompile;
    procedure SetSource(AValue: String);
  public
    destructor Destroy; override;
    procedure Compile;
    function Render(Context: TDataContext): String;
    function Render(Data: TJSONData): String;
    function Render(Instance: TObject): String;
    property Source: String read FSource write SetSource;
  end;

function RenderTemplate(const TemplateSrc: String; Data: TJSONObject): String;

implementation

function RenderTemplate(const TemplateSrc: String; Data: TJSONObject): String;
var
  Template: THandlebarsTemplate;
begin
  Template := THandlebarsTemplate.Create;
  try
    Template.Source := TemplateSrc;
    Result := Template.Render(Data);
  finally
    Template.Destroy;
  end;
end;

{ THandlebarsTemplate }

procedure THandlebarsTemplate.SetSource(AValue: String);
begin
  if FSource = AValue then Exit;
  FSource := AValue;
  FreeAndNil(FProgram);
end;

procedure THandlebarsTemplate.DoCompile;
var
  Parser: THandlebarsParser;
begin
  Parser := THandlebarsParser.Create(FSource);
  try
    FProgram := Parser.Parse;
  finally
    Parser.Destroy;
  end;
end;

destructor THandlebarsTemplate.Destroy;
begin
  FProgram.Free;
  inherited Destroy;
end;

procedure THandlebarsTemplate.Compile;
begin
  if FProgram = nil then
    DoCompile;
end;

function THandlebarsTemplate.Render(Context: TDataContext): String;
begin
  if FProgram = nil then
    DoCompile;
  Result := FProgram.GetText(Context);
end;

function THandlebarsTemplate.Render(Data: TJSONData): String;
var
  Context: TJSONDataContext;
begin
  Context := TJSONDataContext.Create(Data);
  try
    Result := Render(Context);
  finally
    Context.Destroy;
  end;
end;

function THandlebarsTemplate.Render(Instance: TObject): String;
var
  Context: TDataContext;
begin
  Context := CreateContext(Instance);
  try
    Result := Render(Context);
  finally
    Context.Destroy;
  end;
end;

end.

