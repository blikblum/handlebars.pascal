unit HandlebarsScanner;

{$mode objfpc}{$H+}

interface

uses
  Classes;

type

  THandlebarsToken = (
    tkEOF,
    tkContent,
    tkOpenPartial,
    tkOpenPartialBlock,
    tkOpenBlock,
    tkOpenEndBlock,
    tkEndBlock,
    tkOpenRawBlock,
    tkCloseRawBlock,
    tkEndRawBlock,
    tkOpenBlockParams,
    tkCloseBlockParams,
    tkOpenSExpr,
    tkCloseSExpr,
    tkInverse,
    tkOpenInverse,
    tkOpenInverseChain,
    tkOpenUnescaped,
    tkCloseUnescaped,
    tkOpen,
    tkClose,
    tkComment,
    tkEquals,
    tkId,
    tkSep,
    tkData,
    tkUndefined,
    tkNull,
    tkBoolean,
    tkNumber,
    tkString,
    tkInvalid
  );

  THandlebarsTokens = set of THandlebarsToken;

  //inspired by fpc jsonscanner

  { THandlebarsScanner }

  THandlebarsScanner = class
  private
     FSource : TStringList;
     FCurToken: THandlebarsToken;
     FCurTokenString: string;
     FCurLine: string;
     TokenStr: PChar;
     FCurRow: Integer;
     FMustacheLevel: Integer;
     function FetchLine: Boolean;
     function GetCurColumn: Integer;
     procedure ScanComment;
     procedure ScanContent(TokenOffset: Integer = 0);
   protected
     procedure Error(const Msg: string);overload;
     procedure Error(const Msg: string; const Args: array of Const);overload;
   public
     constructor Create(Source : TStream); overload;
     constructor Create(const Source : String); overload;
     destructor Destroy; override;
     function FetchToken: THandlebarsToken;

     property CurLine: string read FCurLine;
     property CurRow: Integer read FCurRow;
     property CurColumn: Integer read GetCurColumn;

     property CurToken: THandlebarsToken read FCurToken;
     property CurTokenString: string read FCurTokenString;
   end;

const
  LiteralTokens = [tkUndefined..tkString];

implementation

uses
  strings;

{ THandlebarsScanner }

function THandlebarsScanner.FetchLine: Boolean;
begin
  Result := FCurRow < FSource.Count;
  if Result then
  begin
    FCurLine := FSource[FCurRow];
    TokenStr := PChar(FCurLine);
    Inc(FCurRow);
  end
  else
  begin
    FCurLine := '';
    TokenStr := nil;
  end;
end;

function THandlebarsScanner.GetCurColumn: Integer;
begin
  Result := TokenStr - PChar(CurLine);
end;

procedure THandlebarsScanner.ScanComment;
var
  TokenStart: PChar;
  SectionLength, StrOffset: Integer;
  IsDoubleDash, EndOfComment: Boolean;
begin
  //todo: handlebars.js returns the token content with the mustaches and later removes them at parsing.
  //seems a limitation of tokenizer. We don't have this issue and the code could be cleaned a bit
  TokenStart := TokenStr;
  IsDoubleDash := (TokenStr[3] = '-') and (TokenStr[4] = '-');
  StrOffset := 0;
  while True do
  begin
    Inc(TokenStr);
    if TokenStr[0] = #0 then
    begin
      SectionLength := TokenStr - TokenStart;
      SetLength(FCurTokenString, StrOffset + SectionLength + Length(LineEnding));
      Move(TokenStart^, FCurTokenString[StrOffset + 1], SectionLength);
      Move(LineEnding[1], FCurTokenString[StrOffset + SectionLength + 1], Length(LineEnding));
      if not FetchLine then
      begin
        //todo: mark as invalid
        Break;
      end;
      TokenStart := TokenStr;
      Inc(StrOffset, SectionLength + Length(LineEnding));
    end;
    if IsDoubleDash then
      EndOfComment := (TokenStr[0] = '-') and (TokenStr[1] = '-') and (TokenStr[2] = '}') and (TokenStr[3] = '}')
    else
      EndOfComment := (TokenStr[0] = '}') and (TokenStr[1] = '}');
    if EndOfComment then
    begin
      if IsDoubleDash then
        Inc(TokenStr, 4)
      else
        Inc(TokenStr, 2);
      SectionLength := TokenStr - TokenStart;
      SetLength(FCurTokenString, StrOffset + SectionLength);
      Move(TokenStart^, FCurTokenString[StrOffset + 1], SectionLength);
      Break;
    end;
  end;
end;

procedure THandlebarsScanner.ScanContent(TokenOffset: Integer);
var
  TokenStart: PChar;
  SectionLength, StrOffset: Integer;
begin
  TokenStart := TokenStr;
  StrOffset := 0;
  Inc(TokenStr, TokenOffset);
  while True do
  begin
    if TokenStr[0] = #0 then
    begin
      SectionLength := TokenStr - TokenStart;
      if FetchLine then
      begin
        SetLength(FCurTokenString, StrOffset + SectionLength + Length(LineEnding));
        Move(TokenStart^, FCurTokenString[StrOffset + 1], SectionLength);
        Move(LineEnding[1], FCurTokenString[StrOffset + SectionLength + 1], Length(LineEnding));
      end
      else
      begin
        SetLength(FCurTokenString, StrOffset + SectionLength);
        Move(TokenStart^, FCurTokenString[StrOffset + 1], SectionLength);
        Break;
      end;
      TokenStart := TokenStr;
      Inc(StrOffset, SectionLength + Length(LineEnding));
      continue;
    end;
    if ((TokenStr[0] = '{') and (TokenStr[1] = '{')) or
      (((TokenStr[0] = '\') and not (TokenStr[-1] = '\')) and (TokenStr[1] = '{') and (TokenStr[2] = '{')) then
    begin
      SectionLength := TokenStr - TokenStart;
      //escaped escape
      if (TokenStr[0] = '{') and (TokenStr[-1] = '\') then
        Dec(SectionLength);
      SetLength(FCurTokenString, StrOffset + SectionLength);
      Move(TokenStart^, FCurTokenString[StrOffset + 1], SectionLength);
      Break;
    end;
    Inc(TokenStr);
  end;
end;

procedure THandlebarsScanner.Error(const Msg: string);
begin

end;

procedure THandlebarsScanner.Error(const Msg: string; const Args: array of const);
begin

end;

constructor THandlebarsScanner.Create(Source: TStream);
begin
  FSource := TStringList.Create;
  FSource.LoadFromStream(Source);
end;

constructor THandlebarsScanner.Create(const Source: String);
var
  L: Integer;
begin
  FSource := TStringList.Create;
  FSource.Text := Source;
  //TStringList eats a lineending at string tail
  //add a workaround until develop a proper solution
  L := Length(Source);
  if (L >= Length(LineEnding)) and (CompareByte(Source[L - Length(LineEnding) + 1], LineEnding[1], Length(LineEnding)) = 0) then
    FSource.Add('');
end;

destructor THandlebarsScanner.Destroy;
begin
  FSource.Destroy;
  inherited Destroy;
end;

function GetNextToken(Start: PChar): PChar;
begin
  Result := Start;
  while Result[0] = ' ' do
    Inc(Result);
end;

function GetNextChar(Start: PChar; out Next: PChar; const C: Char): Boolean;
begin
  Next := Start;
  while Next[0] = ' ' do
    Inc(Next);
  Result := Next[0] = C;
end;

function GetNextStr(Start: PChar; out Next: PChar; const Str: PChar; Size: SizeInt): Boolean;
begin
  Next := Start;
  while Next[0] = ' ' do
    Inc(Next);
  Result := strlcomp(Next, Str, Size) = 0;
end;

function THandlebarsScanner.FetchToken: THandlebarsToken;
var
  TokenStart, NextToken: PChar;
  SectionLength, StrOffset: Integer;
  C, Escaped: Char;
begin
  FCurTokenString := '';
  if (TokenStr = nil) and not FetchLine then
  begin
    Result := tkEOF;
    FCurToken := tkEOF;
    Exit;
  end;

  Result := tkInvalid;

  case TokenStr[0] of
    '{':
      begin
        //{{
        TokenStart := TokenStr;
        if TokenStr[1] = '{' then
        begin
          Result := tkOpen;
          Inc(TokenStr, 2);
          case TokenStr[0] of
            '>': Result := tkOpenPartial;
            '#':
              begin
                Result := tkOpenBlock;
                case TokenStr[1] of
                  '>':
                    begin
                      Result := tkOpenPartialBlock;
                      Inc(TokenStr);
                    end;
                   '*': Inc(TokenStr); // directive
                end;
              end;
            '/': Result := tkOpenEndBlock;
            '&', '*': Inc(TokenStr);
            '{': Result := tkOpenUnescaped;
            '^':
              begin
                NextToken := GetNextToken(TokenStr + 1);
                if (NextToken[0] = '}') and (NextToken[1] = '}') then
                begin
                  Result := tkInverse;
                  TokenStr := NextToken + 2;
                end
                else
                  Result := tkOpenInverse;
              end;
            '!':
              begin
                Result := tkComment;
                Dec(TokenStr, 2);
                ScanComment;
              end;
          else
            if GetNextStr(TokenStr, NextToken, 'else', 4) then
            begin
              NextToken := GetNextToken(NextToken + 4);
              if (NextToken[0] = '}') and (NextToken[1] = '}') then
              begin
                Result := tkInverse;
                TokenStr := NextToken + 2;
              end
              else
              begin
                Result := tkOpenInverseChain;
                TokenStr := NextToken;
              end;
            end;
          end;
          if not (Result in [tkInverse, tkComment]) then
          begin
            if not (Result in [tkOpen, tkOpenInverseChain]) then
              Inc(TokenStr);
            Inc(FMustacheLevel);
          end;
          if Result <> tkComment then
          begin
            SectionLength := TokenStr - TokenStart;
            SetLength(FCurTokenString, SectionLength);
            Move(TokenStart^, FCurTokenString[1], SectionLength);
          end;
        end
        else
        begin
          Result := tkContent;
          ScanContent;
        end;
      end;
    '}':
      begin
        TokenStart := TokenStr;
        if (TokenStr[1] = '}') and (FMustacheLevel > 0) then
        begin
          if TokenStr[2] = '}' then
          begin
            Result := tkCloseUnescaped;
            Inc(TokenStr, 3);
          end
          else
          begin
            Result := tkClose;
            Inc(TokenStr, 2);
          end;
          SectionLength := TokenStr - TokenStart;
          SetLength(FCurTokenString, SectionLength);
          Move(TokenStart^, FCurTokenString[1], SectionLength);
          Dec(FMustacheLevel);
        end
        else
        begin
          Result := tkContent;
          ScanContent;
        end;
      end;
  else
    if FMustacheLevel = 0 then
    begin
      Result := tkContent;
      if (TokenStr[0] = #0) then
      begin
         if FCurRow >= FSource.Count then
          Result := tkEOF
        else
          ScanContent;
      end else if strlcomp(TokenStr, '\{{', 3) = 0 then
      begin
        Inc(TokenStr);
        ScanContent(2);
      end
      else
        ScanContent;
    end
    else
    begin
      while TokenStr[0] = ' ' do
        Inc(TokenStr);
      StrOffset := 0;
      TokenStart := TokenStr;
      case TokenStr[0] of
        '/':
          begin
            Result := tkSep;
            Inc(TokenStr);
          end;
        '.':
          begin
            Result := tkSep;
            if TokenStr[1] = '.' then
            begin
              Result := tkId;
              Inc(TokenStr);
            end else if FCurToken <> tkId then
              Result := tkId;
            Inc(TokenStr);
          end;
        '"', '''':
          begin
            Result := tkString;
            C := TokenStr[0];
            Inc(TokenStr);
            TokenStart := TokenStr;
            while not (TokenStr[0] in [#0, C]) do
            begin
              if (TokenStr[0] = '\') then
              begin
                // Save length
                SectionLength := TokenStr - TokenStart;
                Inc(TokenStr);
                // Read escaped token
                case TokenStr[0] of
                  '"' : Escaped:='"';
                  '''': Escaped:='''';
                  't' : Escaped:=#9;
                  'b' : Escaped:=#8;
                  'n' : Escaped:=#10;
                  'r' : Escaped:=#13;
                  'f' : Escaped:=#12;
                  '\' : Escaped:='\';
                  '/' : Escaped:='/';
                  #0  : Error('SErrOpenString');
                else
                  Error('SErrInvalidCharacter', [CurRow,CurColumn,TokenStr[0]]);
                end;
                SetLength(FCurTokenString, StrOffset + SectionLength + 2);
                if SectionLength > 0 then
                  Move(TokenStart^, FCurTokenString[StrOffset + 1], SectionLength);
                FCurTokenString[StrOffset + SectionLength + 1] := Escaped;
                Inc(StrOffset, SectionLength + 1);
                // Next char
                // Inc(TokenStr);
                TokenStart := TokenStr + 1;
              end;
              if TokenStr[0] = #0 then
                Error('SErrOpenString');
              Inc(TokenStr);
            end;
            if TokenStr[0] = #0 then
              Error('SErrOpenString');
          end;
        '0'..'9','-':
          begin
            Result := tkNumber;
            TokenStart := TokenStr;
            while True do
            begin
              Inc(TokenStr);
              case TokenStr[0] of
                '.':
                  begin
                    if TokenStr[1] in ['0'..'9', 'e', 'E'] then
                    begin
                      Inc(TokenStr);
                      repeat
                        Inc(TokenStr);
                      until not (TokenStr[0] in ['0'..'9', 'e', 'E','-','+']);
                    end;
                    break;
                  end;
                '0'..'9': ;
                'e', 'E':
                  begin
                    Inc(TokenStr);
                    if TokenStr[0] in ['-','+']  then
                      Inc(TokenStr);
                    while TokenStr[0] in ['0'..'9'] do
                      Inc(TokenStr);
                    break;
                  end;
                else
                  break;
              end;
            end;
            SectionLength := TokenStr - TokenStart;
            SetLength(FCurTokenString, SectionLength);
            if SectionLength > 0 then
              Move(TokenStart^, FCurTokenString[1], SectionLength);
          end;
        '=':
          begin
            Result := tkEquals;
            Inc(TokenStr);
          end;
        '@':
          begin
            Result := tkData;
            Inc(TokenStr);
          end;
        '(':
          begin
            Result := tkOpenSExpr;
            Inc(TokenStr);
          end;
        ')':
          begin
            Result := tkCloseSExpr;
            Inc(TokenStr);
          end;
        '|':
          begin
            Result := tkCloseBlockParams;
            Inc(TokenStr);
          end;
        '&':
          begin
            //todo: see what are the other invalid chars
            //Result := tkInvalid;
            Inc(TokenStr);
          end;
      else
        if (strlcomp(TokenStr, 'true', 4) = 0) or (strlcomp(TokenStr, 'false', 5) = 0) then
          Result := tkBoolean
        else if strlcomp(TokenStr, 'null', 4) = 0 then
          Result := tkNull
        else if strlcomp(TokenStr, 'undefined', 9) = 0 then
          Result := tkUndefined
        else if (strlcomp(TokenStr, 'as', 2) = 0) and GetNextChar(TokenStr + 2, NextToken, '|') then
        begin
          Result := tkOpenBlockParams;
          TokenStr := NextToken;
        end
        else
          Result := tkId;

        while True do
        begin
          if ((TokenStr[0] = '}') and (TokenStr[1] = '}')) or (TokenStr[0] in [' ', '.', '/'])
            or (TokenStr[0] = '=') or (TokenStr[0] = ')') or (TokenStr[0] = '|')
            or (TokenStr[0] = #0) then
            break;
          Inc(TokenStr);
        end;
      end;
      if TokenStr <> nil then
      begin
        SectionLength := TokenStr - TokenStart;
        SetLength(FCurTokenString, SectionLength + StrOffset);
        if SectionLength > 0 then
          Move(TokenStart^, FCurTokenString[StrOffset + 1], SectionLength);
        if Result in [tkString, tkOpenBlockParams] then
          Inc(TokenStr);
        //rigth trim space and line break
        while TokenStr[0] = ' ' do
          Inc(TokenStr);
        while TokenStr[0] = #0 do
        begin
          if not FetchLine then
            Break;
        end;
      end;
    end;
  end;

  FCurToken := Result;
end;

end.

