; Script generated by the Inno Script Studio Wizard.
; SEE THE DOCUMENTATION FOR DETAILS ON CREATING INNO SETUP SCRIPT FILES!

#define MyAppName "WOLAgent"
#define MyAppPublisher "Aquila Technology"
#define MyAppURL "https://wol.aquilatech.com/"
#define rootFolder "C:\Projects\agent"
#define MyAppExeName "WOLAgent.exe"
#define MyDescription "Aquila WOL Agent"
#define MyAppVersion GetFileVersion("C:\Projects\Agent\bin\Release\WOLAgent.exe")

#define signtool "c:\Program Files (x86)\Windows Kits\10\bin\x64\signtool.exe"
#define subject "Open Source Developer, Phillip Tull"
#define time "http://time.certum.pl"

[Setup]
; NOTE: The value of AppId uniquely identifies this application.
; Do not use the same AppId value in installers for other applications.
; (To generate a new GUID, click Tools | Generate GUID inside the IDE.)
AppId={{E0E4F4B0-2D93-4E03-B540-9198094045C4}
AppName={#MyAppName}
AppVersion={#MyAppVersion}
;AppVerName={#MyAppName} {#MyAppVersion}
AppPublisher={#MyAppPublisher}
AppPublisherURL={#MyAppURL}
AppSupportURL="https://github.com/basildane/WOLAgent/issues"
AppUpdatesURL={#MyAppURL}
DefaultDirName={pf}\{#MyAppPublisher}\{#MyAppName}
DefaultGroupName=WOLAgent
OutputDir=Release
OutputBaseFilename={#MyAppName}_{#MyAppVersion}
SetupIconFile={#rootFolder}\Resources\secuty_agent.ico
UninstallDisplayIcon={app}\{#MyAppExeName}
Compression=lzma
SolidCompression=yes
ArchitecturesInstallIn64BitMode=x64 ia64

; declare mysign=$p
SignTool=mysign {#signtool} sign /a /n $q{#subject}$q /as /fd sha256 /td sha256 /tr {#time} /d $q{#MyAppName}$q $f

[Languages]
Name: "english"; MessagesFile: "compiler:Default.isl"

[Files]
; NOTE: Don't use "Flags: ignoreversion" on any shared system files
Source: "{#rootFolder}\bin\Release\{#MyAppExeName}"; DestDir: "{app}"; Flags: ignoreversion sign; BeforeInstall: BeforeServiceInstall('{#MyAppName}', '{#MyAppExeName}'); AfterInstall: AfterServiceInstall('{#MyAppName}', '{#MyAppExeName}')

[Registry]
Root: "HKLM"; Subkey: "SYSTEM\CurrentControlSet\Services\{#MyAppName}"; ValueType: string; ValueName: "Description"; ValueData: "Passes WOL packets between networks."; Flags: createvalueifdoesntexist deletevalue

[Code]
#include "services_unicode.iss"

procedure BeforeServiceInstall(SvcName, FileName: String);
var
  S: Longword;
begin
  //If service is installed, it needs to be stopped
  if ServiceExists(SvcName) then begin
    S:= SimpleQueryService(SvcName);
    if S <> SERVICE_STOPPED then begin
      SimpleStopService(SvcName, True, True);
    end;
  end;
end;

procedure AfterServiceInstall(SvcName, FileName: String);
begin
  //If service is not installed, it needs to be installed now
  if not ServiceExists(SvcName) then begin
    if SimpleCreateService(SvcName, '{#MyDescription}', ExpandConstant('{app}')+'\' + FileName, SERVICE_AUTO_START, 'NT AUTHORITY\NETWORK SERVICE', '', False, True) then begin
      //Service successfully installed
      SimpleStartService(SvcName, True, True);
    end else begin
      //Service failed to install
    end;
  end;
end;


Const
  NET_FW_PROFILE2_DOMAIN = 1;
  NET_FW_PROFILE2_PRIVATE = 2;
  NET_FW_PROFILE2_PUBLIC = 4;
  NET_FW_PROFILE2_ALL = 2147483647;

  NET_FW_IP_PROTOCOL_TCP = 6;
  NET_FW_IP_PROTOCOL_UDP = 17;

  NET_FW_RULE_DIR_IN = 1;
  NET_FW_RULE_DIR_OUT = 2;

  NET_FW_ACTION_ALLOW = 1;

  procedure SetFirewallException(AppName,FileName:string);
var
  fwPolicy2: Variant;
  RulesObject: Variant;
  NewRule: Variant;
begin
  try
    fwPolicy2 := CreateOleObject('HNetCfg.FwPolicy2');
    RulesObject := fwPolicy2.Rules;

    //Create a Rule Object.
    NewRule := CreateOleObject('HNetCfg.FWRule');
    NewRule.Name := AppName;
    NewRule.Description := 'Allow incoming WOL packets on UPD port 9';
    NewRule.Applicationname := FileName;
    NewRule.Protocol := NET_FW_IP_PROTOCOL_UDP;
    NewRule.LocalPorts := 9;
    NewRule.Direction := NET_FW_RULE_DIR_IN;
    NewRule.Enabled := true;
    NewRule.Grouping := 'WakeOnLAN';
    NewRule.Profiles := NET_FW_PROFILE2_ALL;
    NewRule.Action := NET_FW_ACTION_ALLOW;
        
    //Add a new rule
    RulesObject.Add(NewRule);

  except
  end;
end;

procedure RemoveFirewallException(AppName:string);
var
    fwPolicy2: Variant;
begin
  try
    fwPolicy2 := CreateOleObject('HNetCfg.FwPolicy2');
    fwPolicy2.Rules.Remove(AppName);
  except
  end;
end;

procedure CurStepChanged(CurStep: TSetupStep);
begin
  if CurStep=ssPostInstall then
     SetFirewallException('{#MyDescription}', ExpandConstant('{app}\')+'{#MyAppExeName}');
end;

procedure CurUninstallStepChanged(CurUninstallStep: TUninstallStep);
var
  mRes : integer;
  S: Longword;
  SvcName : String;

begin
  SvcName := '{#MyAppName}';
  case CurUninstallStep of
    usUninstall:
      begin
        mRes := MsgBox('Do you want to remove the {#MyAppName} service?', mbConfirmation, MB_YESNO or MB_DEFBUTTON2)
        if mRes = IDYES then
          begin
            //If service is installed, it needs to be stopped
            if ServiceExists(SvcName) then begin
              S:= SimpleQueryService(SvcName);
              if S = SERVICE_RUNNING then begin
                SimpleStopService(SvcName, True, True);
              end;
              SimpleDeleteService(SvcName);
              RemoveFirewallException('{#MyDescription}');
            end;
          end;
      end;
  end;
end;
