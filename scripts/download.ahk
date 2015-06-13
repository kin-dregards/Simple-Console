; - from user 'Bruttosozialprodukt'
;-------- http://www.autohotkey.com/board/topic/101007-super-simple-download-with-progress-bar/ ---

;Example 1 - Download a firefox setup with a progressbar and overwrite it if it already exists on the disk:

a:=a_tickcount
Url = %1%
SplitPath, url, name, dir, ext, name_no_ext, drive
name:= name
RegRead, location, HKEY_CURRENT_USER, SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Shell Folders, {374DE290-123F-4565-9164-39C4925E467B}
fd1=%location%
ifnotexist,%fd1%
 filecreatedir,%fd1%

where=%fd1%\%name%
where:= where
DownloadFile(url,where)
delta:=((a_tickcount-a)/1000)
msgbox, 262208,Downloaded ,Downloaded in %delta% seconds
run,%fd1%
return

/*
;- Example 2 - Download Autohotkey with a progressbar and don't overwrite it if it already exists:

Url            = http://ahkscript.org/download/ahk-install.exe
DownloadAs     = AutoHotkey_L Installer.exe
Overwrite      := False
UseProgressBar := True
DownloadFile(Url, DownloadAs, Overwrite, UseProgressBar)
return
*/
;-------------------------------------------------------------------


DownloadFile(UrlToFile, _SaveFileAs, Overwrite := True, UseProgressBar := True) {
    ;Check if the file already exists and if we must not overwrite it
      If (!Overwrite && FileExist(_SaveFileAs))
          Return
    ;Check if the user wants a progressbar
      If (UseProgressBar) {
          ;Make variables global that we need later when creating a timer
            Global SaveFileAs := _SaveFileAs, FinalSize
          ;Initialize the WinHttpRequest Object
            WebRequest := ComObjCreate("WinHttp.WinHttpRequest.5.1")
          ;Download the headers
            WebRequest.Open("HEAD", UrlToFile)
            WebRequest.Send()
          ;Store the header which holds the file size in a variable:
            FinalSize := WebRequest.GetResponseHeader("Content-Length")
            Progress, H80, , Downloading..., %UrlToFile% Download
            SetTimer, UpdateProgressBar, 100
      }
    ;Download the file
      UrlDownloadToFile, %UrlToFile%, %_SaveFileAs%
    ;Remove the timer and the progressbar  because the download has finished
      If (UseProgressBar) {
          Progress, Off
          SetTimer, UpdateProgressBar, Off
      }
}

UpdateProgressBar:
    ;Get the current filesize and tick
      CurrentSize := FileOpen(SaveFileAs, "r").Length ;FileGetSize wouldn't return reliable results
      CurrentSizeTick := A_TickCount
    ;Calculate the downloadspeed
      Speed := Round((CurrentSize/1024-LastSize/1024)/((CurrentSizeTick-LastSizeTick)/1000)) . " Kb/s"
    ;Save the current filesize and tick for the next time
      LastSizeTick := CurrentSizeTick
      LastSize := FileOpen(SaveFileAs, "r").Length
    ;Calculate percent done
      PercentDone := Round(CurrentSize/FinalSize*100)
    ;Update the ProgressBar
      Progress, %PercentDone%, %PercentDone%`% Done, Downloading...  (%Speed%), Downloading %SaveFileAs% (%PercentDone%`%)
Return
;=================== end script =====================================================================