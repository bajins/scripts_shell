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

Set WshShell = Wscript.CreateObject("Wscript.Shell")
Set fso = CreateObject("Scripting.FileSystemObject")

' ��ȡ��ǰ�û�����
f = GetFileDlgEx(WshShell.SpecialFolders("Desktop"), "*.war", "ѡ��WAR��")
If f = "" Or IsNull(f) Then
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
' ��ѹWAR��
resCode = WshShell.Run("jar -xvf " & unWar, 0, True)
If resCode <> 0 Then
    MsgBox "WAR����ѹ����", 48
    Wscript.Quit
End If
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