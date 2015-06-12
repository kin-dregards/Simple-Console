#SingleInstance,Force
DetectHiddenWindows,On
SplitPath,A_AhkPath,,dir
if (A_PtrSize>4){
	if !FileExist(dir "\AutoHotkeyU32.exe"){
		m("This script requires x32 AHK. Please upgrade to the latest version.")
		ExitApp
	}
	Run,%dir%\AutoHotkeyU32.exe %A_ScriptName%
	ExitApp
}
v:=[],settings:=new xml("settings"),v.socklist:=[],v.newmessage:=[],v.TrayTip:=[]
formats()
v.colors:={0:8421376,1:0xff0000,2:0xff0000,3:0xaa00aa,4:0x0000ff,5:0x00ff00,6:0xAAAAAA}
v.dcolors:={0:0xFFFFFF,1:0x0,2:0x7F0000,3:0x009300,4:0x0000FF,5:0x00007F,6:0x9C009C,7:0x007FFC,8:0x00FFFF,9:0x00FC00,10:0x939300,11:0xFFFF00,12:0xFC0000,13:0xFF00FF,14:0x7F7F7F,15:0xD2D2D2}
if !settings.ssn("//theme[@name='default']"){
	Default:=settings.add({path:"theme",att:{name:"default"},dup:1})
	for a,b in v.colors{
		att:=a=0?{font:"Tahoma",size:10,color:b,style:a}:{color:b,style:a}
		settings.under({under:default,node:"style",att:att})
	}
	if old:=settings.sn("//font/*"){
		Default:=settings.add({path:"theme",att:{name:"My Theme"},dup:1})
		while,set:=old.item(a_index-1){
			att:=xml.easyatt(set)
			settings.under({under:default,node:"style",att:att})
		}
	}
	if old:=settings.ssn("//font")
		old.ParentNode.RemoveChild(old),settings.add({path:"gui/theme",text:"My Theme"})
	else
		settings.add({path:"gui/theme",text:"default"})
}
v.ctheme:=settings.ssn("//gui/theme").text?settings.ssn("//gui/theme").text:"default"
v.ctxml:=settings.ssn("//theme[@name='" v.ctheme "']")
FileInstall,SciLexer.dll,SciLexer.dll
if !FileExist("scilexer.dll"){
	SplashTextOn,200,50,Downloading required files,Please wait...
	urldownloadtofile,http://www.maestrith.com/files/AHKStudio/SciLexer.dll,SciLexer.dll
	SplashTextOff
}
CoordMode,ToolTip,Screen
chan:=new xml("channels"),messages:=[],v.cstyle:=40,v.style:={0:0,1:201,2:202,3:203,4:204,5:205,6:206,7:207,201:1,202:2,203:3,204:4,205:5,206:6,207:7} ;,v.style:={0:0,1:9,2:26,3:27,4:28,5:29,6:30,7:31,9:1,26:2,27:3,28:4,29:5,30:6,31:7}
global v,chan,settings,input,messages
username:=settings.ssn("//username").text
username:=username?username:"Guest" %a_now%
v.username:=username
if !settings.ssn("//server")
	settings.add({path:"server/server",att:{name:"irc.freenode.net",port:6667,user:RegExReplace(username,"\W")}})
gui(),wordchar(),Input.2105(0,"`n"),Resize(),focus()
OnExit,GuiClose
return
/*
	GuiContextMenu:
	MouseGetPos,,,,con
	return
*/
if !InStr(con,"Scintilla")
	return
for a,b in ["Copy To Clipboard","Insert Into Typing Area"]
	Menu,rcm,Add,%b%,copytext
Menu,rcm,Show
menu,rcm,DeleteAll
return
GuiClose:
settings.save(1)
ExitApp
return
; Sockets library by Bentschi http://www.autohotkey.com/board/topic/94376-socket-class-%C3%BCberarbeitet/
; slightly edited by maestrith
class Socket{
	static __eventMsg:=0x9987,list:=[]
	__New(s=-1){
		static init
		if (!init){
			DllCall("LoadLibrary","str","ws2_32","ptr")
			VarSetCapacity(wsadata,394+A_PtrSize)
			DllCall("ws2_32\WSAStartup","ushort",0x0000,"ptr",&wsadata)
			DllCall("ws2_32\WSAStartup","ushort",NumGet(wsadata,2,"ushort"),"ptr",&wsadata)
			OnMessage(Socket.__eventMsg,"SocketEventProc")
			init := 1
		}
		this.socket:=s
	}
	__Delete(){
		this.disconnect()
	}
	__Get(k, v){
		if (k="size")
			return this.msgSize()
	}
	connect(host,port){
		Critical
		if ((this.socket!=-1) || (!(faddr := next := this.__getAddrInfo(host, port))))
			return 0
		while (next){
			this.name:=host
			sockaddrlen:=NumGet(next+0,16,"uint"),sockaddr:=NumGet(next+0,16+(2*A_PtrSize),"ptr")
			if ((this.socket:=DllCall("ws2_32\socket","int",NumGet(next+0,4,"int"),"int",this.__socketType,"int",this.__protocolId,"ptr"))!=-1){
				this.list[this.socket]:=this
				if((r:=DllCall("ws2_32\WSAConnect","ptr",this.socket,"ptr",sockaddr,"uint",sockaddrlen,"ptr",0,"ptr",0,"ptr",0,"ptr",0,"int"))=0){
					DllCall("ws2_32\freeaddrinfo","ptr",faddr)
					return Socket.__eventProcRegister(this,0x21)
				}
				this.disconnect()
			}
			next:=NumGet(next+0,16+(3*A_PtrSize),"ptr")
		}
		this.lastError:=DllCall("ws2_32\WSAGetLastError")
		return 0
	}
	bind(host, port){
		m("here")
		if ((this.socket!=-1)||(!(faddr:=next:=this.__getAddrInfo(host,port))))
			return 0
		while (next){
			sockaddrlen := NumGet(next+0, 16, "uint")
			sockaddr := NumGet(next+0, 16+(2*A_PtrSize), "ptr")
			if ((this.socket := DllCall("ws2_32\socket", "int", NumGet(next+0, 4, "int"), "int", this.__socketType, "int", this.__protocolId, "ptr"))!=-1){
				if (DllCall("ws2_32\bind", "ptr", this.socket, "ptr", sockaddr, "uint", sockaddrlen, "int")=0){
					socket.list[this.socket]:=this
					DllCall("ws2_32\freeaddrinfo", "ptr", faddr)
					return Socket.__eventProcRegister(this, 0x29)
				}
				this.disconnect()
			}
			next := NumGet(next+0, 16+(3*A_PtrSize), "ptr")
		}
		this.lastError := DllCall("ws2_32\WSAGetLastError")
		return 0
	}
	listen(backlog=32){
		return (DllCall("ws2_32\listen", "ptr", this.socket, "int", backlog)=0) ? 1 : 0
	}
	accept(){
		if ((s := DllCall("ws2_32\accept", "ptr", this.socket, "ptr", 0, "int", 0, "ptr"))!=-1){
			newsock := new Socket(s)
			newsock.__protocolId := this.__protocolId
			newsock.__socketType := this.__socketType
			Socket.__eventProcRegister(newsock, 0x21)
			return newsock
		}
		return 0
	}
	disconnect(){
		Socket.__eventProcUnregister(this)
		DllCall("ws2_32\closesocket", "ptr", this.socket, "int")
		this.socket := -1
		return 1
	}
	msgSize(){
		VarSetCapacity(argp, 4, 0)
		if (DllCall("ws2_32\ioctlsocket", "ptr", this.socket, "uint", 0x4004667F, "ptr", &argp)!=0)
			return 0
		return NumGet(argp, 0, "int")
	}
	send(addr, length){
		if ((r := DllCall("ws2_32\send", "ptr", this.socket, "ptr", addr, "int", length, "int", 0, "int"))<=0)
			return 0
		return r
	}
	sendText(msg,encoding="UTF-8"){
		msg.="`r`n"
		VarSetCapacity(buffer, length := (StrPut(msg, encoding)*(((encoding="utf-16")||(encoding="cp1200")) ? 2 : 1)))
		StrPut(msg, &buffer, encoding)
		return this.send(&buffer, length-1)
	}
	recv(byref buffer, wait=1){
		Critical
		while ((wait) && ((length := this.msgSize())=0))
			sleep, 100
		if (length){
			VarSetCapacity(buffer, length)
			if ((r := DllCall("ws2_32\recv", "ptr", this.socket, "ptr", &buffer, "int", length, "int", 0))<=0)
				return 0
			return r
		}
		return 0
	}
	recvText(wait=1, encoding="UTF-8"){
		Critical
		if (length := this.recv(buffer, wait))
			return StrGet(&buffer, length, encoding)
		return
	}
	__getAddrInfo(host, port){
		a := ["127.0.0.1", "0.0.0.0", "255.255.255.255", "::1", "::", "FF00::"]
		conv := {localhost:a[1], addr_loopback:a[1], inaddr_loopback:a[1], addr_any:a[2], inaddr_any:a[2], addr_broadcast:a[3]
		, inaddr_broadcast:a[3], addr_none:a[3], inaddr_none:a[3], localhost6:a[4], addr_loopback6:a[4], inaddr_loopback6:a[4]
		, addr_any6:a[5], inaddr_any:a[5], addr_broadcast6:a[6], inaddr_broadcast6:a[6], addr_none6:a[6], inaddr_none6:a[6]}
		if (conv[host])
			host := conv[host]
		VarSetCapacity(hints, 16+(4*A_PtrSize), 0)
		NumPut(this.__socketType, hints, 8, "int")
		NumPut(this.__protocolId, hints, 12, "int")
		if ((r := DllCall("ws2_32\getaddrinfo", "astr", host, "astr", port, "ptr", &hints, "ptr*", next))!=0){
			this.lastError := DllCall("ws2_32\WSAGetLastError")
			return 0
		}
		return next
	}
	__eventProcRegister(obj, msg){
		a := SocketEventProc(0, 0, "register", 0)
		a[obj.socket] := obj
		return (DllCall("ws2_32\WSAAsyncSelect", "ptr", obj.socket, "ptr", A_ScriptHwnd, "uint", Socket.__eventMsg, "uint", msg)=0) ? 1 : 0
	}
	__eventProcUnregister(obj){
		a := SocketEventProc(0, 0, "register", 0)
		a.remove(obj.socket)
		return (DllCall("ws2_32\WSAAsyncSelect", "ptr", obj.socket, "ptr", A_ScriptHwnd, "uint", 0, "uint", 0)=0) ? 1 : 0
	}
}
SocketEventProc(wParam, lParam, msg, hwnd){
	Critical
	global Socket
	static a := []
	Critical
	if (msg="register")
		return a
	if (msg=Socket.__eventMsg){
		if (!isobject(a[wParam]))
			return 0
		if ((lParam & 0xFFFF) = 1)
			return a[wParam].onRecv(a[wParam])
		else if ((lParam & 0xFFFF) = 8)
			return a[wParam].onAccept(a[wParam])
		else if ((lParam & 0xFFFF) = 32){
			a[wParam].socket := -1
			return a[wParam].onDisconnect(a[wParam])
		}
		return 0
	}
	return 0
}
class SocketTCP extends Socket
{
	static __protocolId := 6 ;IPPROTO_TCP
	static __socketType := 1 ;SOCK_STREAM
}
class SocketUDP extends Socket{
	static __protocolId := 17 ;IPPROTO_UDP
	static __socketType := 2 ;SOCK_DGRAM
	enableBroadcast(){
		VarSetCapacity(optval, 4, 0)
		NumPut(1, optval, 0, "uint")
		if (DllCall("ws2_32\setsockopt", "ptr", this.socket, "int", 0xFFFF, "int", 0x0020, "ptr", &optval, "int", 4)=0)
			return 1
		return 0
	}
	disableBroadcast(){
		VarSetCapacity(optval, 4, 0)
		if (DllCall("ws2_32\setsockopt", "ptr", this.socket, "int", 0xFFFF, "int", 0x0020, "ptr", &optval, "int", 4)=0)
			return 1
		return 0
	}
}
;---------------------------------------end socket--------------
t(x*){
	for a,b in x
		list.=b "`n"
	ToolTip,%list%
}
m(x*){
	for a,b in x
		list.=b "`n"
	MsgBox,0,AHK IRC,% list
}
hwnd(win,hwnd=0){
	static windows:=[]
	if win.all
		return windows
	if win&&hwnd
		return windows[win]:=hwnd
	if win.rem
		return windows[win.rem]:=0
	if win.1
		return "ahk_id" windows[win.1]
	return windows[win]
}
gui(){
	static
	DllCall("LoadLibrary","str","scilexer.dll")
	Gui,+hwndhwnd +Resize +MinSize450x200
	Gui,Color,0,0
	hwnd(1,hwnd)
	OnMessage(0x06,"Focus"),OnMessage(0x4E,"notify"),OnMessage(0x5,"Resize"),OnMessage(0x232,"endmove"),OnMessage(0x201,"movewin"),OnMessage(0x404, "Traytip")
	OnMessage(0xA4,"deadend"),OnMessage(0x205,"rbutton")
	hotkey()
	Gui,Margin,5,5
	Gui,Color,0,0
	il:=IL_Create(2)
	for a,b in [10,2,78]
		IL_Add(il,"shell32.dll",b)
	Gui,Add,TreeView,w150 h200 gg vchangechan hwndcc AltSubmit ImageList%il% c0xffffff
	Gui,Add,TreeView,xm h155 y+10 w150 gg vpopinfo hwndss AltSubmit Section c0xffffff
	input:=new s(1,"x160")
	sc:=new s(1,"x160 y0"),Resize(0),color(sc),color(input)
	under:=chan.add({path:"startup",att:{control:sc.sc}})
	for a,b in [cc,ss]
		chan.under({under:under,node:"TreeView",att:{treeview:b},dup:1})
	addtext(sc,help(1),40),sc.2530(0,"Help")
	input.2130(0),input.2115(1),input.2112(0,":")
	ea:=settings.ea("//gui/window[@window='1']")
	w:=ea.width?ea.width:700,h:=ea.height?ea.height:500,x:=ea.x!=""?ea.x:"Center",y:=ea.y!=""?ea.y:"Center"
	Gui,1:Show,x%x% y%y% w%w% h%h%
	if ea.maximize
		WinMaximize,% hwnd([1])
	popaj()
	d({t:2}),TV_Modify(TV_GetChild(0),"Select Vis Focus")
	ControlFocus,Scintilla2,% hwnd([1])
	return
	help:
	d({t:1}),TV_Modify(0,"Select Vis Focus")
	return	
	caption:
	WinGet,style,style,% hwnd([1])
	if (style&0xC00000)
		Gui,1:-Resize -caption
	else
		Gui,1:+Resize +caption
	return
}
focus(){
	ControlFocus,Scintilla1,% hwnd([1])
}
d(info){
	win:=info.w?info.w:1
	type:=info.t?"TreeView":"ListView"
	control:=info.t?"SysTreeView32":"SysListView32"
	con:=info.t?info.t:info.l
	Gui,%win%:Default
	Gui,%win%:%type%,% control con
}
refresh(info){
	win:=info.w?info.w:1
	oo:=info.o?"+":"-"
	control:=info.t?"SysTreeView32":"SysListView32"
	con:=info.t?info.t:info.l
	GuiControl,%win%:%oo%Redraw,% control con
}
changechan(x=""){
	static last:=[]
	if (A_GuiEvent="RightClick"){
		d({t:1,w:1}),TV_GetText(channel,A_EventInfo),last:={tv:A_EventInfo,channel:channel}
		if !channel
			return
		;operation:=TV_GetParent(A_EventInfo)=0?"Disconnect from ":"Close "
		if TV_GetParent(A_EventInfo)=0
			menu("server",["Disconnect from " channel])
		else
			menu("channel",["Close " channel]),v.eventinfo:=A_EventInfo
	}
	if x
		goto ccnext
	if A_GuiEvent not in Normal,S
		return
	ccnext:
	d({t:1}),current:=TV_GetSelection(),ea:=xml.easyatt(chan.ssn("//*[@tv='" current "']"))
	if !current
		ea:=chan.ea("//startup")
	num:=ea.control
	hide:=chan.sn("//@control|//@treeview")
	Gui,1:Default
	while,cc:=hide.item(a_index-1){
		if ssn(cc,"..").nodename!="treeview"
			GuiControl,1:Hide,% cc.text
	}
	Gui,1:Default
	if ea.treeview
		GuiControl,Show,% ea.treeview
	Gui,1:Default
	GuiControl,Show,% s.ctrl[num].sc
	icon:=TV_GetParent(current)?"Icon2 -bold":"Icon1 -bold"
	title:=ea.topic?ea.name " - " ea.topic:ea.name
	WinSetTitle,% hwnd([1]),,%title%
	d({t:1}),TV_Modify(current,icon),v.newmessage.remove(current)
	tv_redraw(),focus()
	return
	unread:
	for a,b in v.newmessage
		return TV_Modify(a,"Select Vis Focus")
}
updatechan(sel=""){
	d({l:1}),LV_Delete()
	list:=chan.sn("//channel/@name")
	while,cc:=list.item(a_index-1){
		Select:=cc.text=sel?"Select Vis Focus Sort":"Sort"
		LV_Add(select,cc.text)
	}
	if IsObject(sel)
		LV_Modify(sel.1,"Select Vis Focus")
}
class s{
	static ctrl:=[],lc:=""
	__New(win=1,pos=""){
		static count=1
		v.count:=count
		Gui,%win%:Add,custom,classScintilla hwndsc %pos% +1387331584
		sc:=sc+0,this.sc:=sc,t:=[],s.sc[sc]:=this
		if count!=1
			s.ctrl[sc]:=this
		for a,b in {fn:2184,ptr:2185}
			this[a]:=DllCall("SendMessageA","UInt",sc,"int",b,int,0,int,0)
		v.focus:=sc,this.num:=count
		this.2460(3)
		this.2090(8)
		for a,b in [[2563,1],[2565,1],[2614,1],[2630,1],[2521,1],[2037,65001],[2412,1],[2052,32,0],[2242,1,0],[2130,0]]{
			b.2:=b.2?b.2:0,b.3:=b.3?b.3:0
			this[b.1](b.2,b.3)
		}
		if count!=1
		for a,b in [[2371,0],[2171,1],[2268,1],[2403,0x15,10],[2409,1,1],[2240,0,4],[2052,33,0],[2240,1,0],[2188,0]]{
			b.2:=b.2?b.2:0,b.3:=b.3?b.3:0
			this[b.1](b.2,b.3)
		}
		else
			this[2069](0xffffff),this[2242](1,0)
		loop,16
			b:=A_Index-1,this.2080(b,8),this.2082(b,v.dcolors[A_Index-1]),this.2523(b,255),this.2510(b,1),this.2558(b,255)
		count++
		v.lastscin:=this
		return this
	}
	__Get(x*){
		return DllCall(this.fn,"Ptr",this.ptr,"UInt",x.1,int,0,int,0,"Cdecl")
	}
	__Call(code,lparam=0,wparam=0){
		if (code="getseltext"){
			VarSetCapacity(text,this.2161),length:=this.2161(0,&text)
			return StrGet(&text,length,"cp0")
		}
		if (code="textrange"){
			VarSetCapacity(text,abs(lparam-wparam)),VarSetCapacity(textrange,12,0),NumPut(lparam,textrange,0),NumPut(wparam,textrange,4),NumPut(&text,textrange,8)
			this.2162(0,&textrange)
			return strget(&text,"","cp0")
		}
		if (code="gettext"){
			cap:=VarSetCapacity(text,vv:=this.2182),this.2182(vv,&text),t:=strget(&text,vv,"cp0")
			return t
		}
		wp:=(wparam+0)!=""?"Int":"AStr"
		if wparam.1
			wp:="AStr",wparam:=wparam.1
		return DllCall(this.fn,"Ptr",this.ptr,"UInt",code,int,lparam,wp,wparam,"Cdecl")
	}
}
class xml{
	keep:=[]
	__New(param*){
		root:=param.1,file:=param.2
		file:=file?file:root ".xml"
		temp:=ComObjCreate("MSXML2.DOMDocument"),temp.setProperty("SelectionLanguage","XPath")
		this.xml:=temp
		SplitPath,file,,dd
		IfNotExist,%dd%
			FileCreateDir,%dd%
		ifexist %file%
			temp.load(file),this.xml:=temp
		else
			this.xml:=this.CreateElement(temp,root)
		this.file:=file
		xml.keep[ref]:=this
	}
	CreateElement(doc,root){
		return doc.AppendChild(this.xml.CreateElement(root)).parentnode
	}
	under(info){
		new:=info.under.appendchild(this.xml.createelement(info.node))
		for a,b in info.att
			new.SetAttribute(a,b)
		new.text:=info.text
		return new
	}
	add(info){
		path:=info.path,p:="/",dup:=this.ssn("//" path)?1:0
		if next:=this.ssn("//" path)?this.ssn("//" path):this.ssn("//*")
			Loop,Parse,path,/
				last:=A_LoopField,p.="/" last,next:=this.ssn(p)?this.ssn(p):next.appendchild(this.xml.CreateElement(last))
		if (info.dup&&dup)
			next:=next.parentnode.appendchild(this.xml.CreateElement(last))
		for a,b in info.att
			next.SetAttribute(a,b)
		if info.text!=""
			next.text:=info.text
		return next
	}
	ssn(node,find=""){
		if (find)
			return this.xml.SelectSingleNode(node "[contains(.,'" RegExReplace(find,"'","')][contains(.,'") "')]..")
		return this.xml.SelectSingleNode(node)
	}
	sn(node){
		return this.xml.SelectNodes(node)
	}
	__Get(x=""){
		return this.xml.xml
	}
	transform(){
		static
		if !IsObject(xsl){
			xsl:=ComObjCreate("MSXML2.DOMDocument")
			style=
			(
			<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform">
			<xsl:output method="xml" indent="yes" encoding="UTF-8"/>
			<xsl:template match="@*|node()">
			<xsl:copy>
			<xsl:apply-templates select="@*|node()"/>
			<xsl:for-each select="@*">
			<xsl:text></xsl:text>
			</xsl:for-each>
			</xsl:copy>
			</xsl:template>
			</xsl:stylesheet>
			)
			xsl.loadXML(style),style:=null
		}
		this.xml.transformNodeToObject(xsl,this.xml)
	}
	save(x*){
		if x.1=1
			this.Transform()
		filename:=this.file?this.file:x.1.1
		file:=fileopen(filename,"rw")
		file.seek(0)
		file.write(this.xml.xml)
		file.length(file.position)
	}
	ea(path){
		if !IsObject(path)
			list:=this.ssn(path),ll:=[],nodes:=sn(list,"@*")
		else
			nodes:=sn(path,"@*"),ll:=[]
		while,n:=nodes.item(a_index-1)
			ll[n.nodename]:=n.text
		return ll
	}
	easyatt(path){
		list:=[]
		if nodes:=path.nodename
			nodes:=path.SelectNodes("@*")
		else if path.text
			nodes:=this.sn("//*[text()='" path.text "']/@*")
		else
			for a,b in path
				nodes:=this.sn("//*[@" a "='" b "']/@*")
		while,n:=nodes.item(A_Index-1)
			list[n.nodename]:=n.text
		return list
	}
	search(node,find,return=""){
		found:=this.xml.SelectNodes(node "[contains(.,'" RegExReplace(find,"'","')][contains(.,'") "')]")
		while,ff:=found.item(a_index-1)
		if (ff.text=find){
			if return
				return ssn(ff,"../" return)
			return ssn(ff,"..")
		}
	}
	removeall(node,find){
		found:=this.xml.SelectNodes(node "[contains(.,'" RegExReplace(find,"'","')][contains(.,'") "')]")
		while,ff:=found.item(a_index-1){
			if (ff.text=find){
				ff:=ssn(ff,"..")
				ff.ParentNode.RemoveChild(ff)
			}
		}
	}
	unique(info){
		if (info.check!=""){
			find:=this.ssn("//" info.path "[@" info.check "='" info.att[info.check] "']")
			if !find
				find:=this.add({path:info.path,att:info.att,dup:1})
		}
		for a,b in info.att
			find.SetAttribute(a,b)
		if info.text
			find.text:=info.text
		return find
	}
	
}
ssn(node,path){
	return node.SelectSingleNode(path)
}
sn(node,path){
	return node.SelectNodes(path)
}
search(node,path,find,return=""){
	found:=node.SelectNodes(path "[contains(.,'" RegExReplace(find,"'","')][contains(.,'") "')]")
	while,ff:=found.item(a_index-1)
		if (ff.text=find)
			if return
				return ssn(ff,"../" return)
	else
		return ssn(ff,"..")
}
send(message=""){
	;edit:=trim(input.gettext(),"`r`n")
	;StringReplace,edit,edit,% chr(194),,All
	edit:=message?message:edit
	if !edit
		return
	d({t:1}),tv:=TV_GetSelection(),TV_GetText(channel,tv)
	history(channel,edit)
	sock:=socket.list[chan.ssn("//*[@tv='" tv "']/ancestor-or-self::*/@socket").text]
	srvr:=chan.ssn("//*[@socket='" sock.socket "']"),cc:=search(srvr,"channel/@name",channel)
	bankick:=ssn(cc,"@kicked").text?"kicked":"",bankick:=ssn(cc,"@banned").text&&bankick=""?"banned":""
	if (bankick&&SubStr(message,1,1)!="/"){
		MsgBox,4,IRC,You were banned from this channel.  Attempt to rejoin?
		IfMsgBox,Yes
			sock.sendtext("JOIN " channel)
		exit
	}
	StringSplit,edit,edit,%A_Space%
	top:=chan.ssn("//*[@tv='" tv "']")
	password:=settings.search("//server/@name",ssn(top,"ancestor-or-self::server/@name").text,"@password").text
	nick:=ssn(top,"ancestor-or-self::*[@user!='']/@user").text
	cc:=search(top,"@name",channel)
	if (top.nodename="server"&&SubStr(edit,1,1)!="/")
		return sock.Sendtext(edit),display({text:edit,socket:sock})
	info:=msg(Edit)
	if (info.1="/quit"||info.1="/q")
		return quit(sock)
	else if (info.1="/t"||info.1="/topic")
		return sock.sendtext("PRIVMSG CHANSERV :TOPIC " channel " " msg(edit,1).2)
	else if (info.1="/c"||info.1="/chanserv")
		return sock.sendtext("PRIVMSG CHANSERV :" msg(edit,1).2)
	else if (info.1="/nn")
		return sock.sendtext("NAMES " channel)
	else if (info.1="/me")
		mm:="PRIVMSG " channel " :" chr(1) "ACTION " msg(edit,1).2 chr(1)
	else if (info.1="/i"||info.1="/ident")
		return sock.sendtext("PRIVMSG NICKSERV :IDENTIFY " password)
	else if (info.1="/away")
		return sock.sendtext("AWAY :" msg(edit,1).2)
	else if (info.1="/nick")
		return sock.sendtext("nick " msg(edit,1).2)
	else if (info.1="/n"||info.1="/nickserv")
		return sock.sendtext("PRIVMSG NICKSERV :" msg(edit,1).2)
	else if (info.1="/raw"||info.1="/r"||info.1="/")
		return sock.sendtext(msg(edit,1).2)
	else if (info.1="/msg"||info.1="/m")
		return sock.sendtext("PRIVMSG " info.2 " :" msg(edit,2).3) ;,display({user:nick,chan:info.2,text:msg(edit,2).3,socket:sock})
	else if (info.1="/part"||info.1="/p"){
		mm:=strsplit(edit," ")
		if mm.2
			return sock.sendtext("PART " out:=InStr(mm.2,"#")?mm.2:"#" mm.2,msg(edit,2).3)
		return sock.sendtext("PART " channel)
	}
	else if (info.1="/j"||info.1="/join"),info:=msg(edit,1)
		return sock.sendtext("JOIN " out:=InStr(info.2,"#")?info.2:"#" info.2)
	else
		mm:="PRIVMSG " channel " :" edit
	if Password
		mm:=RegExReplace(mm,"i)" password,"*****"),edit:=RegExReplace(edit,"i)" password,"*****")
	if (info.1="/me")
		display({text:"***" nick " " msg(edit,1).2,chan:channel,socket:sock})
	if mm
		sock.Sendtext(mm)
	if !InStr(info.1,"/")
		display({text:edit,chan:channel,socket:sock,user:nick})
	input.2004
	return
	g:
	%A_GuiControl%()
	return
}
msg(edit,count=0){
	if !(count){
		StringSplit,Edit,edit,%a_space%
		return [edit1,edit2,edit3]
	}
	loop,%count%
		search.="\W(.+)"
	RegExMatch(edit,"OU)(.+)" search "$",info)
	return info
}


next(message,sock){
	static pl:={"@":"Operator","+":"Voice","":"Normal"}
	LV_GetText(curchan,LV_GetNext())
	currentpage:=main.2357,d({t:2}),srvr:=chan.ssn("//*[@socket='" sock.socket "']"),ea:=xml.easyatt(srvr)
	Loop,Parse,message,`r`n,`r`n
	{
		if !A_LoopField
			continue
		in:=strsplit(A_LoopField," ")
		msg:=SubStr(A_LoopField,InStr(A_LoopField,":",0,1,2)+1)
		regexmatch(in.1,"A):(.+)!",user)
		;----Welcome----
		if (in.2=1||in.2=001){
			if ea.user!=in.3
				srvr.SetAttribute("user",in.3)
		}
		;----Duplicate nickname----
		if (in.2=433){
			sleep,200
			sock.sendtext("NICK " SubStr(in.4,1,10) "1")
		}
		;----MOTD/No MOTD-----
		if (in.2=376||in.2=422){
			srv:=chan.ssn("//*[@socket='" sock.socket "']/@name").text
			if Password:=settings.search("//@name",srv,"@password").text
				sock.sendtext("PRIVMSG NICKSERV :IDENTIFY " Password)
			list:=sn(settings.search("//@name",srv),"channel")
			while,item:=list.item(a_index-1)
				ll.=ssn(item,"@name").text ","
			if ll
				sock.sendtext("JOIN " Trim(ll,","))
		}
		if (in.2="topic"){
			topic:=SubStr(A_LoopField,InStr(A_LoopField,":",0,1,2)+1)
			cc:=search(srvr,"channel/@name",in.3)
			cc.SetAttribute("topic",topic)
			d({t:1}),ctv:=TV_GetSelection()
			if (ssn(cc,"@tv").text=ctv)
				WinSetTitle,% hwnd([1]),,% in.3 " - " topic
		}
		;----WhoReply----
		if (in.2=352)
			return whoreply(sock,in)
		;----Banlist----
		if (in.2=367)
			buildbanlist(in)
		;----End Banlist----
		if (in.2=368)
			buildbanlist("show")
		;----Topic----
		if (in.2=332){
			topic:=SubStr(A_LoopField,InStr(A_LoopField,":",0,1,2)+1)
			cc:=display({text:"Topic=" topic,chan:in.4,user:user1,socket:sock})
			cc.SetAttribute("topic",topic)
			WinSetTitle,% hwnd([1]),,% in.4 " - " topic
		}
		;----Name reply----
		if (in.2=353)
			v.lastline.=SubStr(A_LoopField,InStr(A_LoopField,":",0,1,2)+1) " "
		;----End of names----
		if (in.2=366){
			if cc:=search(srvr,"channel/@name",in.4){
				all:=sn(cc,"*")
				while,aa:=all.item(a_index-1)
					cc.RemoveChild(aa)
			}
			else
			{
				cc:=""
				cc:=display({text:"Users=" v.lastline,chan:in.4,user:user1,socket:sock})
				while,!IsObject(cc)
					sleep,20
			}
			d({t:1}),TV_Modify(ssn(cc,"@tv").text,"Select Focus Vis")
			for a,b in ["Operator","Voice","Normal"]
				chan.under({under:cc,node:b})
			cc:=search(srvr,"channel/@name",in.4)
			out:=strsplit(v.lastline," ")
			for a,user in out{
				if !user
					continue
				Prefix:=SubStr(user,1,1)
				if Prefix in @,+
					user:=SubStr(user,2)
				else
					Prefix:=""
				under:=ssn(cc,pl[prefix])
				op:=pl[prefix]="operator"?1:0,voice:=pl[prefix]="voice"||pl[prefix]="operator"?1:0
				chan.under({under:under,node:"user",att:{user:user,operator:op,voice:voice}})
			}
			list:=sn(cc,"descendant::*"),loop:=[]
			Gui,TreeView,% ssn(cc,"@treeview").text
			TV_Delete()
			while,ll:=list.item(a_index-1){
				if ll.nodename!="user"
					tt:=TV_Add(ll.nodename),loop[tt]:=1,ll.SetAttribute("tv",tt)
				if (ll.nodename="operator")
					root:=tt
				if ll.nodename="user"
					tv:=TV_Add(ssn(ll,"@user").text,tt,"Sort"),ll.SetAttribute("tv",tv)
			}
			for a in loop
				TV_Modify(a,"Expand")
			TV_Modify(root,"Vis Focus Select")
			v.lastline:=""
		}
		;---------------
		if (in.1="ping")
			sock.Sendtext("PONG " in.2)
		if (in.2="JOIN"&&ea.user!=user1){
			cc:=search(srvr,"channel/@name",in.3),user:=user1
			cc.RemoveAttribute("kicked"),cc.RemoveAttribute("banned")
			if RegExMatch(SubStr(user,1,1),"\W",prefix)
				user:=SubStr(user,2)
			under:=ssn(cc,pl[prefix])
			newusr:=chan.under({under:under,node:"user",att:{user:user}})
			id:=ssn(under,"@tv").text
			Gui,TreeView,% "ahk_id" ssn(cc,"@treeview").text
			new:=TV_Add(user,id,"Sort"),TV_Modify(id,"Expand")
			newusr.SetAttribute("tv",new)
			updatenicks(in.3),display({text:user " has joined the channel",chan:in.3,socket:sock})
			tv_redraw(ssn(cc,"@treeview").text)
		}
		if (in.2="QUIT"){
			found:=sn(srvr,"descendant::*[@user='" user1 "']"),list:=[]
			while,ff:=found.item(a_index-1){
				ancestor:=ssn(ff,"ancestor::channel")
				list[ssn(ancestor,"@name").text]:=1
				Gui,TreeView,% ssn(ancestor,"@treeview").text
				tv:=ssn(ff,"@tv").text
				d({t:1}),TV_Delete(tv),tv_redraw(ssn(ancestor,"@treeview").text)
				ff.ParentNode.RemoveChild(ff)
			}
			for cc in list
				display({text:user1 " has quit the server",chan:cc,socket:sock})
			;tv_redraw()
		}
		if (in.2="PART"){
			user:=user1
			in.3:=RegExReplace(in.3,"A):"),cc:=search(srvr,"channel/@name",in.3)
			if (ea.user=user){
				ea:=xml.easyatt(cc)
				for a,b in [ea.control,ea.TreeView]
					WinKill,ahk_id%b%
				tv:=ssn(cc,"@tv").text,cc.ParentNode.RemoveChild(cc),d({t:1})
				tv1:=TV_GetNext(tv)?TV_GetNext(tv):TV_GetPrev(tv),TV_Delete(tv),TV_Modify(tv1,"Select Vis Focus"),tv_redraw()
				return
			}
			else uu:=ssn(cc,"descendant::user[@user='" user "']")
				treeview:=ssn(uu,"ancestor::channel/@treeview").text,tv:=ssn(uu,"@tv").text,uu.ParentNode.RemoveChild(uu)
			if (user!=ea.user){
				display({text:user " has left the channel",chan:in.3,socket:sock})
				tv_rem(treeview,tv)
				tv_redraw(treeview)
			}
		}
		if (in.2="NICK"){
			newnick:=SubStr(in.3,2)
			if (user1=ea.user){
				srvr.SetAttribute("user",newnick)
				ea.user:=newnick
			}
			found:=sn(srvr,"descendant::*[@user='" user1 "']/@user")
			while,ff:=found.item(a_index-1){
				if (ff.text=user1){
					top:=ssn(ff,"..")
					if tv:=ssn(top,"@tv").text{
						Gui,TreeView,% ssn(top,"ancestor::*[@treeview]/@treeview").text
						TV_Modify(tv,"",newnick)
					}
					ff.text:=newnick
				}
			}
			ch:=sn(srvr,"descendant::channel[@name='" user1 "']")
			while,cc:=ch.item(a_index-1){
				d({t:1}),TV_Modify(ssn(cc,"@tv").text,"",newnick)
				cc.SetAttribute("name",newnick)
			}
			d({t:1})
			list:=chan.sn("//*[@tv='" TV_GetSelection() "']/descendant-or-self::*[@user!='']/@user")
			while,ll:=list.item(a_index-1)
				ul.=ll.text " "
			v.userlist:=ul
		}
		if (in.2="kick"){
			;in.4=user in.3=channel
			reason:=msg=in.4?"":" (" msg ")"
			cc:=search(srvr,"channel/@name",in.3),usr:=ssn(cc,"descendant::user[@user='" in.4 "']/@tv")
			tv:=usr.text,usr.ParentNode.RemoveChild(usr)
			if (in.4=ssn(srvr,"@user").text)
				display({text:"You have been kicked by " user1 reason,chan:in.3,user:user1,socket:sock,notice:1}),cc.SetAttribute("kicked",1)
			else
				tv_rem(ssn(cc,"ancestor::channel/@treeview").text,tv),sock.sendtext("NAMES " in.3),display({text:"I kicked " in.4 " " reason,chan:in.3,user:user1,socket:sock,notice:1})
		}
		if (in.2="MODE"&&in.5){
			;FileAppend,% A_LoopField`r`n,ban.txt
			if found:=InStr(in.5,"!")
				in.5:=SubStr(in.5,1,found-1)
			self:=ssn(srvr,"@user").text
			cc:=search(srvr,"channel/@name",in.3),treeview:=ssn(cc,"@treeview").text,uu:=ssn(cc,"descendant::user[@user='" in.5 "']")
			if (InStr(in.4,"+b")){
				
				;:maestrith_test!~maestrith@cpe-76-188-92-52.neo.res.rr.com MODE #maestrith +b flan!*@*
				;t(A_LoopField)
				;return m("You have been banned :(",cc.xml),cc.SetAttribute("banned",1)
				
				;if it is self
				;Gui,TreeView,%TreeView%
				;if tv:=ssn(uu,"@tv").text
				;TV_Delete(tv),tv_redraw(treeview)
			}
			for a,b in [["+o","operator",1],["-o","operator",0],["+v","voice",1],["-v","voice",0]]{
				if InStr(in.4,b.1){
					Gui,TreeView,%TreeView%
					uu.SetAttribute(b.2,b.3)
					TV_Delete(ssn(uu,"@tv").text)
					if ssn(uu,"@operator").text{
						uu:=ssn(cc,"Operator").AppendChild(uu)
						goto modeend
					}
					if ssn(uu,"@voice").text{
						uu:=ssn(cc,"Voice").AppendChild(uu)
						goto modeend
					}
					uu:=ssn(cc,"Normal").AppendChild(uu)
					modeend:
					tv:=ssn(uu.ParentNode,"@tv").text
					Gui,TreeView,%TreeView%
					newtv:=TV_Add(in.5,tv,"Sort")
					uu.SetAttribute("tv",newtv)
				}
			}
			TV_Modify(tv,"Expand")
			tv_redraw(treeview)
		}
		if (in.2=311||in.2=319||in.2=312||in.2=317||in.2=330||in.2=318)
			whois({in:in,msg:msg})
		else if (in.2="NOTICE"){
			display({text:msg,chan:user1,user:user1,socket:sock,mark:mark,notice:1})
			;display({text:A_LoopField,chan:user1,user:user1,socket:sock,mark:mark,notice:1})
		}
		else if (in.2="PRIVMSG"){
			if InStr(msg,Chr(1))&&InStr(msg,"ping")
				sock.sendtext("PONG " RegExReplace(msg,"\D")+1),t(RegExReplace(msg,"\D"))
			cc:=if InStr(in.3,"#")?in.3:user1
			mark:=regexmatch(msg,"i)\b" ea.user "\b")?1:0
			display({text:msg,chan:cc,user:user1,socket:sock,mark:mark})
		}
		else
			;display({text:A_LoopField,socket:sock})
		display({text:msg,socket:sock})
	}
}
currentchan(byref channel){
	if !LV_GetNext()
		channel:=""
	else
		LV_GetText(channel,LV_GetNext())
}
notify(wp,info,c,d){
	Critical
	;static in:=[]
	sc:=NumGet(info+0)
	if !main:=s.sc[sc]
		return
	static last
	fn:=[]
	for a,b in {0:"Obj",2:"Code",4:"ch",7:"text",6:"modType",9:"linesadded",3:"position",13:"line",8:"length"}
		fn[b]:=NumGet(Info+(A_PtrSize*a))
	if (sc=input.sc&&fn.code=2008){
		if (fn.modtype&0x1){
			length:=fn.length,start:=fn.position
			if (start+1=input.2006){
				style:=v.cstyle
				if v.cbackground!=""
					input.2500(v.cbackground),input.2504(start,length)
			}
			else
			{
				style:=input.2010(start-1)
				style:=style=0?40:style
				style:=style<0?style+256:style
			}
			input.2032(start,255)
			input.2033(length,style)
		}
		if (fn.modtype&0x2){
			start:=fn.position-1>=0?fn.position:0
			style:=input.2010(start-1)>0?input.2010(start-1):256+input.2010(start-1)
			2032(start,255)
			input.2033(1,style)
		}
	}
	if (sc=v.theme&&fn.code=2010){
		if GetKeyState("Control","P")
			return cfont(2)
		return ccolor(2,main.2481(2))
	}
	if (sc=v.theme&&fn.code=2027){
		style:=main.2010(main.2008)
		if GetKeyState("Control","P")
			return cfont(style)
		if GetKeyState("Alt","P"){
			if style=40
				return
			change:=ssn(v.ctxml,"descendant::style[@style='" style "']")
			ea:=xml.ea(change)
			for a,b in ea
				if a not in color,style
					change.RemoveAttribute(a)
			color(style)
			return
		}
		return ccolor(style,main.2481(style))
	}
	if (fn.code=2027){
		start:=end:=main.2008
		while,main.2010(start)=1
			start--
		while,main.2010(end)=1
			end++
		url:=main.textrange(start+1,end)
		url:=RegExMatch(url,"Ai)http")?url:"http://" url
		Run,% url
	}
	if (fn.code=2004)
		input.2400()
	if (fn.code=2001&&sc=input.sc){
		cp:=input.2008
		word:=input.textrange(start:=input.2266(cp-1,0),end:=input.2267(cp-1,0))
		li:=""
		if InStr(word,"/")
			return command(word)
		if (StrLen(word)>1&&input.2102=0){
			st:=SubStr(word,1,1)
			StringUpper,upper,st
			StringLower,lower,st
			d({t:1}),root:=chan.ssn("//*[@tv='" TV_GetSelection() "']")
			sel:=sn(root,"descendant::user/@user[starts-with(.,upper)][starts-with(.,lower)]")
			while,ss:=sel.item(a_index-1)
				if InStr(ss.text,word)
					li.=ss.text " "
			li:=Trim(li)
			Sort,li,D%A_Space%
			if li
				input.2100(StrLen(word),li)
		}
	}
}
stripurl(main,text){
	static flip:={29:1,2:2,31:4,15:0}
	sss:=40,style:=0,pos:=0 ;,color1:=0
	ss:=strsplit(text,[Chr(29),Chr(2),Chr(31),Chr(15),Chr(3)])
	for a,b in ss{
		pos+=StrLen(b)+1
		if (code=3){
			RegExMatch(b,"^(\d+),?(\d+)?",color)
			if (color1=""){
				color2:=""
				end:=addtext(main,b,style+40),sss:=style+40 ;,laststyle:=style+40
			}
			else
			{
				b:=SubStr(b,StrLen(color)+1)
				startstyle:=color1*8+48
				if (main.2484(startstyle+1)=0)
					addstyles(main,color1),addstyles(input,color1)
				end:=addtext(main,b,color1*8+48+style,color2),sss:=color1*8+48+style ;,laststyle:=color1*8+48+style
			}
		}
		else
		{
			ss:=flip[code]
			if !ss
				style:=0
			else
				style:=style&ss?style-ss:style|=ss
			sss:=mod(sss,8)>style?sss-mod(sss,8)+style:sss|=style
			end:=addtext(main,b,sss,color2)
		}
		code:=Asc(SubStr(text,pos,1))
		if (main.sc!=input.sc)
			if b contains http,ftp,.com,.net,.gov,.org,mailto
			{
				url:=strsplit(b," "),add:=0
				for c,tt in url{
					if tt contains http,ftp,.com,.net,.gov,.org,mailto,.co.uk,.biz
					{
					actualurl:=RegExReplace(RegExReplace(tt,"^(\W+)"),"(\W+)$")
					more:=InStr(tt,actualurl)
					main.2032(end+add+more-1,255),main.2033(StrLen(actualurl),1)
					}
				add+=StrLen(tt)+1
				}
		}
	}
}
check_for_update(){
	Version=0.001.44
	Gui,4:Destroy
	Gui,4:Default
	Gui,4:+hwndver
	SplashTextOn,100,50,Please Wait.,Downloading information...
	info:=URLDownloadToVar("http://files.maestrith.com/irc/irc.text")
	SplashTextOff
	Gui,Add,Edit,-Wrap w500 h500 hwndhwnd,%info%
	if !(SubStr(info,1,InStr(info,"`r`n")-1)=version)
		Gui,Add,Button,gdownload,Download Update
	Gui,Show,,IRC Version:%version%
	ControlSend,Edit1,^{Home},ahk_id%ver%
	return
	download:
	FileMove,%A_ScriptName%,backup_%a_now%_%A_ScriptName%
	ext:=A_IsCompiled?".exe":".ahk"
	URLDownloadToFile,http://www.maestrith.com/files/irc/irc%ext%,%A_ScriptName%
	MsgBox,17,Reload now?,Reload now? will kick you offline.
	IfMsgBox,Ok
	{
		for a,b in socket.list
			b.disconnect()
		reload
		ExitApp
	}
	return
	4GuiEscape:
	4GuiClose:
	Gui,4:Destroy
	return
}
updatenicks(curchan){
	mm:=chan.search("//channel/@name",curchan)
	for a,b in ["Operator","Voice","Normal"]{
		list:=sn(mm,b "/*")
		while,ll:=list.item(a_index-1)
			userlist.=ssn(ll,"@user").text " "
	}
	Sort,userlist,D%A_Space%
	v.userlist:=userlist
}
compile(info,index=1){
	for a,b in info
		if (A_Index>index)
			msg.=b " "
	return msg
}
display(edit){
	static search:=Chr(1) "ACTION"
	text:=edit.text,time:=time()
	root:=chan.ssn("//*[@socket='" edit.socket.socket "']"),username:=ssn(root,"@user").text
	if InStr(text,search){
		StringReplace,text,text,%search%,,All
		StringReplace,text,text,% Chr(1),,All
		un:="***" edit.user
		ul:=StrLen(un)
	}
	else if edit.user
		un:=user(edit.user),ul:=StrLen(un)
	else
		ul:=0
	cc:=search(root,"channel/@name",edit.chan)
	;t("un-comment this before upload")
	if edit.socket.socket<=0
		return m("Not connected to a server.",edit.socket.socket)
	if !(root){
		d({t:1}),sc:=new s(1,"xm+155 ym w700 h410 Hidden"),name:=edit.socket.name
		add:=TV_Add(edit.socket.name),cc:=chan.add({path:"server",att:{name:name,control:sc.sc,tv:add,socket:edit.socket.socket},dup:1})
		TV_Modify(add,"Select Vis Focus")
		GuiControl,1:+Redraw,SysTreeView321
		tv_redraw(),color(sc),Resize()
	}
	if (cc.xml=""&&edit.chan!=""){
		pos:=InStr(edit.chan,"#")?"xm+155 ym w550 h410 Hidden Section":"xm+155 ym w700 h410 Hidden Section"
		d({t:1}),sc:=new s(1,pos)
		parent:=ssn(root,"@tv").text
		add:=TV_Add(edit.chan,parent),cc:=chan.under({under:root,node:"channel",att:{name:edit.chan,tv:add,control:sc.sc}})
		if InStr(edit.chan,"#"){
			Gui,Add,TreeView,xs+560 ys w140 h410 hidden hwndhwnd c0xffffff gnicktree AltSubmit
			cc.SetAttribute("treeview",hwnd+0)
		}
		tv_redraw(),color(sc),Resize()
	}
	cc:=cc?cc:root,main:=s.ctrl[ssn(cc,"@control").text],end:=main.2006,move1:=getpos(main).move
	if (edit.user){
		ea:=chan.easyatt(ssn(cc,"descendant::user[@user='" edit.user "']"))
		if self:=edit.user=ssn(root,"@user").text?1:0
			style:=3
		else if ea.operator
			style:=4
		else if ea.voice
			style:=5
		else
			style:=6
		main.2032(end?end+2:end,255)
		main.2033(ul,style)
		addtext(main,end?"`r`n" un:un,style)
		stripurl(main,text)
	}
	else
		addtext(main,main.2006?"`r`n" text:text,40)
	;stripurl(main,end?"`r`n" text:text) ;swap this and the one below
	line:=main.2166(main.2006)
	main.2530(line,time),main.2532(line,2)
	main.2171(1)
	if (move1){
		v.Bottom.Insert(main)
		SetTimer,Bottom,100
	}
	tv:=ssn(cc,"@tv").text,d({t:1}),current:=TV_GetSelection()
	if (tv!=current){
		d({t:1}),TV_Modify(tv,"Icon3 Bold"),tv_redraw()
		if (cc.nodename!="server")
			v.newmessage[tv]:=1
	}
	if (WinActive(hwnd([1]))=0&&edit.notice=""&&cc.nodename!="server"&&edit.user&&(InStr(text,username)||InStr(edit.chan,"#")=0)){
		go:=v.TrayTip.1?0:1
		v.traytip.Insert({tv:tv,user:edit.user,message:text})
		if go
			TrayTip()
	}
	if (edit.mark){
		main.2242(1,main.2276(5,"ZZ"))
		main.2040(0,2)
		main.2043(line,0)
	}
	return cc
}
bottom(){
	Bottom:
	SetTimer,Bottom,Off
	for a,main in v.bottom{
		main.2569(main.2006,main.2006)
		v.pos[main.2357]:=main.2006
	}
	v.bottom:=[]
	return
}

nicklist(){
	d({t:2})
	if (A_GuiEvent="rightclick"&&TV_GetParent(A_EventInfo)&&LV_GetNext()){
		TV_GetText(user,A_EventInfo),LV_GetText(channel,LV_GetNext())
		v.sock.Sendtext("chanserv :op " channel " " user)
	}
}
wordchar(){
	index=33
	while,index<127
		letters.=Chr(index++)
	Input.2077(0,letters)
}
svr(channel=""){
	top:=ssn(chan.ssn("//*[@doc='" main.2357 "']"),"ancestor-or-self::*[@socket!='']")
	if !channel
		return top
	bottom:=search(top,"channel/@name",channel)
	return bottom
}
server(option){
	sock:=socket.list[chan.ssn("//server[@name='" SubStr(option,17) "']/@socket").text]
	quit(sock),next:=TV_GetNext(0),d({t:1,w:1}),TV_Modify(next,"Select Vis Focus")
}
toggle_timestamps(){
	for a,main in s.ctrl{
		width:=main.2243(0)
		width:=width?0:main.2276(2,time() "|")
		main.2242(0,width)
	}
	input.2400
}
popaj(srv=""){
	d({t:2}),TV_GetText(sel,TV_GetSelection()),TV_Delete(),expand:=[]
	top:=settings.ssn("//server")
	list:=sn(top,"//*[@name!='']")
	while,ll:=list.item(a_index-1){
		if (ll.nodename="server"){
			ea:=xml.easyatt(ll)
			root:=TV_Add(ea.name)
			if (ea.name=srv)
				last:=root
			for a,b in {Port:ea.port,Username:ea.user,Password:ea.password}{
				child:=TV_Add(a,root),expand.Insert(child)
				if b
					gchild:=TV_Add(a="Password"?RegExReplace(b,"\w","*"):b,child),expand.Insert(gchild)
			}
			root:=TV_Add("Channels",root),expand.Insert(root)
		}
		if ll.nodename="channel"
			TV_Add(ssn(ll,"@name").text,root)
	}
	for a,b in Expand
		TV_Modify(b,"Expand")
	if Last
		TV_Modify(last,"Expand Select Vis")
}
popinfo(){
	d({t:2}),TV_GetText(channel,A_EventInfo),parent:=TV_GetParent(A_EventInfo)
	if (A_GuiEvent="rightclick"&&parent=0){
		if channel
			return menu("connect",["Connect to " channel,"Edit Server List"])
		return menu("connect",["Edit Server List"])
	}
	if (A_GuiEvent="k"&&(A_EventInfo=46||A_EventInfo=8)){
		if !TV_GetParent(TV_GetSelection()){
			MsgBox,4,Are you sure?,Delete this server?
			IfMsgBox,No
				return
			d({t:2}),TV_GetText(cc,TV_GetSelection())
			rem:=settings.ssn("//server/server[@name='" cc "']"),rem.ParentNode.RemoveChild(rem),popaj()
		}
		if (channel="channels"){
			MsgBox,4,Remove Channel?,Remove This Channel?
			IfMsgBox,No
				return
			d({t:2}),TV_GetText(channel,sel:=TV_GetSelection())
			rem:=settings.ssn("//server/channel[@name='" channel "']"),rem.ParentNode.RemoveChild(rem),TV_Delete(sel)
		}
		settings.save(1)
	}
}
server_list(x=""){
	static
	if !(x){
		Gui,2:Destroy
		Gui,2:Default
		Gui,+hwndhwnd +Owner1 +ToolWindow
		hwnd(2,hwnd),controls()
		Gui,2:Default
		Gui,Add,ListView,gpop AltSubmit,Server
		Gui,Add,Text,xm,Server:
		Gui,Add,Edit,x+5 w200 vsrvr,irc.freenode.net 
		Gui,Add,Text,xm,Port:
		Gui,Add,Edit,x+5 w200 vport,6667
		Gui,Add,Text,xm,Username:
		Gui,Add,Edit,x+5 w100 vuser,% v.username
		Gui,Add,Text,xm,Password:
		Gui,Add,Edit,w100 x+10 Password vpassword
		Gui,Add,Text,xm,Channel (One at a time):
		Gui,Add,Edit,w100 x+10 vchannel
		Gui,Add,Button,gupdate Default,Update/Add Server/Channels
		Gui,Show,,Server List
		top:=settings.sn("//server/@name")
		while,tt:=top.item(a_index-1)
			LV_Add("",tt.text)
		return
	}
	update:
	Gui,2:Submit,Nohide
	ControlSetText,Edit5,,% hwnd([2])
	if srvr=""||srv=""
		return m("Please input a server address")
	srvr:=srvr?srvr:srv
	if !(srvr&&port&&user)
		return m("Please make sure to have a server, port and username available")
	if !root:=settings.ssn("//*[@name='" srvr "']")
		root:=settings.add({path:"server/server",att:{name:srvr},dup:1})
	for a,b in {port:port,user:user,password:password}
		if b
			root.SetAttribute(a,b)
	if (channel){
		channel:=InStr(channel,"#")?channel:"#" channel
		if !ssn(root,"channel[@name='" channel "']")
			settings.under({under:root,node:"channel",att:{name:channel}})
	}
	settings.save(1)
	popaj(srvr)
	return
	2GuiClose:
	2GuiEscape:
	destroy(2)
	return
	pop:
	LV_GetText(srvr,LV_GetNext())
	top:=settings.search("//server/@name",srvr)
	ea:=xml.easyatt(top)
	for a,b in {1:"name",2:"port",3:"user",4:"password"}
		ControlSetText,Edit%a%,% ea[b],% hwnd([2])
	return
}
onrecv(sock){
	static store
	store.=sock.recvText()
	pos:=InStr(store,"`r`n",0,0)
	next(SubStr(store,1,pos),sock)
	store:=SubStr(store,pos)
}
nicktree(){
	nicktree:
	if !TV_GetParent(A_EventInfo)
		return
	if (A_GuiEvent="rightclick"){
		d({t:2,w:1}),TV_GetText(nick,A_EventInfo)
		user:=chan.ssn("//*[@tv='" A_EventInfo "']"),self:=ssn(user,"ancestor::server/@user").text
		cc:=ssn(user,"ancestor::channel"),ea:=xml.easyatt(search(cc,"*/user/@user",self)),v.lastuser:=user
		if (ea.operator)
			menu("nick",["OP","DEOP","VOICE","DEVOICE","KICK","WHOIS","BAN"])
		else
			menu("nick",["WHOIS"])
	}
	return
}
quit(sock){
	sock.sendtext("QUIT :" msg(edit,1).2)
	ss:=sock.socket
	sock.disconnect()
	sleep,500
	srvr:=chan.ssn("//*[@socket='" ss "']")
	cc:=sn(srvr,"descendant-or-self::*[@control]")
	while,ccc:=cc.item(a_index-1){
		if (A_Index=1){
			ee:=xml.easyatt(ccc)
			continue
		}
		ea:=xml.easyatt(ccc)
		for a,b in ea
		if WinExist("ahk_id" b){
			WinKill,ahk_id%b%
		}
		d({t:1}),TV_Delete(ea.tv)
		ccc.ParentNode.RemoveChild(ccc)
	}
	d({t:1})TV_Delete(ee.tv)
	for a,b in ee
		if WinExist("ahk_id" b)
			WinKill,ahk_id%b%
	changechan(1)
	srvr.ParentNode.RemoveChild(srvr)
}
getpos(main){
	size:=VarSetCapacity(info,52),NumPut(size,info,0),NumPut(0x7,info,4)
	work:=DllCall("GetScrollInfo","uptr",main.sc,"uint",1,"uptr",&info)
	total:={max:NumGet(info,12),page:NumGet(info,16),pos:NumGet(info,20)}
	total.move:=total.page+total.pos<total.max?0:1
	return total
}
tv_rem(treeview,tv){
	Gui,TreeView,ahk_id%treeview%
	TV_Delete(tv)
	sleep,1
	GuiControl,+Redraw,ahk_id%treeview%
}
tv_redraw(info=""){
	static tick=0
	Gui,1:Default
	info:=info?[info]:["SysTreeView321","SysTreeView322"]
	for a,b in info{
		sleep,5
		GuiControl,1:+Redraw,%b%
	}
}
help(x=0){
	help=
	(
	F1: Show Help (this window)
	F2: Hide/Show caption (window border)
	F3: Hide/Show Server window
	F4: Connect to the currently selected server
	
	For now everything is right click for menus:
	-Right Click on the lower left control to connect to servers or edit the server list
	-Right Click on the upper left control to control the servers/channels
	-Right Click on the message window (this window) for copy options if you have anything selected, or channel/server options depending on what you have in the window currently
	
	Commands:
	-/q or /quit (message) = Quit the server
	-/c or /chanserv (message) = Sends a message to the chanserv
	-/n or /nickserv (message) = Sends a message to the nickserv
	-/nn = Refreshes the nick list
	-/me (message) = Sends an action
	-/i = sends your password to the nickserv to register your nick
	-/away (message) = sets you away with a message and sets you back without
	-/nick (new nickname) = sends a request to the server to chang your nick
	-/raw (message) = sends a raw message to the server
	-/msg or /m (username message) = Sends a private message to a user
	-/p or /part (OPTIONAL channel) = Parts you from the current channel (optional whatever channel you input)
	-/j or join (channel with or without #) = Joins you to the channel
	-/c = Connect
	
	General:
	As long as you set your password it will not allow it to be sent to any channel (public or private)
	
	Keep in mind this is alpha software :)
	
	If you change the font of the plain text it will change the rest of the fonts by default.
	
	-Bold,Italic,and Underline using Ctrl+B,Ctrl+I, and Ctrl+U.  Ctrl+N gets you back to normal text
	Ctrl+K sets colors
	
	License for Scintilla and SciTE
	
	Copyright 1998-2002 by Neil Hodgson <neilh@scintilla.org>
	
	All Rights Reserved 
	
	Permission to use, copy, modify, and distribute this software and its 
	documentation for any purpose and without fee is hereby granted, 
	provided that the above copyright notice appear in all copies and that 
	both that copyright notice and this permission notice appear in 
	supporting documentation. 
	
	NEIL HODGSON DISCLAIMS ALL WARRANTIES WITH REGARD TO THIS 
	SOFTWARE, INCLUDING ALL IMPLIED WARRANTIES OF MERCHANTABILITY 
	AND FITNESS, IN NO EVENT SHALL NEIL HODGSON BE LIABLE FOR ANY 
	SPECIAL, INDIRECT OR CONSEQUENTIAL DAMAGES OR ANY DAMAGES 
	WHATSOEVER RESULTING FROM LOSS OF USE, DATA OR PROFITS, 
	WHETHER IN AN ACTION OF CONTRACT, NEGLIGENCE OR OTHER 
	TORTIOUS ACTION, ARISING OUT OF OR IN CONNECTION WITH THE USE 
	OR PERFORMANCE OF THIS SOFTWARE. 
	)
	;	Ctrl+Down: Jumps to a window with unread messages
	
	StringReplace,help,help,`t,,All
	if x
		return help
	control:=chan.ssn("//startup/@control").text
	hide:=chan.sn("//@control|//@treeview")
	Gui,1:Default
	while,cc:=hide.item(a_index-1){
		if ssn(cc,"..").nodename!="treeview"
			GuiControl,1:Hide,% cc.text
	}
	Gui,1:Default
	GuiControl,1:Show,%control%
	return
	Gui,3:Destroy
	Gui,3:Font,s13
	Gui,3:Add,Edit,-Wrap,%help%
	Gui,3:Show,,Help
	ControlSend,Edit1,^{home},Help
	return
	3GuiEscape:
	3GuiClose:
	destroy(3)
	return
}
URLDownloadToVar(url){
	hObject:=ComObjCreate("WinHttp.WinHttpRequest.5.1")
	hObject.Open("GET",url)
	hObject.Send()
	return hObject.ResponseText
}
tab(){
	tab:
	if (input.2102)
		return input.2104
	ControlGetFocus,focus,% hwnd([1])
	if !InStr(Focus,"Scintilla2")
		return
	cp:=input.2008
	word:=input.textrange(start:=input.2266(cp,0),end:=input.2267(cp,0))
	li:=""
	if (input.2102=0){
		st:=SubStr(word,1,1)
		StringUpper,upper,st
		StringLower,lower,st
		d({t:1}),root:=chan.ssn("//*[@tv='" TV_GetSelection() "']")
		sel:=sn(root,"descendant::user/@user[contains(.,upper)][contains(.,lower)]")
		while,ss:=sel.item(a_index-1)
			if RegExMatch(ss.text,"iA)" st)
				li.=ss.text " "
		if !li
			return
		if !(InStr(Trim(li)," ",0,1,1)){
			input.2160(start,end)
			input.2170(0,Trim(li))
			return
		}
		sort,li,D%A_Space%
		if li
			input.2100(StrLen(word),Trim(li))
	}
	return
}
history(channel,edit){
	static lastkey:=[],keyhistory:=[]
	if !IsObject(keyhistory[channel])
		keyhistory[channel]:=[]
	info:=keyhistory[channel],info.Insert(edit)
	lastkey[channel]:=info.maxindex()+1
	return
	history:
	if input.2006
		return
	if input.2102
		return
	GuiControl,1:-Redraw,Scintilla1
	d({t:1}),TV_GetText(channel,TV_GetSelection())
	info:=keyhistory[channel]
	if !lastkey[channel]
		lastkey[channel]:=info.maxindex()+1
	if InStr(A_ThisHotkey,"Up")&&lastkey[channel]>1
		lastkey[channel]--
	if InStr(A_ThisHotkey,"Down")&&lastkey[channel]<=info.maxindex()
		lastkey[channel]++
	input.2004(),stripurl(input,info[lastkey[channel]])
	sleep,50
	Input.2025(input.2006)
	GuiControl,1:+Redraw,Scintilla1
	return
}
color(b){
	style:=v.style
	bold:=italic:=strikeout:=underline:=0
	ea:=controls()
	background:=settings.ssn("//*[@style='0']/background").text
	Background:=background?background:0
	Gui,1:Default
	if IsObject(b)
		ctrls:=[],ctrls.Insert(b),colors:=sn(v.ctxml,"*")
	else
		ctrls:=s.ctrl.clone(),colors:=sn(v.ctxml,"descendant::style[@style='" b "']"),ctrls.insert(input)
	if (b="back"){
		colors:=ssn(v.ctxml,"descendant::style[@style='0']/@background").text
		for a,b in ctrls
			Loop,255
				b.2052(A_Index-1,colors)
		return
	}
	Default:=settings.ea("//*[@style='0']")
	if !default.background
		default.background:=0
	while,cc:=colors.item(a_index-1){
		ea:=xml.easyatt(cc),offset:=A_Index
		for a,b in default
			if !ea[a]
				ea[a]:=b
		for a,b in ea
			%a%:=b
		for a,b in ctrls{
			ii:=A_Index
			b.2052(33,Background)
			if ea.style=0
				b.2052(32,background),b.2051(32,color),ea.style:=40
			b.2056(ea.style,font),b.2051(ea.style,color),b.2055(ea.style,size),b.2052(ea.style,Background)
			if ea.style=0||ea.style=2
				b.2242(0,b.2276(ea.style,v.time))
			b.2242(0,b.2276(2,time() "|"))
			if ea.style=1
				b.2409(1,1),b.2059(1,1)
			for e,f in {0:40,1:41,2:42,3:43,4:44,5:45,6:46,7:47}
			{
				b.2056(f,default.font),b.2051(f,default.color),b.2055(f,default.size),b.2052(f,default.Background)
				for c,d in {1:2054,2:2053,4:2059}
					if (e&c)
						b[d](f,1)
			}
		}
	}
	input.2242(0,0)
	ToolTip,% lili,0,0,3
	main:=theme(1)
	if (main.sc){
		Loop,20
			main.2409(A_Index-1,1)
	}
}
rgb(c){
	setformat,IntegerFast,H
	c:=(c&255)<<16 | (c&65280) | (c>>16),c:=SubStr(c,1)
	SetFormat, integerfast,D
	return c
}
Dlg_Font(ByRef Style,Effects=1,window=""){
	VarSetCapacity(LOGFONT,60),strput(style.font,&logfont+28,32,"CP0")
	LogPixels:=DllCall("GetDeviceCaps","uint",DllCall("GetDC","uint",0),"uint",90),Effects:=0x041+(Effects?0x100:0)
	for a,b in font:={16:"bold",20:"italic",21:"underline",22:"strikeout"}
		if style[b]
			NumPut(b="bold"?700:1,logfont,a)
	style.size?NumPut(Floor(style.size*logpixels/72),logfont,0):NumPut(16,LOGFONT,0)
	VarSetCapacity(CHOOSEFONT,60,0),NumPut(60,CHOOSEFONT,0),NumPut(&LOGFONT,CHOOSEFONT,12),NumPut(Effects,CHOOSEFONT,20),NumPut(style.color,CHOOSEFONT,24),NumPut(window,CHOOSEFONT,4)
	if !r:=DllCall("comdlg32\ChooseFontA", "uint",&CHOOSEFONT)
		return
	Color:=NumGet(CHOOSEFONT,24)
	bold:=NumGet(LOGFONT,16)>=700?1:0
	style:={size:NumGet(CHOOSEFONT,16)//10,font:StrGet(&logfont+28,"CP0"),color:color}
	for a,b in font
		style[b]:=NumGet(LOGFONT,a,"UChar")?1:0
	style["bold"]:=bold
	return 1
}
/*
	0=Normal
	1=Bold
	2=Italic
	3=Bold+Italic
	4=Underline
	5=Bold+Underline
	6=Italic+Underline
	7=Bold+Italic+Underline
	color*8+state+offset(40)=style
	marker offset(10)
*/
release(x=""){
	MouseGetPos,,,,con
	if (InStr(con,"Scintilla")=0||InStr(con,"Scintilla1")=1)
		return
	MouseGetPos,,,,con,2
	main:=s.ctrl[con+0]
	pos:=cp(main)
	if pos.end-pos.start=0
		return
	text:=format(main,pos.start,pos.end)
	main.2572(pos.start,pos.start)
	if x
		return text
	stripurl(input,text)
}
connect(option){
	server:=SubStr(option,12)
	ea:=settings.ea("//server[@name='" server "']"),v.login:=[]
	for a,b in {1:"name",2:"port",3:"user",4:"password"}
		v.login[b]:=ea[b]
	if !(v.login.name)
		return server_list()
	if select:=chan.search("//server/@name",v.login.name){
		MsgBox,20,Already Connected!,You are already connected to this server. Open another connection?
		d({t:1})
		IfMsgBox,No
			return TV_Modify(ssn(select,"@tv").text,"Select Vis Focus")
	}
	sock:=new SocketTCP()
	sock.onRecv:=Func("onrecv")
	sock.connect(v.login.name,v.login.port),focus()
	sock.sn:=v.login.name,sock.tv:=add,sock.num:=v.count
	if sock.socket<=0
		return m("can not be located",sock.socket)
	new.SetAttribute("socket",sock.socket)
	username:=v.login.user
	sock.Sendtext("NICK " username)
	sock.Sendtext("USER " username " 0 * :" username)
	WinSetTitle,%A_ScriptName%,,AHK IRC - %username%
	v.sock:=sock
	return
	connect:
	d({t:2}),TV_GetText(server,TV_GetSelection())
	connect("connect to " server)
	return
}
resize(a="",b="",c="",d=""){
	static pos:=[]
	if (A_Gui=1||a.1||a=""){
		width:=b&0xffff,height:=b>>16
		width:=a.1?a.1:width,height:=a.2?a.2:height
		width:=width?width:pos.w,height:=height?height:pos.h
		if (v.hide)
			offset:=5
		else
		{
			offset:=v.left+10
			GuiControl,1:move,SysTreeView321,% "h" height-175 " w" v.left
			GuiControl,1:move,SysTreeView322,% "y" height-165 " w" v.left
		}
		ch:=input.2279(0)+5
		GuiControl,1:move,% input.sc,% "x" offset " y" height-ch-10 " w" Width-offset-5 " h" ch
		cl:=chan.sn("//server|//channel|//startup")
		Gui,1:Default
		while,cc:=cl.item(a_index-1){
			ea:=xml.easyatt(cc)
			if cc.nodename="server"||cc.nodename="startup"
				GuiControl,1:move,% ea.control,% "x" offset " w" width-offset-5 " y5 h" height-ch-20
			if (cc.nodename="channel"){
				ww:=InStr(ea.name,"#")?width-offset-v.right-10:width-offset-5
				GuiControl,1:Move,% ea.control,% "x" offset " w" ww " y5 h" height-ch-20
				Gui,1:Default
				if InStr(ea.name,"#")
					GuiControl,1:Move,% ea.TreeView,% " x" offset+ww+5 " h" height-ch-20 " w" v.right
			}
		}
		WinGet,style,style,% hwnd([A_Gui])
		if width&&height&&a!=2&&(style&0x40000||style&0x40000=""){
			pos.w:=width,pos.h:=height
			if !size:=settings.ssn("//gui/window[@window='1']")
				size:=settings.add({path:"gui/window",att:{window:1},dup:1})
			for a,b in {width:pos.w,height:pos.h,maximize:0}
				size.SetAttribute(a,b)
		}
		if width&&height&&a!=2
			pos.w:=width,pos.h:=height
		if a=2
			size:=settings.ssn("//gui/window[@window='1']").SetAttribute("maximize",1)
	}
}
endmove(a,b,c,d){
	WinGetPos,x,y,,,% hwnd([1])
	if !size:=settings.ssn("//gui/window[@window='1']")
		size:=settings.add({path:"gui/window",att:{window:1},dup:1})
	for a,b in {x:x,y:y}
		size.SetAttribute(a,b)
	return 0
}
theme(x=0){
	static main
	if x
		return main
	if !hwnd(5){
		Gui,5:Destroy
		Gui,5:+Owner1 +hwndhwnd
		hwnd(5,hwnd),controls()
		Gui,5:Add,Text,xm,Time Format ($h:$m:$s.$ss):
		Gui,5:Add,Edit,x+5 w200 gtimeformat,% v.time
		Gui,5:Add,Text,xm,Username Format <$u> :
		Gui,5:Add,Edit,x+5 w200 guserformat,% v.uformat
		Gui,5:Add,ListView,xm w200 h300 c0xffffff,Themes
		main:=new s(5,"x+5 w300 h300"),v.tt:=main
		Menu,theme,Add,Background,Background
		Gui,5:Menu,theme
		Gui,5:Show,,Theme
		pos:=0
		color(main),poptheme(main)
		main.2246(0,1),main.2242(0,main.2276(2,time() " ")),v.theme:=main.sc
		Gui,5:Default
		LV_Add("","Future use")
		Gui,1:Default
	}
	else
		WinShow,% hwnd([5])
	;hotspot()
	return
	Background:
	v.ctxml:=settings.ssn("//theme[@name='" v.ctheme "']")
	color:=ssn(v.ctxml,"descendant::style[@style='0']")
	clr:=dlg_color(ssn(color,"@background").text,hwnd(5))
	color.SetAttribute("background",clr),settings.save(1),color("back")
	return
	userformat:
	ControlGetText,uformat,Edit2,% hwnd([5])
	settings.add({path:"user",text:RegExReplace(uformat," $","a_space")})
	v.uformat:=uformat
	poptheme(main),settings.save(1)
	return
	timeformat:
	ControlGetText,time,Edit1,% hwnd([5])
	settings.add({path:"time",text:RegExReplace(time," $","a_space")})
	v.time:=time
	main.2530(0,time())
	main.2242(0,main.2276(2,time() " "))
	return
	5GuiClose:
	5GuiEscape:
	Gui,5:Hide
	return
}
style(main,text,style,hotspot=0){
	main.2171(0),end:=main.2006,text:=end?"`r`n" text:text,main.2003(end,text)
	main.2409(style,hotspot),main.2032(end,255),main.2033(StrLen(text),style),main.2171(1)
}
ccolor(style,color){
	style:=style=40?0:style
	color:=dlg_color(color,hwnd(5)),font:=ssn(v.ctxml,"descendant::style[@style='" style "']"),font.SetAttribute("color",color),color(style),resize()
	sleep,100
	;hotspot()
}
cfont(style){
	style:=style=40?0:style
	v.ctxml:=settings.ssn("//theme[@name='" v.ctheme "']")
	for a,b in [0,style]
		font%A_Index%:=xml.ea(ssn(v.ctxml,"descendant::style[@style='" b "']"))
	for a,b in font2
		font1[a]:=b
	if !dlg_font(font1,1,hwnd(1))
		return
	change:=ssn(v.ctxml,"descendant::style[@style='" style "']")
	for a,b in font1
		change.SetAttribute(a,b)
	v.ctxml:=settings.ssn("//theme[@name='" v.ctheme "']")
	if style=0
		Loop,7
			color(A_Index-1)
	else
		color(style)
	resize(),settings.save(1)
	sleep,100
}
hotspot(){
	main:=theme(1)
	Loop,20
		main.2409(A_Index-1,1)
}
poptheme(main){
	main.2004
	style(main,"Left click to change the color`r`n`r`nControl+Left click to change the font`r`n`r`nShift+Click to remove the font style from any BUT the plain text`r`n`r`nThis is an example of plain text",40,1)
	style(main,user("Your Username"),3,1),style(main,user("Operator Username"),4,1),style(main,user("Voice Username"),5,1),style(main,user("Normal Username"),6,1)
	style(main,"URL=www.google.com",1,1),main.2530(0,time()),main.2532(0,2)
}
showhide_server(){
	v.hide:=v.hide?0:1
	hide:=v.hide?"Hide":"Show"
	Loop,2
		GuiControl,1:%Hide%,SysTreeView32%A_Index%
	resize()
	return
}
Dlg_Color(Color,hwnd){
	static
	if !cc{
		VarSetCapacity(cccc,16*A_PtrSize,0),cc:=1,size:=VarSetCapacity(CHOOSECOLOR,9*A_PtrSize,0)
		Loop,16{
			IniRead,col,color.ini,color,%A_Index%,0
			NumPut(col,cccc,(A_Index-1)*4,"UInt")
		}
	}
	NumPut(size,CHOOSECOLOR,0,"UInt"),NumPut(hwnd,CHOOSECOLOR,A_PtrSize,"UPtr")
	,NumPut(Color,CHOOSECOLOR,3*A_PtrSize,"UInt"),NumPut(3,CHOOSECOLOR,5*A_PtrSize,"UInt")
	,NumPut(&cccc,CHOOSECOLOR,4*A_PtrSize,"UPtr")
	ret:=DllCall("comdlg32\ChooseColorW","UPtr",&CHOOSECOLOR,"UInt")
	WinActivate,% hwnd([5])
	if !ret
		exit
	Loop,16
		IniWrite,% NumGet(cccc,(A_Index-1)*4,"UInt"),color.ini,color,%A_Index%
	IniWrite,% Color:=NumGet(CHOOSECOLOR,3*A_PtrSize,"UInt"),color.ini,default,color
	return Color
}
time(){
	time:=v.time
	for a,b in {"\$h":A_Hour,"\$m":A_Min,"\$s":A_Sec,"\$ss":A_MSec}
		time:=RegExReplace(time,a "\b",b)
	return time
}
user(name){
	user:=v.uformat
	return RegExReplace(user,"\$u",name)
}
hotkey(){
	CoordMode,Mouse,Screen
	Hotkey,IfWinActive,% hwnd([1])
	Hotkey,F1,help,On
	Hotkey,F2,caption,On
	Hotkey,F3,showhideserver,On
	Hotkey,F4,connect,On
	Hotkey,Tab,Tab,On
	Hotkey,~Up,history,On
	Hotkey,~Down,history,On
	Hotkey,^Down,unread,On
	Hotkey,^b,bold,On
	Hotkey,^u,underline,On
	Hotkey,^i,italic,On
	Hotkey,*Enter,Enter,On
	Hotkey,^k,color,On
	Hotkey,^n,Normal,On
	Hotkey,Alt,deadend,On
	return
	showhideserver:
	showhide_server()
	return
	deadend:
	destroy(10)
	return
}
movewin(a,b,c,d){
	if (A_Gui!=1)
		return
	CoordMode,Mouse,Screen
	MouseGetPos,x,y,,con
	if !(con){
		WinGetPos,wx,wy,w,h,% hwnd([1])
		offset:=[]
		offset.x:=wx-x,offset.y:=wy-y
		while,GetKeyState("LButton","P"){
			mousegetpos,x,y
			WinMove,% x+offset.x,% y+offset.y
		}
	}
}
formats(){
	time:=settings.ssn("//time").text,user:=settings.ssn("//user").text
	for a,b in ["user","time"]
		%b%:=RegExReplace(%b%,"i)a_space"," ")
	v.time:=time?time:"[$h:$m:$s]",v.uformat:=user?user:"<$u> "
	left:=settings.ssn("//left").text,right:=settings.ssn("//right").text
	v.left:=left?left:150,v.right:=right?right:160
}
Resize_windows(){
	static left,right,w
	SysGet,Border,32
	Gui,1:+Disabled
	Gui,6:Destroy
	Gui,6:Color,0,0
	Gui,6:Margin,0,0
	Gui,6:-Caption -Resize +hwndhwnd +Owner1
	hwnd(6,hwnd)
	controls()
	ControlGetPos,cx,,cw,,SysTreeView321,% hwnd([1])
	WinGetPos,x,y,w,h,% hwnd([1])
	Gui,6:Add,Text,,Left set
	range:=w:=w-(border*2)
	wid:=range+(border*2)
	Gui,6:Add,Slider,x-%border% w%wid% Range0-%range% gleft vleft AltSubmit,% v.left
	Gui,6:Add,Text,xm,Right set
	Gui,6:Add,Slider,x-%border% w%wid% Range-%range%-0 gright vright AltSubmit,% -v.right
	Gui,6:Add,Button,gclose,Close
	Gui,6:Show,% "x" x+border " y" y+(h/2) " w" w
	return
	close:
	6GuiEscape:
	Gui,1:-Disabled
	destroy(6)
	return
	left:
	Gui,6:Submit,Nohide
	v.left:=left
	settings.add({path:"left",text:v.left})
	resize()
	return
	right:
	Gui,6:Submit,Nohide
	v.right:=Abs(right)
	settings.add({path:"right",text:v.right})
	resize()
	return
}
TrayTip(a*){
	if !(a.1){
		TrayTip,% v.TrayTip.1.user,% v.TrayTip.1.message,3
	}
	if (a.2=1028&&a.4=A_ScriptHWND){
		v.traytip.remove(1)
		TrayTip,% v.TrayTip.1.user,% v.TrayTip.1.message,3
	}
	if (a.2=1029&&a.4=A_ScriptHWND){
		tv:=v.TrayTip.1.tv,list:=[]
		remove:
		for a,b in v.TrayTip
		if (b.tv=tv){
			v.TrayTip.remove(a)
			goto remove
		}
		d({t:1,w:1}),TV_Modify(tv,"Select Vis Focus")
		WinActivate,% hwnd([1])
		if v.traytip.1
			TrayTip,% v.TrayTip.1.user,% v.TrayTip.1.message,3
	}
	return
}
whois(info){
	static userlist:=[],lastuser
	if !(hwnd(8)){
		Gui,8:Default
		Gui,+hwndhwnd +Owner1
		hwnd(8,hwnd),controls()
		Gui,8:Default
		Gui,Add,ListView,w300 h300 AltSubmit gshowuser,Username
		Gui,Add,Edit,x+10 w300 h300
		Gui,1:Default
	}
	if (info="show"){
		Gui,8:Show,,Whois
		return
	}
	if (info.in.2=311){
		d({l:1,w:8})
		Gui,8:Default
		lastuser:=info.msg
		if !IsObject(userlist[info.msg]){
			LV_Add("",info.msg)
			userlist[info.msg]:=[]
		}
		d({t:1,w:1})
		Gui,1:Default
	}
	if (info.in.2=319)
		userlist[lastuser,"Channels"]:=info.msg " "
	if (info.in.2=312)
		userlist[lastuser,"Server"]:=info.in.5 " - " info.msg
	if (info.in.2=317)
		userlist[lastuser,"Seconds Idle"]:=info.in.5,userlist[lastuser,"Sign-on Time"]:=info.in.6
	if (info.in.2=330)
		userlist[lastuser,"Logged In As"]:=info.in.5
	if (info.in.2=318){
		lastuser:=""
		Gui,8:Show,,Whois
		Gui,1:Default
	}
	return
	8GuiEscape:
	8GuiClose:
	Gui,8:Hide
	return
	showuser:
	LV_GetText(user,LV_GetNext()),info:=""
	for a,b in userlist[user]
		info.=a " = " b "`r`n"
	ControlSetText,Edit1,%info%,% hwnd([8])
	return
}
addtext(main,text,style,indic=""){
	main.2171(0),end:=main.2006,main.2282(StrLen(text),[text])
	main.2032(end,255),main.2033(StrLen(text),style)
	if indic between -1 and 16
		main.2500(indic),main.2504(InStr(end,"`r`n")?end+2:end,StrLen(text))
	if (main.sc!=input.sc)
		main.2171(1)
	return end
}
format(main,index=0,end=0){
	static back:={1:0,2:1,4:2,8:3,16:4,32:5,64:6,128:7,256:8,512:9,1024:10,2048:11,4096:12,8192:13,16384:14,32768:15}
	Default:=0,list:=0,color:=""
	count:=end?end-index:main.2006
	Loop,% count
	{
		pos:=a_index-1+index
		next:=main.2010(pos),next:=next<0?next+256:next
		chr:=main.2007(pos),chr:=chr=0?0:Chr(chr)
		color:=floor((next-48)/8)
		color:=color<=0?"":color
		style:=Mod(next,8),bstyle:=""
		bcolor:=back[main.2506(pos)]
		if (lastcolor!=color&&color="")
			total.=Chr(3) ,flan.=Chr(3)
		if (style!=laststyle){
			if laststyle
			for a,b in {1:29,2:2,4:31}{
				if (style&a!=laststyle&a)
					total.=chr(b) ,flan.="(code" b ")"
			}
			else
			for a,b in {1:29,2:2,4:31}{
				if style&a
					total.=Chr(b) ,flan.="(code" b ")"
			}
		}
		if (next=40&&(lastcolor!=""||lastbcolor!="")){
			lastcolor:=bcolor:=""
			total.=Chr(15) chr ,flan.="CODE15" chr
			continue
		}
		else if (next>47){
			if ((color!=lastcolor)||(bcolor!=lastbcolor))
				cc:=bcolor!=""?"," bcolor:"",total.=Chr(3) color cc chr ,flan.=chr(3) color cc chr
			else
				total.=chr ,flan.=chr
		}
		else
			total.=chr ,flan.=chr
		laststyle:=style,lastcolor:=color,lastbcolor:=bcolor
	}
	v.cstyle:=40,v.cbackground:=""
	sleep,1
	return total
}
command(word){
	/*
		if InStr(word,"/s"){
		Input.2004
		list:=settings.sn("//server/server/@name")
		while,ll:=list.item(a_index-1)
		total.=ll.text " "
		input.2117(1,Trim(total))
		v.connect:=1
		}
	*/
}
addstyles(main,color){
	if !IsObject(v.addedstyles)
		v.addedstyles:=[]
	if color=""
		return
	cc:=v.dcolors[color],offset:=(color*8)+48,ea:=settings.ea("//style[@style='0']")
	main.2051(offset,cc),main.2056(offset,ea.font),main.2052(offset,ea.background),main.2055(offset,ea.size)
	Loop,7
	{
		total:=A_Index
		main.2051(offset+total,cc),main.2056(offset+total,ea.font),main.2052(offset+total,ea.background),main.2055(offset+total,ea.size)
		for c,d in {1:2054,2:2053,4:2059}
			if (total&c)
				main[d](offset+total,1),v.addedstyles.Insert(offset+total)
	}
}
color_codes(){
	static codes:="0 white`r`n1 black`r`n2 blue (navy)`r`n3 green`r`n4 red`r`n5 brown (maroon)`r`n6 purple`r`n7 orange (olive)`r`n8 yellow`r`n9 light green (lime)`r`n10 teal (a green/blue cyan)`r`n11 light cyan (cyan) (aqua)`r`n12 light blue (royal)`r`n13 pink (light purple) (fuchsia)`r`n14 grey`r`n15 light grey (silver)"
	static color:=6,background:=1
	color:
	InputBox,color,Forground Color,%codes%,,,400,,,,,%color%
	if ErrorLevel
		return
	if color not between 0 and 15
	{
		m("Please enter a value between 0 and 15")
		return
	}
	InputBox,Background,Background Color,%codes%,,,400,,,,,%Background%
	if color not between 0 and 15
	{
		m("Please enter a value between 0 and 15")
		return
	}
	if ErrorLevel
		Background:=""
	addstyles(input,color)
	pos:=cp(input)
	if (pos.start=pos.end)
		v.cstyle:=(color*8)+48
	if (pos.start!=pos.end)
		loop,% pos.end-pos.start
		{
			position:=A_Index-1+pos.start
			stylestart:=input.2010(position)<0?input.2010(position)+256:input.2010(position)
			style:=mod(stylestart,8)
			stylestart:=(color*8)+48+style
			input.2032(position,255)
			input.2033(1,stylestart)
		}
	if Background!=""
		v.cbackground:=Background
	input.2500(background),input.2504(pos.start,pos.end-pos.start)
	return
}
cp(main){
	start:=main.2008,end:=main.2009
	if (start<end)
		return {start:start,end:end}
	return {start:end,end:start}
	
}
enter(){
	enter:
	input.2101
	send(format(input))
	input.2004(),input.2025(0)
	return
	copytext:
	if InStr(A_ThisMenuItem,"Clipboard")
		Clipboard:=release(1)
	else
		release()
	return
}
formattext(){
	static add:={italic:1,bold:2,underline:4}
	bold:
	underline:
	italic:
	normal:
	pos:=cp(input)
	aa:=add[A_ThisLabel]
	if (A_ThisLabel="normal"){
		input.2032(pos.start,255)
		input.2033(pos.end-pos.start,0)
		v.cstyle:=40,v.cbackground:=""
		input.2505(pos.start,pos.end-pos.start)
		return
	}
	else if (pos.start!=pos.end){
		loop,% pos.end
		{
			if (A_Index-1<pos.start)
				continue
			stylestart:=input.2010(A_Index-1)<0?input.2010(A_Index-1)+256:input.2010(A_Index-1)
			style:=stylestart&aa?stylestart-aa:stylestart|aa
			input.2032(A_Index-1,255)
			input.2033(1,style)
		}
		return
	}
	if (v.cstyle&aa)
		v.cstyle-=aa
	else
		v.cstyle|=aa
	return
}
in(var,list){
	if var in %list%
		return 1
	else
		return 0
}
whoreply(sock,msg){
	v.lastsock:=sock
	if !WinExist(hwnd([7]))
		ban(sock,msg)
}
ban(sock,msg){
	static
	d({t:1}),TV_GetText(channel,TV_GetSelection())
	Gui,7:+hwndhwnd
	hwnd(7,hwnd)
	Gui,7:Default
	last:=[["Nickname",msg.3,"nickname"],["Real Name",RegExReplace(msg.5,"$(\W+)"),"realname"],["Host",msg.6,"hostname"]]
	for a,b in last{
		Gui,Add,Text,xm Section,% b.1
		Gui,Add,Edit,x+5 ys-2 w300,% b.2
	}
	Gui,Add,Text,,How do you want to ban this person?
	Gui,Add,Checkbox,xm Checked vNick,Nickname
	Gui,Add,Checkbox,x+5 vreal,Real Name
	Gui,Add,Checkbox,x+5 vhost,Host
	Gui,Add,Button,xm gban,Ban User
	Gui,Show,,Ban
	return
	7GuiEscape:
	7GuiClose:
	destroy(7)
	return
	ban:
	Gui,7:Submit
	mask:=""
	for a,b in [1,2,3]{
		ControlGetText,out,Edit%b%,% hwnd([7])
		last[a].2:=out
	}
	for a,b in [[nick,""],[real,"!"],[host,"@"]]{
		add:=b.1?b.2 last[A_Index].2:b.2 "*"
		mask.=add
	}
	v.lastsock.sendtext("MODE " channel " +b " mask)
	goto 7GuiClose
	return
}
manage_channel(){
	d({t:1}),tv:=TV_GetSelection(),TV_GetText(channel,tv)
	if !tv
		return m("Please connect to a server")
	cc:=chan.ssn("//*[@tv='" tv "']")
	if (cc.nodename!="channel")
		return m("Please select a channel in the server list")
	if !InStr(channel,"#")
		return m("You can not manage private chats.")
	sock:=socket.list[chan.ssn("//*[@tv='" tv "']/ancestor-or-self::*/@socket").text]
	SplashTextOn,200,50,Please wait,Getting information from the server.
	sock.sendtext("MODE " channel " +b")
	if !WinExist(hwnd([9])){
		Gui,9:Default
		Gui,+hwndhwnd
		hwnd(9,hwnd)
		Gui,Add,ListView,w500 h300,Banned User|By|When
		Gui,Add,Button,gmcrem,Remove From List
	}
	Gui,9:Default
	LV_Delete()
	return
	9GuiEscape:
	9GuiClose:
	Gui,9:Hide
	return
	mcrem:
	d({t:1}),tv:=TV_GetSelection()
	channel:=chan.ssn("//*[@tv='" tv "']/@name").text
	sock:=socket.list[chan.ssn("//*[@tv='" tv "']/ancestor-or-self::*/@socket").text]
	Gui,9:Default
	if !next:=LV_GetNext()
		return
	LV_GetText(mask,next)
	sock.sendtext("MODE " channel " -b " mask)
	LV_Delete(next)
	return
}
buildbanlist(in){
	if (in="show"){
		Gui,9:Show,,Manage Channel
		SplashTextOff
		return
	}
	diff:=a_now
	diff-=a_nowUTC,h
	now:=19700101000000
	now+=in.7,s
	now+=diff,h
	formattime,when,%now%,(hh:mm:sstt - MM-dd-yyyy)
	Gui,9:Default
	LV_Add("",in.5,in.6,when)
	Loop,3
		LV_ModifyCol(A_Index,"AutoHDR")
}
menu(last,info){
	static lastmenu,hwnd,lv
	lastmenu:=last
	if !(hwnd){
		Gui,menu:+hwndhwnd -Caption +Owner1
		Gui,menu:Default
		ea:=settings.ea("//theme[@name='" v.ctheme "']/style[@style='0']"),Background:=ea.Background?ea.Background:0
		Gui,Color,% RGB(ea.Background),% RGB(ea.Background)
		Gui,Font,% "s" ea.size " c" RGB(ea.color),% ea.font
		Gui,Margin,0,0
		Hotkey,IfWinActive,ahk_id%hwnd%
		Hotkey,~Enter,menuenter,On
		Hotkey,Alt,deadend,On
		r:=info.MaxIndex()
		Gui,Add,ListView,gmenu AltSubmit hwndlv -Hdr,Menu
	}
	Gui,menu:Default
	LV_Delete()
	for a,b in info
		LV_Add("",b)
	count:=LV_GetCount()
	MouseGetPos,x,y
	LV_ModifyCol(1,"Auto")
	VarSetCapacity(rect,16),NumPut(3,rect,0)
	SendMessage,0x1000|14,0,&rect,,ahk_id%lv%
	VarSetCapacity(point,16)
	SendMessage,0x1000|16,0,&point,,ahk_id%lv%
	offset:=NumGet(point,0)
	left:=NumGet(rect,0),top:=NumGet(rect,4),right:=NumGet(rect,8),bottom:=NumGet(rect,12)
	height:=bottom-top,width:=right-left
	width+=offset*2
	height:=(count)*(height)+4
	ControlMove,,,,%width%,% height,ahk_id%lv%
	x:=x+width>A_ScreenWidth?A_ScreenWidth-width:x
	SysGet,Mon2,Monitorworkarea,%A_Gui%
	y:=y+height>Mon2Bottom?Mon2Bottom-height:y
	LV_Modify(1,"Select Vis Focus")
	Gui,Show,% "x" x " y" y " w" width " h" height
	Gui,1:Default
	return
	menuenter:
	Gui,menu:Default
	if !LV_GetNext()
		LV_Modify(1,"Select Vis Focus")
	Menu:
	sleep,1
	if (A_GuiEvent=="f"){
		Gui,menu:Hide
		return
	}
	if (A_GuiEvent!="Normal"&&A_ThisLabel="Menu")
		return
	Gui,menu:Default
	LV_GetText(option,LV_GetNext())
	Gui,Menu:Hide
	%lastmenu%(option)
	menuGuiEscape:
	Gui,menu:Hide
	return
}
controls(win=""){
	ea:=settings.ea("//theme[@name='" v.ctheme "']/style[@style='0']"),Background:=ea.Background?ea.Background:0
	if win
		hwnd:=[],hwnd[win]:=1
	else
		hwnd:=hwnd({all:1})
	for a,b in hwnd{
		Gui,%a%:Default
		Gui,%a%:Color,% RGB(Background),% RGB(Background)
		WinGet,cl,ControlList,% hwnd([a])
		Loop,Parse,cl,`n
		if !InStr(A_LoopField,"Scintilla"){
			Gui,%a%:Font,% "Normal" " c" RGB(ea.color) " s" ea.size " " style,% ea.font
			GuiControl,% a ":+background" RGB(Background) " c" rgb(ea.color),% A_LoopField
			GuiControl,%a%:font,% A_LoopField
		}
		Gui,%a%:Font,% "Normal" " c" RGB(ea.color) " s" ea.size " " style,% ea.font
	}
	return ea
}
nick(action){
	static control:={op:"+o",deop:"-o",voice:"+v",devoice:"-v"}
	lastuser:=v.lastuser
	user:=ssn(lastuser,"@user").text,channel:=ssn(lastuser,"ancestor::channel/@name").text
	sock:=socket.list[ssn(lastuser,"ancestor::server/@socket").text]
	if (switch:=control[action]){
		sock.sendtext("MODE " channel " " switch " " user)
	}
	else if (action="ban"){
		sock.sendtext("WHO " user)
	}
	else if (action="kick"){
		InputBox,reason,%action%,Reason?
		reason:=reason?user " :" reason:user
		sock.sendtext(action " " channel " " reason)
	}
	else if (action="whois"){
		sock.sendtext("WHOIS " user)
		whois("show")
	}
	return
}
channel(option){
	d({t:1}),tv:=TV_GetSelection()
	root:=chan.ssn("//*[@tv='" v.eventinfo "']"),ea:=xml.ea(root)
	sock:=socket.list[chan.ssn("//*[@tv='" v.eventinfo "']/ancestor-or-self::*/@socket").text]
	if InStr(ea.name,"#")
		sock.sendtext("PART " ea.name),d({t:1,w:1}),TV_Modify(ssn(root,"@tv").text,"Select Vis Focus")
	else
	{
		WinKill,% "ahk_id" ea.control
		d({t:1,w:1}),TV_Delete(ea.tv),TV_Modify(ssn(root.ParentNode,"@tv").text,"Select Vis Focus"),root.ParentNode.RemoveChild(root)
		tv_redraw()
	}
}
deadend(a,b,c,d){
	return d
}
rbutton(a,b,c,d){
	if main:=s.ctrl[d]{
		control:=chan.ssn("//*[@control='" d "']")
		pos:=cp(main),v.main:=main
		if (control.nodename="channel"){
			list:=pos.start=pos.end?["Manage Channel","Theme"]:["Copy Text to Clipboard","Insert Text Into Edit Area","Manage Channel","Theme"]
			menu("chancontrol",list)
		}
		else
			menu("g",["Server List","Check for Update","Theme"])
	}
	return d
}
chancontrol(option){
	if (option=="Theme")
		return theme()
	if InStr(option,"manage")
		return manage_channel()
	main:=v.main
	pos:=cp(main)
	if InStr(option,"insert text")
		return stripurl(input,format(main,pos.start,pos.end))
	Clipboard:=main.textrange(pos.start,pos.end)
}
g(option){
	option:=RegExReplace(option,"\W","_")
	%option%()
}
destroy(win){
	sleep,100
	if !WinExist(hwnd([win]))
		return
	Gui,%win%:Destroy
	hwnd({rem:win})
}