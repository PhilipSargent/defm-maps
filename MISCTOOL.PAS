(****************************************************************)
(*                     DATABASE TOOLBOX 4.0                     *)
(*     Copyright (c) 1984, 87 by Borland International, Inc.    *)
(*                                                              *)
(*                      MiscTool(s)                             *)
(*                                                              *)
(*  A small collection of utility procedures used by various    *)
(*  Turbo Database Toolbox programs.                            *)
(*                                                              *)
(****************************************************************)
unit MiscTool;
interface
uses CRT;

procedure Abort(M : String);
{ Simple fatal error reporter: Goes to the bottom of the screen,
  Prints M and terminates execution of the program. }

procedure Beep;
{ Generates a sound from the speaker to alert the user.  Useful
  for error handling routines. }

function ConstStr(C : Char; N : byte) : String;
{  ConstStr returns a string with N characters of value C }

function Exist(FN : String) : boolean;
{ Returns true if file named by FN exists }

function NumStr(Num : integer) : String;
{ Converts an integer to a string.  Function form is often more
  convenient than the Str procedure }

function UpcaseStr(S : String) : String;
{ Converts all characters in the string S to their upper case
  equivalents. }

implementation
{$V-}

procedure Beep;
{ Generates a sound from the speaker to alert the user.  Useful
  for error handling routines. }
begin
  Sound(220);
  Delay(200);
  NoSound;
end; { Beep }

function Exist(FN : String) : boolean;
{ Returns true if file named by FN exists }
var
  F : file;
  found : boolean;
begin
  Assign(f, FN);
  {$I-}
  Reset(f);
  Found := (IOResult = 0);
  if Found then
    Close(f);
  {$I+}
  Exist := Found;
end; { Exist }

procedure Abort(M : String);
{ Simple fatal error reporter: Goes to the bottom of the screen,
  Prints M and terminates execution of the program. }

begin
  Window(1, 1, 80, 25);
  TextColor(White);
  TextBackground(Black);
  LowVideo;
  GotoXY(1, 25);
  Write(M);
  ClrEol;
  Halt;
end; { Abort }

function NumStr(Num : integer) : String;
{ Converts an integer to a string.  Function form is often more
  convenient than the Str procedure }
var
  S : string;

begin
  Str(Num:1, S);
  NumStr := S;
end;

function ConstStr(C : Char; N : byte) : String;
{  ConstStr returns a string with N characters of value C }

var
  S : string;
begin
  if N < 0 then
    N := 0;
  S[0] := Chr(N);
  FillChar(S[1],N,C);
  ConstStr := S;
end; { ConstStr }

function UpcaseStr(S : String) : String;
{ Converts all characters in the string S to their upper case
  equivalents. }
var
  P : byte;
begin
  for P := 1 to Length(S) do
    S[P] := Upcase(S[P]);
  UpcaseStr := S;
end;

end.