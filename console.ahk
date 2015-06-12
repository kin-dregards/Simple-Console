﻿#NoEnv  ; Recommended for performance and compatibility with future AutoHotkey releases.
; #Warn  ; Enable warnings to assist with detecting common errors.
SendMode Input  ; Recommended for new scripts due to its superior speed and reliability.
SetWorkingDir %A_ScriptDir%  ; Ensures a consistent starting directory.

f1::
IfWinExist, Console
{
Gui, Destroy
	WinClose
	return
}


IfWinNotExist, Console
{
Gui, Destroy
Gui, -SysMenu +ToolWindow -Caption -Border +AlwaysOnTop
Gui +LastFound 
Gui, Font, cRed
gui, add, edit, x0 y0 w300 h20 vinput
Gui, Color,, Black
gui, add, button, default x302 y4 w26 h20 gok, OK
guicontrol, hide, ok
gui, show, w300 h20 x0 y0, Console
}
return


ok:
 {
gui, submit

StringSplit, word_array, input, %A_Space%, %A_Space%%A_Tab%
StringLen, length, input

	If length = 0
		{
			return
		}

	If input not contains a,b,c,d,e,f,g,h,i,j,k,l,m,n,o,p,q,r,s,t,u,v,w,x,y,z
	If input not contains 1,2,3,4,5,6,7,8,9,0
		{
		return
		}

	If word_array1 = run
		{
			StringTrimLeft, s, input, 4
			run %s%
		}

	If word_array1 = remind
		{
			Run , scripts\reminder.ahk
		}

	If word_array1 = g
		{
			StringTrimLeft, s, input, 2
			Run , https://www.google.co.nz/search?q=%s%
		}

	If word_array1 = yt
		{
			StringTrimLeft, s, input, 2
			Run , https://www.youtube.com/results?search_query=%s%
		}

	If word_array1 = imdb
		{
			StringTrimLeft, s, input, 5
			Run , http://www.imdb.com/find?ref_=nv_sr_fn&q=%s%&s=all
		}

	If word_array1 = wa
		{
			StringTrimLeft, s, input, 3
			Run , https://www.wolframalpha.com/input/?i=%s%
		}

	If word_array1 = map
		{
			StringTrimLeft, s, input, 4
			Run , https://www.google.co.nz/maps?q=%s%
		}

	If word_array1 = d
		{
			StringTrimLeft, s, input, 2
			Run , http://dictionary.reference.com/browse?q=%s%
		}

	If word_array1 = th
		{
			StringTrimLeft, s, input, 2
			Run , http://thesaurus.reference.com/browse?q=%s%
		}

	If word_array1 = ud
		{
			StringTrimLeft, s, input, 2
			Run , http://www.urbandictionary.com/define.php?term=%s%
		}

	If input not contains a,b,c,d,e,f,g,h,i,j,k,l,m,n,o,p,q,r,s,t,u,v,w,x,y,z
	If input contains 1,2,3,4,5,6,7,8,9,0
		{
				file = $temp$.ahk             ; any unused filename
				clipstore:=clipboard ;Store whatever is on the clipboard
				clipboard = ; 
				clipboard = %input%
				FileDelete %file%             ; delete old temporary file -> write new
				FileAppend FileDelete %file%`nFileAppend `% %input%`, %file%, %file%
				RunWait %A_AhkPath% %file%    ; run AHK to execute temp script, evaluate expression
				FileRead clipboard, %file%       ; get result
				FileDelete %file%

				Gui, -SysMenu +ToolWindow -Caption -Border +AlwaysOnTop
				Gui +LastFound 
				Gui, Font, cRed
				gui, add, edit, x0 y0 w300 h20
				Gui, Color,, Black
				gui, add, button, default x302 y4 w26 h20 gok, OK
				guicontrol, hide, ok
				gui, show, w300 h20 x0 y0, Console

				Send ^a
				send ^v
				clipboard:=clipstore
  				Return
	  	}

	If input = stopwatch
		{
			Run , scripts\stopwatch.ahk
		}

	If word_array1 = whois
		{
			StringTrimLeft, s, input, 6
		Run, http://www.networksolutions.com/whois/registry-data.jsp?domain=%s%

		}

	If word_array1 = ping
		{
			StringTrimLeft, ping1, input, 5
			SimplePing(URL, byref speed, timeout = 1000)
				{
					Runwait,%comspec% /c ping -w %timeout% %url%>ping.log,,hide 
					fileread , StrTemp, ping.log
					StrTemp := trim(StrTemp)
					stringsplit , TempArr, StrTemp, =
					ifinstring , TempArr%TempArr0%, ms
					speed :=TempArr%TempArr0%
					else
					speed := "No response."
				}

				SimplePing(ping1, result)

			msgbox, , Ping, Ping to %ping1%: %result%
		}
	
	If word_array1 = volume
		{
			SoundSet, %word_array2%
		}

	If word_array1 = audio
		{
			If length = 5
				{
				Run, mmsys.cpl 
				return
				}
			else
			{
				Run, mmsys.cpl 
				WinWait,Sound ; Change "Sound" to the name of the window in your local language
				Loop, %word_array2%
				    {
				    	send {down}
				    }

				ControlClick,&Set Default ; Change "&Set Default" to the name of the button in your local language 
				ControlClick,OK 
				return
			}
		}



	If word_array1 = kill
		{
			SetTitleMatchMode RegEx
			StringTrimLeft, s, input, 5
			IfWinExist, i)%s%
			WinClose
			else
			return
		}

	If input = pictures
		{
			EnvGet, UserProfile, UserProfile
			run, %UserProfile%\AppData\Roaming\Microsoft\Windows\Libraries\Pictures.library-ms

		}

	If input = documents
		{
			EnvGet, UserProfile, UserProfile
			run, %UserProfile%\AppData\Roaming\Microsoft\Windows\Libraries\Documents.library-ms

		}

	If input = music
		{
			EnvGet, UserProfile, UserProfile
			run, %UserProfile%\AppData\Roaming\Microsoft\Windows\Libraries\Music.library-ms

		}

	If input = videos
		{
			EnvGet, UserProfile, UserProfile
			run, %UserProfile%\AppData\Roaming\Microsoft\Windows\Libraries\Videos.library-ms

		}




	If input = shutdown
		{
		Shutdown, 6
		}

	If input = reboot
		{
		Shutdown, 8
		}

	If input = logoff
		{
		Shutdown, 4
		}

	If input = hibernate
		{
		DllCall("PowrProf\SetSuspendState", "int", 0, "int", 0, "int", 0)
		}

		If word_array1 = bind
		{
			StringTrimLeft, s, input, 5
			FileAppend, %s%`n, commands.txt
		}

	If word_array1 = note
		{
			StringTrimLeft, s, input, 5
			FormatTime, xx,, dd/MM/yy
			FormatTime, zz,, HH:mm 
			FileAppend, %xx% %zz% - %s%`n, notes.txt
		}

	If input = .dir
		{
			Run, %A_ScriptDir%
		}

	If input = help
		{
			Reload
		}
	
	If input = .r
		{
			Reload
		}

}
return


guiclose:
 {
   gui, cancel
 }
return