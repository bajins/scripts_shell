Function CreateProgressBar(envType)
    '在HTA中动态创建脚本加载 jerryHtml_env 的内容
    myHtml = "mshta javascript:""<HTA:Application scroll='no'><html><body></body><script>var wsh=new ActiveXObject('WScript.Shell');var myscript = document.createElement('SCRIPT');myscript.text=wsh.Environment('"&envType&"').Item('jerryHtml_env');document.body.appendChild(myscript);</script><SCRIPT Language='VBScript'>window.moveTo screen.availWidth/4, screen.availHeight/3</SCRIPT></html>"""
    Set WshShell = CreateObject("WScript.Shell")
    '创建用户变量
    Set env = WshShell.environment(envType)
    env("jerryCount_env") = 0
    Set oExec = WshShell.Exec(myHtml)
    
    'jerryHtml_env： HTA的主体，通过js动态创建进度条写入 <body>
    env("jerryHtml_env") ="var mydiv = document.createElement('div');mydiv.innerHTML=""<body>" _
    & "<style type='text/css'>body{text-align:center}.process-bar{width:80%;top:20%;display:inline-block;zoom:2}.pb-wrapper{border:1px solid gray;position:relative;background:#cfd0d2;border-style:solid none}.pb-container{text-align:left;border:1px solid gray;height:12px;position:relative;left:-1px;margin-right:-2px;font:1px/0 arial;border-style:none solid;padding:1px}.pb-highlight{position:absolute;left:0;top:0;width:100%;opacity:.6;filter:alpha(opacity=60);height:6px;background:#FFF;font-size:1px;line-height:0;z-index:1}.pb-text{width:100%;position:absolute;left:46%;top:0;color:#000;font:10px/12px arial}.pb-value{height:100%;width:10%;background:#19d73d}.skin-green .pb-wrapper{border-color:#628c2d #666 #666}.skin-green .pb-container{border-color:#666 #666 #666 #628c2d}</style>" _
    & "o(∩_∩)o 导表中。。。<div class='process-bar skin-green pb-wrapper'><div class='pb-highlight'></div><div class='pb-container'><div class='pb-text' id='ptx'></div><div class='pb-value' id='pID'></div></div></div>" _
    & "</body>"";" _
    & "window.resizeTo(screen.availWidth/2, screen.availHeight/4);document.title = '策划导表，闲人回避！';document.body.appendChild(mydiv);var wsh=new ActiveXObject('WScript.Shell');window.setInterval(function(){var str=wsh.Environment('"&envType&"').Item('jerryCount_env');if(str<0)window.close();document.getElementById('pID').style.width=str+'%';document.getElementById('ptx').innerHTML=str+'%';},50);"
    CreateProgressBar = oExec.ProcessID
End Function


CreateProgressBar("volatile")

Set env = CreateObject("WScript.Shell").environment("volatile")
For i = 0 To 100 Step 10
    WScript.Sleep 500
    env("jerryCount_env") = i
Next

WScript.Sleep 500
env("jerryCount_env") = -1

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

envType = "user"
LoadingDialog(envType)
'创建用户变量
set oshell = createobject("wscript.shell")
set env = oshell.environment(envType)

For i = 0 To 100 Step 10
    WScript.Sleep 500
    if i=50 Then
        env("stat") = 0
    end if
Next

for each fname in wscript.arguments
    wscript.echo fname
next