' sIniDir 为初始化目录
' sFilter 为文件后缀 示例："*.*,*.txt"
Function GetFileDlgEx(sIniDir, sFilter, sTitle)
    sIniDir = Replace(sIniDir, "\", "\\")
    ' Set regex = New RegExp
    Set regex = CreateObject("VBScript.RegExp")
    regex.Global = True
    regex.MultiLine = True
    regex.Pattern = ";|\|"
    sFilter = regex.Replace(sFilter, ",")
    DIM sf
    For Each i In Split(sFilter, ",")
        sf = sf & i & "|" & i & "|"
    Next
    sFilter = sf
    hta="""about:<object id=d classid=clsid:3050f4e1-98b5-11cf-bb82-00aa00bdce0b></object>" & _
    "<script>moveTo(0,-9999);" & _
    "eval(new ActiveXObject('Scripting.FileSystemObject').GetStandardStream(0)" & _
    ".Read("&Len(sIniDir)+Len(sFilter)+Len(sTitle)+41&"));" & _
    "function window.onload(){" & _
    "var p=/[^\0]*/;" & _
    "new ActiveXObject('Scripting.FileSystemObject').GetStandardStream(1)" & _
    ".Write(p.exec(d.object.openfiledlg(iniDir,null,filter,title)));" & _
    "close();" & _
    "}</script><hta:application showintaskbar=no />"""
    Set oDlg = CreateObject("WScript.Shell").Exec("mshta.exe " & hta) 
    oDlg.StdIn.Write "var iniDir='" & sIniDir & "';var filter='" & sFilter & "';var title='" & sTitle & "';" 
    GetFileDlgEx = oDlg.StdOut.ReadAll 
End Function

Function LoadingDialog(envType)
    '在HTA中动态创建脚本加载变量 jerryHtml_env 的内容（需要压缩代码为一行）
    myHtml="mshta javascript:""<HTA:Application scroll='no' minimizeButton='no' maximizeButton='no' contextMenu='No' showInTaskbar= 'yes' sysMenu= 'no' selection='no'><html><body><div class=loading id=content style='text-align:center;margin: 20% auto'>正在执行解压！</div></body><script>resizeTo(300, 200);document.title = ' ';var wsh=new ActiveXObject('WScript.Shell');var script = document.createElement('SCRIPT');script.text=wsh.Environment('"&envType&"').Item('script');document.body.appendChild(script);</script></html>"""
    Set ws = CreateObject("WScript.Shell")
    '创建用户变量
    Set env = ws.environment(envType)
    env("stat") = 1
    Set oExec = ws.Exec(myHtml)
    env("script") = "var wsh = new ActiveXObject('WScript.Shell');window.setInterval(function () {var text = wsh.Environment('user').Item('stat');if (text == 0) {window.close();}}, 50);"
    LoadingDialog = oExec.ProcessID
End Function

Set WshShell = Wscript.CreateObject("Wscript.Shell")
Set fso = CreateObject("Scripting.FileSystemObject")

If wscript.arguments.count=0 Then
    ' 获取当前用户桌面
    f = GetFileDlgEx(WshShell.SpecialFolders("Desktop"), "*.war", "选择WAR包")
Else
    f = wscript.arguments(0)
End If

If f = "" Or IsNull(f) Or Not InStr(1, f, ".war") > 1 Then
    MsgBox "请选择WAR包！", 48
    Wscript.Quit
End If


' If Err <> 0 Then
    ' MsgBox "文件夹未正确选择！" & Err.Description, 48
    ' Err.clear ' 错误被手工处理后要记得清除err对象的内容
    ' Wscript.Quit
' End If
' On Error Goto 0 ' 关闭错误捕获

' 输出选择的文件路径
' MsgBox "当前选择的文件：" & chr(13) & f, 64

' 打开对话框
Set oExec = WshShell.Exec("mshta javascript:""<HTA:APPLICATION SCROLL = 'No' MinimizeButton='No'/><span>提示：可从SVN日志中查找到文件</span><textarea id='t' cols='60' rows='20' style='width:100%;height:100%'></textarea><script>document.title='要打包的文件';resizeTo(500, 450);document.body.onunload = function(){new ActiveXObject('Scripting.FileSystemObject').GetStandardStream(1).Write(t.value);}</script>""")

arg = oExec.StdOut.ReadAll
' arg = InputBox("多个文件之间以空格分割" & vbCrLf & vbCrLf & "提示：可从SVN日志中查找到文件", "要打包的文件", "")

If arg = "" Then
    MsgBox "请输入要打包的文件！", 48
    Wscript.Quit
End If

s = Replace(arg, ".java", "*")
With New RegExp
    .Global = True
    .MultiLine = True
    .Pattern = vbCrLf & "|" & vbCr & "|" & vbLf
    s = .Replace(s, " ")
End With


' 处理war包
Set fObj = fso.GetFile(f)
Set fPf = fObj.ParentFolder
fName = fObj.name
oldFolder = Replace(fObj.path, ".war", "")

If fso.folderExists(oldFolder) Then
    MsgBox "文件夹" & oldFolder & "已经存在！", 48
    Wscript.Quit
End If

unWar = oldFolder & "\" & fName
' 创建文件夹
fso.CreateFolder(oldFolder)
' 复制文件
fso.CopyFile f, unWar, True
' 切换工作目录
WshShell.CurrentDirectory = oldFolder

envType = "user"
LoadingDialog(envType) ' 解压提示弹窗
'创建用户变量
set env = WshShell.environment(envType)
' 解压WAR包
resCode = WshShell.Run("jar -xvf " & unWar, 0, True)
If resCode <> 0 Then
    env("stat") = 0
    MsgBox "WAR包解压错误！", 48
    Wscript.Quit
End If
env("stat") = 0
' 删除文件
fso.DeleteFile(unWar)
' WshShell.CurrentDirectory = fso.GetFolder(".").Path
WshShell.CurrentDirectory = fso.GetFile(Wscript.ScriptFullName).ParentFolder.Path

' On Error Resume Next ' 捕获异常

tn = Now ' 当前时间
With New RegExp
    .Global = True
    .MultiLine = True
    .Pattern = "-|/|\s|:"
    tn = .Replace(tn, "")
End With
copyPath = oldFolder & "_" & tn & "_" & WshShell.ExpandEnvironmentStrings("%USERNAME%") ' 复制后的路径



' https://docs.microsoft.com/zh-cn/windows-server/administration/windows-commands/robocopy
resCode = WshShell.Run("robocopy /ndl /njh /njs /s """ & oldFolder & """ """ & copyPath & """ " & s, 0, True)

If resCode > 8 Then
    MsgBox "增量文件复制错误！", 48
    Wscript.Quit
End If
' 删除文件
fso.DeleteFolder(oldFolder)

If Not fso.folderExists(copyPath) Then
    MsgBox "复制文件失败！", 48
End If

WshShell.Run "powershell -NonInteractive -c ""Compress-Archive -Path """""""& copyPath &""""""" -DestinationPath """"""" & copyPath & ".zip" &""""""" """, 1, True

' If fso.folderExists(copyPath) Then
    ' MsgBox "执行成功！", 64
    ' WshShell.Explore(copyPath)
' Else
    ' MsgBox "执行失败！", 48
' End If