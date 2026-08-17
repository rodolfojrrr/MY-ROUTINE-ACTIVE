#define MyAppName "My Routine Active"
#define MyAppVersion "2.0.2"
#define MyAppPublisher "Rodolfo Junior"
#define MyAppExeName "my_routine_active.exe"

[Setup]
AppId={{2DDA2A48-8C38-4F7B-A006-C98D12CF79E8}
AppName={#MyAppName}
AppVersion={#MyAppVersion}
AppPublisher={#MyAppPublisher}
DefaultDirName={autopf}\My Routine Active
DefaultGroupName=My Routine Active
DisableProgramGroupPage=yes
OutputDir=..\ENTREGAS
OutputBaseFilename=My-Routine-Active-Setup
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
Name: "{autoprograms}\My Routine Active"; Filename: "{app}\{#MyAppExeName}"
Name: "{autodesktop}\My Routine Active"; Filename: "{app}\{#MyAppExeName}"; Tasks: desktopicon

[Tasks]
Name: "desktopicon"; Description: "Criar atalho na área de trabalho"; GroupDescription: "Atalhos:"; Flags: unchecked

[Run]
Filename: "{app}\{#MyAppExeName}"; Description: "Abrir My Routine Active"; Flags: nowait postinstall skipifsilent

