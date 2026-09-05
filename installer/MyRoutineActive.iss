#define MyAppName "Smart Routine SI"
#define MyAppVersion "5.5.0"
#define MyAppPublisher "Rodolfo Junior"
#define MyAppExeName "my_routine_active.exe"

[Setup]
AppId={{2DDA2A48-8C38-4F7B-A006-C98D12CF79E8}
AppName={#MyAppName}
AppVersion={#MyAppVersion}
AppPublisher={#MyAppPublisher}
DefaultDirName={autopf}\Smart Routine SI
DefaultGroupName=Smart Routine SI
DisableProgramGroupPage=yes
OutputDir=..\ENTREGAS
OutputBaseFilename=Smart-Routine-SI-Setup
Compression=lzma2
SolidCompression=yes
WizardStyle=modern
ArchitecturesAllowed=x64compatible
ArchitecturesInstallIn64BitMode=x64compatible
SetupIconFile=..\windows\runner\resources\app_icon.ico
UninstallDisplayIcon={app}\{#MyAppExeName}
PrivilegesRequired=admin

[Languages]
Name: "brazilianportuguese"; MessagesFile: "compiler:Languages\BrazilianPortuguese.isl"

[Files]
Source: "..\build\windows\x64\runner\Release\*"; DestDir: "{app}"; Flags: ignoreversion recursesubdirs createallsubdirs

[Icons]
Name: "{autoprograms}\Smart Routine SI"; Filename: "{app}\{#MyAppExeName}"
Name: "{autodesktop}\Smart Routine SI"; Filename: "{app}\{#MyAppExeName}"; Tasks: desktopicon

[Tasks]
Name: "desktopicon"; Description: "Criar atalho na área de trabalho"; GroupDescription: "Atalhos:"; Flags: unchecked

[Run]
Filename: "{app}\{#MyAppExeName}"; Description: "Abrir Smart Routine SI"; Flags: nowait postinstall skipifsilent
