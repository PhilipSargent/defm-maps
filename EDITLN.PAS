(****************************************************************)
(*                     DATABASE TOOLBOX 4.0                     *)
(*     Copyright (c) 1984, 87 by Borland International, Inc.    *)
(*                                                              *)
(*                          EditLn                              *)
(*                                                              *)
(*       General Purpose line editor.  Used in the BTree        *)
(*       sample program as well as in other Turbo Database      *)
(*       Toolbox programs.                                      *)
(*                                                              *)
(****************************************************************)
unit EditLn;
interface
uses CRT,
     MiscTool;
{ If a compiler error occurs here, you need to unpack the source
  to the MiscTool unit from the archived file Tools.arc.  See the
  README file on disk 1 for detailed instructions. }


const
  NULL = #0;
  BS = #8;
  LF = #10;
  CR = #13;
  ESC = #27;
  Space = #32;
  Tab = ^I;

  { The following constants are based on the scheme used by the scan key
    function to convert a two key scan code sequence into one character
    by adding 128 to the ordinal value of the second character.
  }
  F1 = #187;
  F2 = #188;
  F3 = #189;
  F4 = #190;
  F5 = #191;
  F6 = #192;
  F7 = #193;
  F8 = #194;
  F9 = #195;
  F10 = #196;
  UpKey = #200;
  DownKey = #208;
  LeftKey = #203;
  RightKey = #205;
  PgUpKey = #201;
  PgDnKey = #209;
  HomeKey = #199;
  EndKey = #207;
  InsKey = #210;
  DelKey = #211;

type
  CharSet = set of char;

procedure EditLine(var S     : String;
                       Len, X, Y : byte;
                       LegalChars,
                       Term  : CharSet;
                   var TC    : Char    );
{  EditLn implements a line editor that supports WordStar commands
   as well as left-right arrow keys , Home, End, back space, etc.
   Paramaters:
     S : String to be edited
     Len : Maximum characters allowed to be edited
     X, Y : Starting x an y cordinates
     LegalChars : Set of characters that will be accepted
     Term : Set of characters that will cause EditLine to Exit
            (Note LegalChars need not contain Term)
     TC : Character that caused EditLn to exit
}

function ScanKey : char;
{ Reads a key from the keyboard and converts 2 scan code escape
  sequences into 1 character. }

implementation
{$V-}

function ScanKey : char;
{ Reads a key from the keyboard and converts 2 scan code escape
  sequences into 1 character. }

var
  Ch : Char;
begin
  Ch := ReadKey;
  if (Ch = #0) and KeyPressed then
  begin
    Ch := ReadKey;
    if ord(Ch) < 128 then
      Ch := Chr(Ord(Ch) + 128);
  end;
  if Ch = ^C then
    Abort('Program terminated by user');
  ScanKey := Ch;
end; { ScanKey }

procedure EditLine(var S : String;
                   Len, X, Y : byte;
                   LegalChars, Term  : CharSet;
                   var TC    : Char);
{  EditLn implements a line editor that supports WordStar commands
   as well as left-right arrow keys , Home, End, back space, etc.
   Paramaters:
     S : String to be edited
     Len : Maximum characters allowed to be edited
     X, Y : Starting x an y cordinates
     LegalChars : Set of characters that will be accepted
     Term : Set of characters that will cause EditLine to Exit
            (Note LegalChars need not contain Term)
     TC : Character that caused EditLn to exit
}

var
  P : byte;
  Ch : Char;
  first : boolean;

begin
  first := true;
  GotoXY(X,Y); Write(S);
  P := 0;
  repeat
    GotoXY(X + P,Y);
    Ch := ScanKey;
    if not (Upcase(Ch) in Term) then
      case Ch of
        #32..#126 : if (P < Len) and
                       (ch in LegalChars) then
                    begin
                      if First then
                      begin
                        Write(' ':Len);
                        Delete(S,P + 1,Len);
                        GotoXY(X + P,Y);
                      end;
                      if Length(S) = Len then
                        Delete(S,Len,1);
                      P := succ(P);
                      Insert(Ch,S,P);
                      Write(Copy(S,P,Len));
                    end
                    else Beep;
        ^S, LeftKey : if P > 0 then
                        P := pred(P);
        ^D, RightKey : if P < Length(S) then
                         P := succ(P);
         ^A, HomeKey : P := 0;
         ^F, EndKey : P := Length(S);
         ^G, DelKey  : if P < Length(S) then
                       begin
                         Delete(S,P + 1,1);
                         Write(Copy(S,P + 1,Len),' ');
                       end;
                 BS : if P > 0 then
                 begin
                   Delete(S,P,1);
                   Write(^H,Copy(S,P,Len),' ');
                   P := pred(P);
                 end;
        ^Y : begin
               Write(' ':Len);
               Delete(S,P + 1,Len);
             end;
      else;
    end;  {of case}
    First := false;
  until UpCase(Ch) in Term;
  P := Length(S);
  GotoXY(X + P,Y);
  Write('' :Len - P);
  TC := Upcase(Ch);
end; { EditLine }

end.