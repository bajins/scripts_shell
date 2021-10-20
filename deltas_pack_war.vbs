' sIniDir Ϊ��ʼ��Ŀ¼
' sFilter Ϊ�ļ���׺ ʾ����"*.*,*.txt"
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
    '��HTA�ж�̬�����ű����ر��� jerryHtml_env �����ݣ���Ҫѹ������Ϊһ�У�
    myHtml="mshta javascript:""<HTA:Application scroll='no' minimizeButton='no' maximizeButton='no' contextMenu='No' showInTaskbar= 'yes' sysMenu= 'no' selection='no'><html><body><div class=loading id=content style='text-align:center;margin: 20% auto'>����ִ�н�ѹ��</div></body><script>resizeTo(300, 200);document.title = ' ';var wsh=new ActiveXObject('WScript.Shell');var script = document.createElement('SCRIPT');script.text=wsh.Environment('"&envType&"').Item('script');document.body.appendChild(script);</script></html>"""
    Set ws = CreateObject("WScript.Shell")
    '�����û�����
    Set env = ws.environment(envType)
    env("stat") = 1
    Set oExec = ws.Exec(myHtml)
    env("script") = "var wsh = new ActiveXObject('WScript.Shell');window.setInterval(function () {var text = wsh.Environment('user').Item('stat');if (text == 0) {window.close();}}, 50);"
    LoadingDialog = oExec.ProcessID
End Function

Set WshShell = Wscript.CreateObject("Wscript.Shell")
Set fso = CreateObject("Scripting.FileSystemObject")

If wscript.arguments.count=0 Then
    ' ��ȡ��ǰ�û�����
    f = GetFileDlgEx(WshShell.SpecialFolders("Desktop"), "*.war", "ѡ��WAR��")
Else
    f = wscript.arguments(0)
End If

If f = "" Or IsNull(f) Or Not InStr(1, f, ".war") > 1 Then
    MsgBox "��ѡ��WAR����", 48
    Wscript.Quit
End If

Set fObj = fso.GetFile(f)
Set fPf = fObj.ParentFolder
fName = fObj.name
oldFolder = Replace(fObj.path, ".war", "")

If fso.folderExists(oldFolder) Then
    MsgBox "�ļ���" & oldFolder & "�Ѿ����ڣ�", 48
    Wscript.Quit
End If

unWar = oldFolder & "\" & fName
' �����ļ���
fso.CreateFolder(oldFolder)
' �����ļ�
fso.CopyFile f, unWar, True
' �л�����Ŀ¼
WshShell.CurrentDirectory = oldFolder
envType = "user"
LoadingDialog(envType)
'�����û�����
set env = WshShell.environment(envType)
' ��ѹWAR��
resCode = WshShell.Run("jar -xvf " & unWar, 0, True)
If resCode <> 0 Then
    env("stat") = 0
    MsgBox "WAR����ѹ����", 48
    Wscript.Quit
End If
env("stat") = 0
' ɾ���ļ�
fso.DeleteFile(unWar)
' WshShell.CurrentDirectory = fso.GetFolder(".").Path
WshShell.CurrentDirectory = fso.GetFile(Wscript.ScriptFullName).ParentFolder.Path

' On Error Resume Next ' �����쳣

copyPath = oldFolder & "_copy" ' ���ƺ��·��

' If Err <> 0 Then
    ' MsgBox "�ļ���δ��ȷѡ��" & Err.Description, 48
    ' Err.clear ' �����ֹ������Ҫ�ǵ����err���������
    ' Wscript.Quit
' End If
' On Error Goto 0 ' �رմ��󲶻�

' ���ѡ����ļ�·��
' MsgBox "��ǰѡ����ļ���" & chr(13) & f, 64

' �򿪶Ի���
Set oExec = WshShell.Exec("mshta javascript:""<HTA:APPLICATION SCROLL = 'No' MinimizeButton='No'/><span>��ʾ���ɴ�SVN��־�в��ҵ��ļ�</span><textarea id='t' cols='60' rows='20' style='width:100%;height:100%'></textarea><script>document.title='Ҫ������ļ�';resizeTo(500, 450);document.body.onunload = function(){new ActiveXObject('Scripting.FileSystemObject').GetStandardStream(1).Write(t.value);}</script>""")

arg = oExec.StdOut.ReadAll
' arg = InputBox("����ļ�֮���Կո�ָ�" & vbCrLf & vbCrLf & "��ʾ���ɴ�SVN��־�в��ҵ��ļ�", "Ҫ������ļ�", "")

If arg = "" Then
    MsgBox "������Ҫ������ļ���", 48
    Wscript.Quit
End If

s = Replace(arg, ".java", "*")
With New RegExp
    .Global = True
    .MultiLine = True
    .Pattern = vbCrLf & "|" & vbCr & "|" & vbLf
    s = .Replace(s, " ")
End With

' https://docs.microsoft.com/zh-cn/windows-server/administration/windows-commands/robocopy
resCode = WshShell.Run("robocopy /ndl /njh /njs /s """ & oldFolder & """ """ & copyPath & """ " & s, 0, True)

If resCode > 8 Then
    MsgBox "�����ļ����ƴ���", 48
    Wscript.Quit
End If
' ɾ���ļ�
fso.DeleteFolder(oldFolder)

If fso.folderExists(copyPath) Then
    MsgBox "ִ�гɹ���", 64
    ' WshShell.Explore(copyPath)
Else
    MsgBox "ִ��ʧ�ܣ�", 48
End If