unit HandlebarsParser;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, contnrs, HandlebarsScanner, DataContext;

type
  THandlebarsHash = class;
  THandlebarsProgram = class;
  THandlebarsStatement = class;

  TStripFlag = (sfOpen, sfClose);

  TStripFlags = set of TStripFlag;

  TStringArray = array of String;

  { THandlebarsNode }

  THandlebarsNode = class
  protected
    function GetNodeType: String;
  public
    function GetText(Context: TDataContext): String; virtual; abstract;
    property NodeType: String read GetNodeType;
  end;

  THandlebarsExpression = class(THandlebarsNode)
  private
  end;

  { THandlebarsPathExpression }

  THandlebarsPathExpression = class(THandlebarsExpression)
  private
    FOriginal: String;
    FParts: TStringArray;
    FDepth: Integer;
    FData: Boolean;
  public
    property Data: Boolean read FData;
    property Depth: Integer read FDepth;
    property Original: String read FOriginal;
    property Parts: TStringArray read FParts;
  end;

  { THandlebarsSubExpression }

  THandlebarsSubExpression = class(THandlebarsExpression)
  private
    FPath: THandlebarsPathExpression;
    FParams: TFPObjectList; //[ Expression ];
    FHash: THandlebarsHash;
    function GetParamCount: Integer;
    function GetParams(Index: Integer): THandlebarsExpression;
  public
    destructor Destroy; override;
    property Hash: THandlebarsHash read FHash;
    property Params[Index: Integer]: THandlebarsExpression read GetParams;
    property ParamCount: Integer read GetParamCount;
    property Path: THandlebarsPathExpression read FPath;
  end;

  { THandlebarsLiteral }

  THandlebarsLiteral = class(THandlebarsExpression)
  private
    function GetAsString: String; virtual; abstract;
  public
    property AsString: String read GetAsString;
  end;

  { THandlebarsStringLiteral }

  THandlebarsStringLiteral = class(THandlebarsLiteral)
  private
    FValue: String;
    FOriginal: String;
    function GetAsString: String; override;
  public
    constructor Create(const AValue: String);
    property Value: String read FValue;
    property Original: String read FOriginal;
  end;

  { THandlebarsBooleanLiteral }

  THandlebarsBooleanLiteral = class(THandlebarsLiteral)
  private
    FValue: Boolean;
    FOriginal: Boolean;
    function GetAsString: String; override;
  public
    constructor Create(const AValue: String);
    property Original: Boolean read FOriginal;
    property Value: Boolean read FValue;
  end;

  { THandlebarsNumberLiteral }

  THandlebarsNumberLiteral = class(THandlebarsLiteral)
  private
    FValue: Double;
    FOriginal: Double;
    function GetAsString: String; override;
  public
    constructor Create(const ValueStr: String);
    property Original: Double read FOriginal;
    property Value: Double read FValue;
  end;

  { THandlebarsNullLiteral }

  THandlebarsNullLiteral = class(THandlebarsLiteral)
  private
    function GetAsString: String; override;
  end;

  { THandlebarsUndefinedLiteral }

  THandlebarsUndefinedLiteral = class(THandlebarsLiteral)
  private
    function GetAsString: String; override;
  end;

  THandlebarsStatement = class(THandlebarsNode)
  end;

  { THandlebarsMustacheStatement }

  THandlebarsMustacheStatement = class(THandlebarsStatement)
  private
    FPath: THandlebarsExpression; //PathExpression | Literal
    FParams: TFPObjectList;   //[Expression]
    FHash: THandlebarsHash;
    FStrip: TStripFlags;
    FScaped: Boolean;
    function GetParamCount: Integer;
    function GetParams(Index: Integer): THandlebarsExpression;
  public
    constructor Create;
    destructor Destroy; override;
    function GetText(Context: TDataContext): String; override;
    property Hash: THandlebarsHash read FHash;
    property Params[Index: Integer]: THandlebarsExpression read GetParams;
    property ParamCount: Integer read GetParamCount;
    property Path: THandlebarsExpression read FPath;
  end;

  { THandlebarsBlockStatement }

  THandlebarsBlockStatement = class(THandlebarsStatement)
  private
    FPath: THandlebarsExpression; //PathExpression | Literal
    FParams: TFPObjectList; //[ Expression ];
    FHash: THandlebarsHash;
    FProgram: THandlebarsProgram;
    FInverse: THandlebarsProgram;
    FOpenStrip: TStripFlags;
    FInverseStrip: TStripFlags;
    FCloseStrip: TStripFlags;
    function GetParamCount: Integer;
    function GetParams(Index: Integer): THandlebarsExpression;
  public
    constructor Create;
    destructor Destroy; override;
    property Hash: THandlebarsHash read FHash;
    property Inverse: THandlebarsProgram read FInverse;
    property Params[Index: Integer]: THandlebarsExpression read GetParams;
    property ParamCount: Integer read GetParamCount;
    property Path: THandlebarsExpression read FPath;
    property TheProgram: THandlebarsProgram read FProgram;
  end;

  { THandlebarsPartialStatement }

  THandlebarsPartialStatement = class(THandlebarsStatement)
  private
    FName: THandlebarsExpression; //PathExpression | SubExpression
    FParams: TFPObjectList; // [ Expression ]
    FHash: THandlebarsHash;
    FIndent: String;
    FStrip: TStripFlags;
    function GetParamCount: Integer;
    function GetParams(Index: Integer): THandlebarsExpression;
  public
    constructor Create;
    destructor Destroy; override;
    property Indent: String read FIndent;
    property Hash: THandlebarsHash read FHash;
    property Name: THandlebarsExpression read FName;
    property Params[Index: Integer]: THandlebarsExpression read GetParams;
    property ParamCount: Integer read GetParamCount;
  end;

  { THandlebarsPartialBlockStatement }

  THandlebarsPartialBlockStatement = class(THandlebarsStatement)
  private
    FName: THandlebarsExpression; //PathExpression | SubExpression
    FParams: TFPObjectList; // [ Expression ]
    FHash: THandlebarsHash;
    FProgram: THandlebarsProgram;
    FIndent: String;
    FOpenStrip: TStripFlags;
    FCloseStrip: TStripFlags;
    function GetParamCount: Integer;
    function GetParams(Index: Integer): THandlebarsExpression;
  public
    constructor Create;
    destructor Destroy; override;
    property Indent: String read FIndent;
    property Hash: THandlebarsHash read FHash;
    property Name: THandlebarsExpression read FName;
    property Params[Index: Integer]: THandlebarsExpression read GetParams;
    property ParamCount: Integer read GetParamCount;
    property TheProgram: THandlebarsProgram read FProgram;
  end;

  { THandlebarsContentStatement }

  THandlebarsContentStatement = class(THandlebarsStatement)
  private
    FValue: String;
    FOriginal: String;
  public
    function GetText({%h-}Context: TDataContext): String; override;
    constructor Create(const Value: String);
    property Value: String read FValue;
  end;

  { THandlebarsCommentStatement }

  THandlebarsCommentStatement = class(THandlebarsStatement)
  private
    FValue: String;
    FStrip: TStripFlags;
  public
    function GetText({%h-}Context: TDataContext): String; override;
    property Value: String read FValue;
  end;

  { THandlebarsDecorator }

  THandlebarsDecorator = class(THandlebarsMustacheStatement)
  private
  public
  end;

  { THandlebarsDecoratorBlock }

  THandlebarsDecoratorBlock = class(THandlebarsBlockStatement)
  private
  public
  end;

  { THandlebarsHashPair }

  THandlebarsHashPair = class(THandlebarsNode)
  private
    FKey: String;
    FValue: THandlebarsExpression;
  public
    constructor Create(const AKey: String; AValue: THandlebarsExpression);
    destructor Destroy; override;
    property Key: String read FKey;
    property Value: THandlebarsExpression read FValue;
  end;

  { THandlebarsHash }

  THandlebarsHash = class(THandlebarsNode)
  private
    FPairs: TFPObjectList; //[ HashPair ]
    function GetPairCount: Integer;
    function GetPairs(Index: Integer): THandlebarsHashPair;
  public
    constructor Create;
    destructor Destroy; override;
    function AddPair(Pair: THandlebarsHashPair): THandlebarsHashPair;
    property PairCount: Integer read GetPairCount;
    property Pairs[Index: Integer]: THandlebarsHashPair read GetPairs;
  end;

  { THandlebarsProgram }

  THandlebarsProgram = class(THandlebarsNode)
  private
    FBody: TFPObjectList; //[ Statement ]
    FBlockParams: TStringArray;
    function GetBody(Index: Integer): THandlebarsStatement;
    function GetBodyCount: Integer;
  public
    constructor Create;
    destructor Destroy; override;
    function GetText(Context: TDataContext): String; override;
    property BlockParams: TStringArray read FBlockParams;
    property Body[Index: Integer]: THandlebarsStatement read GetBody;
    property BodyCount: Integer read GetBodyCount;
  end;

  EHandlebarsParse = class(Exception);

  { THandlebarsParser }

  THandlebarsParser = class
  private
    FScanner: THandlebarsScanner;
    function ParseBlock(ExpectsClose: Boolean = True; Inverted: Boolean = False): THandlebarsBlockStatement;
    function ParseBlockParams: TStringArray;
    procedure ParseCloseBlock(const OpenName: String);
    function ParseComment: THandlebarsCommentStatement;
    function ParseExpression(AllowSubExpression: Boolean): THandlebarsExpression;
    function ParseMustache: THandlebarsMustacheStatement;
    procedure ParseParamsAndHash(Params: TFPObjectList; out Hash: THandlebarsHash);
    function ParsePartial: THandlebarsPartialStatement;
    function ParsePartialBlock: THandlebarsPartialBlockStatement;
    function ParsePath(IsData: Boolean): THandlebarsPathExpression;
    function ParseProgram(BreakTokens: THandlebarsTokens; DoFetchToken: Boolean = True): THandlebarsProgram;
    function ParseStatement: THandlebarsStatement;
    procedure UnexpectedToken(Expected: THandlebarsTokens);
  public
    constructor Create(Source : TStream); overload;
    constructor Create(const Source : String); overload;
    destructor Destroy; override;
    function Parse: THandlebarsProgram;
  end;

implementation

{ THandlebarsCommentStatement }

function THandlebarsCommentStatement.GetText({%h-}Context: TDataContext): String;
begin
  Result := '';
end;

{ THandlebarsUndefinedLiteral }

function THandlebarsUndefinedLiteral.GetAsString: String;
begin
  Result := 'undefined';
end;

{ THandlebarsNullLiteral }

function THandlebarsNullLiteral.GetAsString: String;
begin
  Result := 'null';
end;


{ THandlebarsHashPair }

constructor THandlebarsHashPair.Create(const AKey: String; AValue: THandlebarsExpression);
begin
  FKey := AKey;
  FValue := AValue;
end;

destructor THandlebarsHashPair.Destroy;
begin
  FValue.Free;
  inherited Destroy;
end;

{ THandlebarsBooleanLiteral }

function THandlebarsBooleanLiteral.GetAsString: String;
begin
  Result := LowerCase(BoolToStr(FValue, True));
end;

constructor THandlebarsBooleanLiteral.Create(const AValue: String);
begin
  FValue := AValue = 'true';
  FOriginal := FValue;
end;

{ THandlebarsStringLiteral }

function THandlebarsStringLiteral.GetAsString: String;
begin
  Result := FValue;
end;

constructor THandlebarsStringLiteral.Create(const AValue: String);
begin
  FValue := AValue;
  FOriginal := AValue;
end;

{ THandlebarsNumberLiteral }

function THandlebarsNumberLiteral.GetAsString: String;
begin
  Result := FloatToStr(FValue);
end;

constructor THandlebarsNumberLiteral.Create(const ValueStr: String);
begin
  FValue := StrToFloat(ValueStr);
  FOriginal := FValue;
end;

{ THandlebarsContentStatement }

function THandlebarsContentStatement.GetText({%h-}Context: TDataContext): String;
begin
  Result := FValue;
end;

constructor THandlebarsContentStatement.Create(const Value: String);
begin
  FValue := Value;
  FOriginal := Value;
end;

{ THandlebarsParser }

destructor THandlebarsParser.Destroy;
begin
  FScanner.Destroy;
end;

{
block
  : openBlock program inverseChain? closeBlock
  | openInverse program inverseAndProgram? closeBlock
  ;

openBlock
  : OPEN_BLOCK helperName param* hash? blockParams? CLOSE
  ;

openInverse
  : OPEN_INVERSE helperName param* hash? blockParams? CLOSE
  ;

openInverseChain
  : OPEN_INVERSE_CHAIN helperName param* hash? blockParams? CLOSE
  ;

inverseAndProgram
  : INVERSE program
  ;
}

function THandlebarsParser.ParseBlock(ExpectsClose: Boolean; Inverted: Boolean): THandlebarsBlockStatement;
var
  OpenName: String;
  BlockParams: TStringArray;
  TheProgram, InverseProgram: THandlebarsProgram;
  IsDecorator: Boolean;
begin
  IsDecorator := Pos('*', FScanner.CurTokenString) > 0;
  if IsDecorator then
    Result := THandlebarsDecoratorBlock.Create
  else
    Result := THandlebarsBlockStatement.Create;
  TheProgram := nil;
  InverseProgram := nil;
  BlockParams := nil;
  FScanner.FetchToken;
  Result.FPath := ParseExpression(False);
  if FScanner.CurToken = tkOpenBlockParams then
    BlockParams := ParseBlockParams;
  ParseParamsAndHash(Result.FParams, Result.FHash);
  if FScanner.CurToken = tkOpenBlockParams then
    BlockParams := ParseBlockParams;
  case Result.FPath.NodeType of
    'PathExpression':
      OpenName := THandlebarsPathExpression(Result.FPath).Original;
    'StringLiteral':
      OpenName := THandlebarsStringLiteral(Result.FPath).Original;
    'NumberLiteral':
      OpenName := FloatToStr(THandlebarsNumberLiteral(Result.FPath).Original);
    'BooleanLiteral':
      OpenName := LowerCase(BoolToStr(THandlebarsBooleanLiteral(Result.FPath).Original, True));
  end;
  TheProgram := ParseProgram([tkOpenEndBlock, tkInverse, tkOpenInverseChain]);
  TheProgram.FBlockParams := BlockParams;
  if FScanner.CurToken in [tkInverse, tkOpenInverseChain] then
  begin
    if IsDecorator then
      raise EHandlebarsParse.Create('Unexpected inverse');
    InverseProgram := ParseProgram([tkOpenEndBlock], FScanner.CurToken <> tkOpenInverseChain);
  end;

  if not Inverted then
  begin
    Result.FProgram := TheProgram;
    Result.FInverse := InverseProgram;
  end
  else
  begin
    Result.FInverse := TheProgram;
    Result.FProgram := InverseProgram;
  end;
  if ExpectsClose then
    ParseCloseBlock(OpenName);
end;

function THandlebarsParser.ParseBlockParams: TStringArray;
var
  ItemCount: Integer;
begin
  Result := nil;
  FScanner.FetchToken;
  while FScanner.CurToken = tkId do
  begin
    ItemCount := Length(Result);
    SetLength(Result, ItemCount + 1);
    Result[ItemCount] := FScanner.CurTokenString;
    FScanner.FetchToken;
  end;
  if FScanner.CurToken <> tkCloseBlockParams then
    UnexpectedToken([tkCloseBlockParams]);
  FScanner.FetchToken;
end;


{
closeBlock
  : OPEN_ENDBLOCK helperName CLOSE
  ;
}

procedure THandlebarsParser.ParseCloseBlock(const OpenName: String);
var
  Expression: THandlebarsExpression;
  CloseName: String;
begin
  FScanner.FetchToken;
  Expression := ParseExpression(True);
  case Expression.NodeType of
    'PathExpression':
      CloseName := THandlebarsPathExpression(Expression).Original;
    'StringLiteral':
      CloseName := THandlebarsStringLiteral(Expression).Original;
    'NumberLiteral':
      CloseName := FloatToStr(THandlebarsNumberLiteral(Expression).Original);
    'BooleanLiteral':
      CloseName := LowerCase(BoolToStr(THandlebarsBooleanLiteral(Expression).Original, True));
  else
    CloseName := '';
  end;
  Expression.Free;
  if CloseName <> OpenName then
    raise EHandlebarsParse.CreateFmt('%s doesn''t match %s', [OpenName, CloseName]);
  if FScanner.CurToken <> tkClose then
    UnexpectedToken([tkClose]);
end;

function THandlebarsParser.ParseComment: THandlebarsCommentStatement;
var
  Str: String;
begin
  Result := THandlebarsCommentStatement.Create;
  Str := FScanner.CurTokenString;
  if Pos('--', Str) = 4 then
    Str := Copy(Str, 6, Length(Str) - 9)
  else
    Str := Copy(Str, 4, Length(Str) - 5);
  Result.FValue := Str;
end;

function THandlebarsParser.ParseExpression(AllowSubExpression: Boolean): THandlebarsExpression;
var
  T: THandlebarsToken;
begin
  T := FScanner.CurToken;
  case T of
    tkNumber: Result := THandlebarsNumberLiteral.Create(FScanner.CurTokenString);
    tkString: Result := THandlebarsStringLiteral.Create(FScanner.CurTokenString);
    tkBoolean: Result := THandlebarsBooleanLiteral.Create(FScanner.CurTokenString);
    tkNull: Result := THandlebarsNullLiteral.Create;
    tkUndefined: Result := THandlebarsUndefinedLiteral.Create;
    tkId: Result := ParsePath(False);
    tkData:
      begin
        if FScanner.FetchToken = tkId then
          Result := ParsePath(True)
        else
          UnexpectedToken([tkId]);
      end;
    tkOpenSExpr:
      begin
        if not AllowSubExpression then
          UnexpectedToken([tkUndefined..tkString, tkId, tkData]);
      end
    else
      UnexpectedToken([tkUndefined..tkString, tkId, tkData, tkOpenSExpr]);
  end;
  if T in LiteralTokens then
    FScanner.FetchToken;
end;

{
mustache
  : OPEN helperName param* hash? CLOSE
  | OPEN_UNESCAPED helperName param* hash? CLOSE_UNESCAPED;

helperName
  : path
  | dataName
  | STRING
  | NUMBER
  | BOOLEAN
  | UNDEFINED
  | NULL
  ;
dataName
  : DATA pathSegments
  ;

path
  : pathSegments
  ;

pathSegments
  : pathSegments SEP ID
  | ID
  ;
}

function THandlebarsParser.ParseMustache: THandlebarsMustacheStatement;
var
  IsDecorator: Boolean;
begin
  IsDecorator := Pos('*', FScanner.CurTokenString) > 0;
  if IsDecorator then
    Result := THandlebarsDecorator.Create
  else
    Result := THandlebarsMustacheStatement.Create;
  FScanner.FetchToken;
  Result.FPath := ParseExpression(False);
  ParseParamsAndHash(Result.FParams, Result.FHash);
end;

procedure THandlebarsParser.ParseParamsAndHash(Params: TFPObjectList; out Hash: THandlebarsHash);
var
  PrevTokenString: String;
  Expression: THandlebarsExpression;
begin
  //params
  while FScanner.CurToken <> tkClose do
  begin
    PrevTokenString := FScanner.CurTokenString;
    Expression := ParseExpression(True);
    if FScanner.CurToken <> tkEquals then
      Params.Add(Expression)
    else
    begin
      //discard previous expression
      Expression.Destroy;
      Hash := THandlebarsHash.Create;
      FScanner.FetchToken;
      Expression := ParseExpression(True);
      Hash.AddPair(THandlebarsHashPair.Create(PrevTokenString, Expression));
      //hash
      while FScanner.CurToken = tkId do
      begin
        PrevTokenString := FScanner.CurTokenString;
        if FScanner.FetchToken = tkEquals then
        begin
          FScanner.FetchToken;
          Expression := ParseExpression(True);
          Hash.AddPair(THandlebarsHashPair.Create(PrevTokenString, Expression));
        end
        else
          UnexpectedToken([tkEquals]);
      end;
    end;
  end;
end;

{
partial
  : OPEN_PARTIAL partialName param* hash? CLOSE;

partialName
    : helperName -> $1
    | sexpr -> $1
    ;
}

function THandlebarsParser.ParsePartial: THandlebarsPartialStatement;
begin
  Result := THandlebarsPartialStatement.Create;
  FScanner.FetchToken;
  Result.FName := ParseExpression(True);
  ParseParamsAndHash(Result.FParams, Result.FHash);
end;

{
partialBlock
  : openPartialBlock program closeBlock -> yy.preparePartialBlock($1, $2, $3, @$)
  ;
openPartialBlock
  : OPEN_PARTIAL_BLOCK partialName param* hash? CLOSE -> { path: $2, params: $3, hash: $4, strip: yy.stripFlags($1, $5) }
  ;
}

function THandlebarsParser.ParsePartialBlock: THandlebarsPartialBlockStatement;
var
  OpenName: String;
begin
  Result := THandlebarsPartialBlockStatement.Create;
  FScanner.FetchToken;
  Result.FName := ParseExpression(True);
  ParseParamsAndHash(Result.FParams, Result.FHash);
  case Result.FName.NodeType of
    'PathExpression':
      OpenName := THandlebarsPathExpression(Result.FName).Original;
    'StringLiteral':
      OpenName := THandlebarsStringLiteral(Result.FName).Original;
    'NumberLiteral':
      OpenName := FloatToStr(THandlebarsNumberLiteral(Result.FName).Original);
    'BooleanLiteral':
      OpenName := LowerCase(BoolToStr(THandlebarsBooleanLiteral(Result.FName).Original, True));
  end;
  Result.FProgram := ParseProgram([tkOpenEndBlock]);
  ParseCloseBlock(OpenName);
end;

function THandlebarsParser.ParsePath(IsData: Boolean): THandlebarsPathExpression;
var
  PartCount: Integer;
  Part: String;
begin
  Result := THandlebarsPathExpression.Create;
  Result.FData := IsData;
  Result.FOriginal := '';
  repeat
    Part := FScanner.CurTokenString;
    case Part of
      'this', '.', '..':
        begin
          if Result.FOriginal <> '' then
            raise EHandlebarsParse.CreateFmt('Invalid path: %s%s', [Result.FOriginal, Part]);
          if Part = '..' then
            Inc(Result.FDepth);
        end;
      else
      begin
        PartCount := Length(Result.Parts);
        SetLength(Result.FParts, PartCount + 1);
        Result.FParts[PartCount] := Part;
      end;
    end;
    Result.FOriginal += Part;
    if FScanner.FetchToken = tkSep then
    begin
      Result.FOriginal += FScanner.CurTokenString;
      if FScanner.FetchToken <> tkId then
        UnexpectedToken([tkId]);
    end
    else
      Break;
  until False;
end;

function THandlebarsParser.ParseProgram(BreakTokens: THandlebarsTokens; DoFetchToken: Boolean): THandlebarsProgram;
var
  T: THandlebarsToken;
begin
  Result := THandlebarsProgram.Create;
  if DoFetchToken then
    T := FScanner.FetchToken
  else
    T := FScanner.CurToken;
  while not (T in BreakTokens) do
  begin
    Result.FBody.Add(ParseStatement);
    //todo: make ParseStatement consistent, always let at next token or current token
    if T = tkOpenInverseChain then
      T := FScanner.CurToken
    else
      T := FScanner.FetchToken;
  end;
end;

function THandlebarsParser.ParseStatement: THandlebarsStatement;
begin
  case FScanner.CurToken of
    tkContent:
      Result := THandlebarsContentStatement.Create(FScanner.CurTokenString);
    tkOpen, tkOpenUnescaped:
      Result := ParseMustache;
    tkOpenPartial:
      Result := ParsePartial;
    tkOpenPartialBlock:
      Result := ParsePartialBlock;
    tkComment:
      Result := ParseComment;
    tkOpenBlock:
      Result := ParseBlock;
    tkOpenInverseChain:
      Result := ParseBlock(False);
    tkOpenInverse:
      Result := ParseBlock(True, True);
  else
    UnexpectedToken([tkContent, tkOpen, tkOpenUnescaped, tkOpenPartial, tkOpenPartialBlock,
      tkComment, tkOpenInverse, tkOpenInverseChain]);
  end;
end;

function TokenSetToStr(Tokens: THandlebarsTokens): String;
var
  Token: THandlebarsToken;
  TokenStr: String;
begin
  Result := '[';
  for Token in Tokens do
  begin
    WriteStr(TokenStr, Token);
    Result := Result + TokenStr;
    Result := Result + ',';
  end;
  Result := Result + ']';
end;


procedure THandlebarsParser.UnexpectedToken(Expected: THandlebarsTokens);
var
  ActualStr, ExpectedStr: String;
begin
  WriteStr(ActualStr, FScanner.CurToken);
  ExpectedStr := TokenSetToStr(Expected);
  raise EHandlebarsParse.CreateFmt('Got %s expected %s', [ActualStr, ExpectedStr]);
end;

constructor THandlebarsParser.Create(Source: TStream);
begin
  FScanner := THandlebarsScanner.Create(Source);
end;

constructor THandlebarsParser.Create(const Source: String);
begin
  FScanner := THandlebarsScanner.Create(Source);
end;


function THandlebarsParser.Parse: THandlebarsProgram;
begin
  Result := ParseProgram([tkEOF]);
end;

{ THandlebarsHash }

function THandlebarsHash.GetPairCount: Integer;
begin
  Result := FPairs.Count;
end;

function THandlebarsHash.GetPairs(Index: Integer): THandlebarsHashPair;
begin
  Result := THandlebarsHashPair(FPairs[Index]);
end;

constructor THandlebarsHash.Create;
begin
  FPairs := TFPObjectList.Create;
end;

destructor THandlebarsHash.Destroy;
begin
  FPairs.Destroy;
  inherited Destroy;
end;

function THandlebarsHash.AddPair(Pair: THandlebarsHashPair): THandlebarsHashPair;
begin
  Result := Pair;
  FPairs.Add(Pair);
end;

{ THandlebarsPartialBlockStatement }

function THandlebarsPartialBlockStatement.GetParamCount: Integer;
begin
  Result  := FParams.Count;
end;

function THandlebarsPartialBlockStatement.GetParams(Index: Integer): THandlebarsExpression;
begin
  Result := THandlebarsExpression(FParams[Index]);
end;

constructor THandlebarsPartialBlockStatement.Create;
begin
  FParams := TFPObjectList.Create;
end;

destructor THandlebarsPartialBlockStatement.Destroy;
begin
  FName.Free;
  FHash.Free;
  FParams.Destroy;
  inherited Destroy;
end;

{ THandlebarsPartialStatement }

function THandlebarsPartialStatement.GetParamCount: Integer;
begin
  Result := FParams.Count;
end;

function THandlebarsPartialStatement.GetParams(Index: Integer): THandlebarsExpression;
begin
  Result := THandlebarsExpression(FParams[Index]);
end;

constructor THandlebarsPartialStatement.Create;
begin
  //todo: create on demand
  FParams := TFPObjectList.Create;
end;

destructor THandlebarsPartialStatement.Destroy;
begin
  FName.Free;
  FHash.Free;
  FParams.Free;
  inherited Destroy;
end;

{ THandlebarsBlockStatement }

function THandlebarsBlockStatement.GetParamCount: Integer;
begin
  Result := FParams.Count;
end;

function THandlebarsBlockStatement.GetParams(Index: Integer): THandlebarsExpression;
begin
  Result := THandlebarsExpression(FParams[Index]);
end;

constructor THandlebarsBlockStatement.Create;
begin
  FParams := TFPObjectList.Create;
end;

destructor THandlebarsBlockStatement.Destroy;
begin
  FPath.Free;
  FHash.Free;
  FProgram.Free;
  FInverse.Free;
  FParams.Free;
  inherited Destroy;
end;

{ THandlebarsMustacheStatement }

function THandlebarsMustacheStatement.GetParamCount: Integer;
begin
  Result := FParams.Count;
end;

function THandlebarsMustacheStatement.GetParams(Index: Integer): THandlebarsExpression;
begin
  Result := THandlebarsExpression(FParams[Index]);
end;

constructor THandlebarsMustacheStatement.Create;
begin
  FParams := TFPObjectList.Create;
end;

destructor THandlebarsMustacheStatement.Destroy;
begin
  FPath.Free;
  FHash.Free;
  FParams.Free;
  inherited Destroy;
end;

function THandlebarsMustacheStatement.GetText(Context: TDataContext): String;
begin
  if FPath is THandlebarsLiteral then
    Result := Context.ResolvePath([THandlebarsLiteral(FPath).AsString])
  else
    Result := Context.ResolvePath(THandlebarsPathExpression(FPath).FParts);
end;

{ THandlebarsNode }

function THandlebarsNode.GetNodeType: String;
const
  PrefixOffset = 12; //THandlebars
var
  TheClassName: String;
begin
  TheClassName := ClassName;
  Result := Copy(TheClassName, PrefixOffset, Length(TheClassName));
end;

{ THandlebarsSubExpression }

function THandlebarsSubExpression.GetParamCount: Integer;
begin
  Result := FParams.Count;
end;

function THandlebarsSubExpression.GetParams(Index: Integer): THandlebarsExpression;
begin
  Result := THandlebarsExpression(FParams[Index]);
end;

destructor THandlebarsSubExpression.Destroy;
begin
  FPath.Free;
  FHash.Free;
  inherited Destroy;
end;

{ THandlebarsProgram }

function THandlebarsProgram.GetBody(Index: Integer): THandlebarsStatement;
begin
  Result := THandlebarsStatement(FBody[Index]);
end;

function THandlebarsProgram.GetBodyCount: Integer;
begin
  Result := FBody.Count;
end;

constructor THandlebarsProgram.Create;
begin
  FBody := TFPObjectList.Create;
end;

destructor THandlebarsProgram.Destroy;
begin
  FBody.Destroy;
  inherited Destroy;
end;

function THandlebarsProgram.GetText(Context: TDataContext): String;
var
  i: Integer;
begin
  Result := '';
  for i := 0 to BodyCount - 1 do
    Result += Body[i].GetText(Context);
end;

end.

