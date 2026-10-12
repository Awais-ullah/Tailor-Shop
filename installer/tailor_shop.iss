[Setup]
AppName=Tailor Shop Manager
AppVersion=1.0.0
DefaultDirName={autopf}\Tailor Shop Manager
DefaultGroupName=Tailor Shop Manager
OutputBaseFilename=TailorShopManager-Setup
OutputDir=output
Compression=lzma
SolidCompression=yes
ArchitecturesInstallIn64BitMode=x64compatible

[Tasks]
Name: "desktopicon"; Description: "Create a desktop shortcut"

[Files]
Source: "..\build\windows\x64\runner\Release\*"; DestDir: "{app}"; Flags: recursesubdirs ignoreversion

[Icons]
Name: "{group}\Tailor Shop Manager"; Filename: "{app}\tailor_app.exe"
Name: "{autodesktop}\Tailor Shop Manager"; Filename: "{app}\tailor_app.exe"; Tasks: desktopicon

[Run]
Filename: "{app}\tailor_app.exe"; Description: "Launch Tailor Shop Manager"; Flags: nowait postinstall skipifsilent