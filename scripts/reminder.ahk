/*
Reminder.AHK
Simple Alarm/Reminder [CLD rev.6/1/2015-a]

AutoHotkey version 1.1.22.00

Usage:
ALARM.AHK [h]h[:]mm[A[M]|P[M]] [Reminder]
(If arg is omitted, it is solicited via Input box)
--------------------------------------------------
*/
;
; Optional sound file to play at alarm time:
; SoundFile = "C:\Users\Public\Music\Sample Music\Maid with the Flaxen Hair.mp3"
;
;
#SingleInstance, off
#NoEnv
#Persistent
SendMode Input
SetBatchLines -1
SetWorkingDir %A_ScriptDir%

; Function: Format [h]mm as 0hmm
FourDigits(T)
{
  If T is not number
  {
    T =
    Return T
  }
  If (StrLen(T) >= 0 and StrLen(T) < 3)
    T = %T%00
  While StrLen(T) < 4
    T = 0%T%
  Return T
}

AllArgs =
If 0 > 0 ; You gotta be kidding, AutoHotkey! ;)
  AllArgs = %1% %2% %3% %4% %5% %6% %7% %8% %9%
Else
{
  FormatTime, now
  InputBox, AllArgs, Reminder,
(
It's now %now%
Enter the alarm time ([h]h:mm[AM|PM]) and optional Reminder to display.
eg: 11:30pm Time for bed!
),, 600, 180
}

If StrLen(AllArgs) < 1
    ExitApp

AlarmT =
AmPm =
Remindr = %AllArgs%
Loop, Parse, AllArgs, %A_Space%
{
  If A_Index = 1
  {
    AlarmT = %A_LoopField%
    StringRight, Remindr, Remindr, StrLen(Remindr)-StrLen(A_LoopField)-1
    Continue
  }
  If A_Index = 2
  {
    StringUpper, tmp, A_LoopField
    If tmp in A,a,AM,am,Am,aM,P,p,PM,pm,Pm,pM
    {
      StringUpper, AmPm, A_LoopField
      StringRight, Remindr, Remindr, StrLen(Remindr)-StrLen(A_LoopField)-1
    }
    Continue
  }
  Else
    Break
}

StringReplace, AlarmT, AlarmT, :
StringUpper, AlarmT, AlarmT
If (AlarmT contains A or AlarmT contains P)
{
  If AlarmT contains A
    AmPm = A
  If AlarmT contains P
    AmPm = P
  Atmp = %AlarmT%
  AlarmT =
  Loop, Parse, Atmp
  {
    If A_LoopField is number
      AlarmT = %AlarmT%%A_LoopField%
    Else
      Break
  }
}

; "Guess" AM/PM if missing
If (StrLen(AmPm) < 1 and AlarmT < 1300 and StrLen(AlarmT) < 4)
{
FormatTime,h, ,HH
If Floor(AlarmT/100) < h
  AmPm = PM
Else
  AmPm = AM
}

If StrLen(AmPm) > 0
{
  If StrLen(AmPm) < 2
    AmPm = %AmPm%M
  Msg = %Msg% %AmPm%
}
StringLeft, AlarmTime, AllArgs, StrLen(AllArgs)-StrLen(Remindr)
StringUpper, tmp, AlarmTime
If (tmp not contains A) and (tmp not contains P)
  AlarmTime = %AlarmTime% %AmPm%

; Change input time to 24-hour format (hhmm)
AlarmT := FourDigits(AlarmT)
If AmPm contains P
{
  If AlarmT < 1200
    AlarmT := AlarmT + 1200
}
Else If AmPm contains A
{
  If (AlarmT >= 1200 and AlarmT <= 1259)
  {
    AlarmT := AlarmT - 1200
    AlarmT := FourDigits(AlarmT)
  }
}

; Test for invalid time
If (StrLen(AlarmT) < 1 or AlarmT > 2400 or Mod(AlarmT, 100) > 59)
{
  MsgBox, 16, Alarm, Invalid time %AlarmT%
  ExitApp
}

/*
; Debug:
MsgBox 0, Alarm Debug,
(
AlarmTime = %AlarmTime%
AlarmT = %AlarmT%
Am/Pm = %AmPm%
Reminder = %Remindr%
)
ExitApp
*/

; Main:
; Poll the system time every 5 seconds
; Display alarm/reminder (& optionally play sound file) at alarm time

Loop
{
  FormatTime,now, ,HHmm
  If now <> %AlarmT%
    Sleep, 5000
  Else
  {
    If SoundFile
      SoundPlay, %SoundFile%
    MsgBox, 0, It's %AlarmTime%, %Remindr%
    ExitApp
  }
}
; end ALARM.AHK