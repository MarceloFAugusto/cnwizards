{******************************************************************************}
{                       CnPack For Delphi/C++Builder                           }
{                     �й����Լ��Ŀ���Դ�������������                         }
{                   (C)Copyright 2001-2021 CnPack ������                       }
{                   ------------------------------------                       }
{                                                                              }
{            ���������ǿ�Դ���������������������� CnPack �ķ���Э������        }
{        �ĺ����·�����һ����                                                }
{                                                                              }
{            ������һ��������Ŀ����ϣ�������ã���û���κε���������û��        }
{        �ʺ��ض�Ŀ�Ķ������ĵ���������ϸ���������� CnPack ����Э�顣        }
{                                                                              }
{            ��Ӧ���Ѿ��Ϳ�����һ���յ�һ�� CnPack ����Э��ĸ��������        }
{        ��û�У��ɷ������ǵ���վ��                                            }
{                                                                              }
{            ��վ��ַ��http://www.cnpack.org                                   }
{            �����ʼ���master@cnpack.org                                       }
{                                                                              }
{******************************************************************************}

unit CnUsesToolsWizard;
{ |<PRE>
================================================================================
* �������ƣ�CnPack IDE ר�Ұ�
* ��Ԫ���ƣ����õ�Ԫ�������ߵ�Ԫ
* ��Ԫ���ߣ��ܾ��� (zjy@cnpack.org)
* ��    ע��ԭ��������õ� DCU �ļ����¼�� interface �����Լ� implementation ��
*           �ֵ����ÿһ����Ԫ�����Լ���Ӧ�ĵ�Ԫ�����ʶ�������ĳ����Ԫ�ı�ʶ��
*           ����Ϊ 0����ʾû���õ������ݣ����Կ����޸�Դ���޳�֮��
* ����ƽ̨��PWinXP SP2 + Delphi 5.01
* ���ݲ��ԣ�PWin9X/2000/XP + Delphi 5/6/7 + C++Builder 5/6
* �� �� �����ô����е��ַ���֧�ֱ��ػ�������ʽ
* �޸ļ�¼��2021.08.26 V1.3
*               �ĳ��Ӳ˵�ר������������������
*           2016.08.02 V1.2
*               �����Զ����沢�رմ��������ѡ����Ӧ�Դ���Ŀ
*           2011.11.05 V1.1
*               ���ƶ� XE2 ���Ĵ���ĵ�Ԫ����֧��
*           2005.08.11 V1.0
*               ������Ԫ
================================================================================
|</PRE>}

interface

{$I CnWizards.inc}

{$IFDEF CNWIZARDS_CNUSESTOOLS}

uses
  Windows, Messages, SysUtils, Classes, Graphics, Controls, Forms, Dialogs,
  StdCtrls, ToolsAPI, IniFiles, Contnrs, CnWizMultiLang, CnWizClasses, CnWizConsts,
  CnCommon, CnConsts, CnWizUtils, CnDCU32, CnWizIdeUtils, CnWizEditFiler,
  CnWizOptions, CnHashMap, mPasLex, Math, TypInfo, RegExpr, ActnList
  {$IFDEF DELPHIXE3_UP}, System.Actions {$ENDIF};

type

{ TCnUsesCleanerForm }

  TCnUsesCleanerForm = class(TCnTranslateForm)
    grpKind: TGroupBox;
    rbCurrUnit: TRadioButton;
    rbOpenedUnits: TRadioButton;
    rbCurrProject: TRadioButton;
    rbProjectGroup: TRadioButton;
    btnOK: TButton;
    btnCancel: TButton;
    btnHelp: TButton;
    grpSettings: TGroupBox;
    chkIgnoreInit: TCheckBox;
    lblIgnore: TLabel;
    chkIgnoreReg: TCheckBox;
    mmoClean: TMemo;
    lbl1: TLabel;
    mmoIgnore: TMemo;
    chkIgnoreNoSrc: TCheckBox;
    chkIgnoreCompRef: TCheckBox;
    chkProcessDependencies: TCheckBox;
    chkSaveAndClose: TCheckBox;
    procedure btnHelpClick(Sender: TObject);
    procedure rbCurrUnitClick(Sender: TObject);
  private

  protected
    function GetHelpTopic: string; override;
  public

  end;

  TCnUsesCleanKind = (ukCurrUnit, ukOpenedUnits, ukCurrProject, ukProjectGroup);

{ TCnUsesToolsWizard }

  TCnUsesToolsWizard = class(TCnSubMenuWizard)
  private
    FIdCleaner: Integer;
    FIdInitTree: Integer;
    FIdFromIdent: Integer;
    FIgnoreInit: Boolean;
    FIgnoreReg: Boolean;
    FIgnoreNoSrc: Boolean;
    FIgnoreCompRef: Boolean;
    FProcessDependencies: Boolean;
    FUseBuildAction: Boolean;  // �Ƿ�ʹ�� IDE �� Build �˵����������������ʹ�� OTA �ӿ�
    FSaveAndClose: Boolean;    // ����δ�򿪵��ļ���Clean ���Ƿ񱣴沢�رգ��������Ŀ���ļ�ȫ�򿪵��ºľ���Դ
    FIgnoreList: TStringList;
    FCleanList: TStringList;
    FRegExpr: TRegExpr;
    FUnitsMap: TCnStrToStrHashMap; // ����ȥ��
    FUnitIdents: TStringList; // �洢���������Ľ������ֵ�� DataList
    FUnitNames: TStringList;  // �洢���������Ĳ��ظ������� dcu �ǵ�·���ļ������м�ʹ��
    FSysPath: string;
{$IFDEF SUPPORT_CROSS_PLATFORM}
    FCurrPlatform: string;    // ���̵� Platform �����仯ʱ lib ���䣬��Ҫ���½���
{$ENDIF}
    function MatchInListWithExpr(List: TStrings; const Str: string): Boolean;
    function GetProjectFromModule(AModule: IOTAModule): IOTAProject;
    function ShowKindForm(var AKind: TCnUsesCleanKind): Boolean;
    function CompileUnits(AKind: TCnUsesCleanKind): Boolean;
    function ProcessUnits(AKind: TCnUsesCleanKind; List: TObjectList): Boolean;
    {* ����ĵ�Ԫ�������Ҵ�������}
    procedure ParseUnitKind(const FileName: string; var Kinds: TCnUsesKinds);
    {* ������ unit Դ���ȡ������ init������ Register ��������Ϣ}
    procedure GetCompRefUnits(AModule: IOTAModule; AProject: IOTAProject; Units:
      TStrings);
    procedure CheckUnits(List: TObjectList);
    {* ����ĵ�Ԫ��������}
    function DoCleanUnit(Buffer: IOTAEditBuffer; Intf, Impl: TStrings): Boolean;
    procedure CleanUnitUses(List: TObjectList);

    procedure UsesEnumCallback(const AUnitFullName: string; Exists: Boolean;
      FileType: TCnUsesFileType; ModuleSearchType: TCnModuleSearchType);
    procedure CheckReLoadUnitsMap;
    procedure LoadSysUnitsToList(DataList: TStringList);

    procedure CleanExecute;
    procedure InitTreeExecute;
    procedure FromIdentExecute;
  protected
    procedure SubActionExecute(Index: Integer); override;
    procedure SubActionUpdate(Index: Integer); override;
  public
    constructor Create; override;
    destructor Destroy; override;

    procedure LoadSettings(Ini: TCustomIniFile); override;
    procedure SaveSettings(Ini: TCustomIniFile); override;
    function GetState: TWizardState; override;
    class procedure GetWizardInfo(var Name, Author, Email, Comment: string); override;
    function GetCaption: string; override;
    function GetHint: string; override;
    function GetDefShortCut: TShortCut; override;

    procedure Execute; override;
    procedure AcquireSubActions; override;
  end;

{$ENDIF CNWIZARDS_CNUSESTOOLS}

implementation

{$IFDEF CNWIZARDS_CNUSESTOOLS}

uses
{$IFDEF DEBUG}
  CnDebug,
{$ENDIF}
  CnUsesCleanResultFrm, CnUsesInitTreeFrm, DCURecs, CnUsesIdentFrm, CnProgressFrm;

{$R *.DFM}

const
  csCleanList = 'UsesClean.dat';
  csIgnoreList = 'UsesIgnore.dat';

  csIgnoreInit = 'IgnoreInit';
  csIgnoreReg = 'IgnoreReg';
  csIgnoreNoSrc = 'IgnoreNoSrc';
  csIgnoreCompRef = 'IgnoreCompRef';
  csProcessDependencies = 'ProcessDependencies';
  csUseBuildAction = 'UseBuildAction';
  csSaveAndClose = 'SaveAndClose';
  csDcuExt = '.dcu';

  csProjectBuildCommand = 'ProjectBuildCommand';
  csProjectBuildAllCommand = 'ProjectBuildAllCommand';

{ TCnUsesCleaner }

constructor TCnUsesToolsWizard.Create;
begin
  inherited;
  FIgnoreInit := True;
  FIgnoreReg := True;
  FIgnoreNoSrc := False;
  FIgnoreCompRef := True;
  FProcessDependencies := False;
  FUseBuildAction := False; // Ĭ��ʹ�� OTA �ӿڣ�True ʱδ�������ԣ�ѡ����⿪��
  FSaveAndClose := False;   // Ĭ��ʹ�ô򿪺���ڴ�ķ�ʽ�������Զ����̣�������Ŀ���ܺľ���Դ
  FIgnoreList := TStringList.Create;
  FCleanList := TStringList.Create;

  FRegExpr := TRegExpr.Create;
  FRegExpr.ModifierI := True;
end;

destructor TCnUsesToolsWizard.Destroy;
begin
  FRegExpr.Free;
  FCleanList.Free;
  FIgnoreList.Free;
  FUnitsMap.Free;
  FUnitIdents.Free;
  FUnitNames.Free;
  inherited;
end;

procedure TCnUsesToolsWizard.Execute;
begin

end;

procedure TCnUsesToolsWizard.CleanExecute;
var
  Kind: TCnUsesCleanKind;
  List: TObjectList;
begin
  if CnOtaGetProjectGroup <> nil then
  begin
    // ��ʾѡ��Ի���
    if not ShowKindForm(Kind) then
      Exit;

    // ���뵥Ԫ
    if not CompileUnits(Kind) then
    begin
      ErrorDlg(SCnUsesCleanerCompileFail);
      Exit;
    end;

{$IFDEF DEBUG}
    CnDebugger.LogMsg('UsesCleaner Compile OK. Start to Process Files.');
{$ENDIF}

    // ���з���
    List := TObjectList.Create;
    try
      if ProcessUnits(Kind, List) then
      begin
        if List.Count = 0 then
        begin
          InfoDlg(SCnUsesCleanerNoneResult);
          Exit;
        end;

        CheckUnits(List);
        if ShowUsesCleanResultForm(List) then
          CleanUnitUses(List);
      end;
    finally
      List.Free;
    end;   
  end;
end;

function TCnUsesToolsWizard.ShowKindForm(var AKind: TCnUsesCleanKind): Boolean;
var
  Module: IOTAModule;
begin
  Result := False;
  // ��ʾ��������
  with TCnUsesCleanerForm.Create(nil) do
  try
    chkIgnoreInit.Checked := FIgnoreInit;
    chkIgnoreReg.Checked := FIgnoreReg;
    chkIgnoreNoSrc.Checked := FIgnoreNoSrc;
    chkIgnoreCompRef.Checked := FIgnoreCompRef;
    chkProcessDependencies.Checked := FProcessDependencies;
    chkSaveAndClose.Checked := FSaveAndClose;
    mmoIgnore.Lines.Assign(FIgnoreList);
    mmoClean.Lines.Assign(FCleanList);
    Module := CnOtaGetCurrentModule;
    if (Module <> nil) and IsPas(Module.FileName) and (Module.OwnerCount > 0) then
      rbCurrUnit.Checked := True
    else
    begin
      rbCurrUnit.Enabled := False;
      rbOpenedUnits.Checked := True;
    end;

    if ShowModal = mrOK then
    begin
      FIgnoreInit := chkIgnoreInit.Checked;
      FIgnoreReg := chkIgnoreReg.Checked;
      FIgnoreNoSrc := chkIgnoreNoSrc.Checked;
      FIgnoreList.Assign(mmoIgnore.Lines);
      FIgnoreCompRef := chkIgnoreCompRef.Checked;
      FProcessDependencies := chkProcessDependencies.Checked;
      FSaveAndClose := chkSaveAndClose.Checked;
      FCleanList.Assign(mmoClean.Lines);
      if rbCurrUnit.Checked then
        AKind := ukCurrUnit
      else if rbOpenedUnits.Checked then
        AKind := ukOpenedUnits
      else if rbCurrProject.Checked then
        AKind := ukCurrProject
      else
        AKind := ukProjectGroup;

      DoSaveSettings;
      Result := True;
    end;
  finally
    Free;
  end;
end;

function TCnUsesToolsWizard.GetProjectFromModule(AModule: IOTAModule): IOTAProject;
var
  i: Integer;
begin
  Result := AModule.GetOwner(0);
  for i := 1 to AModule.OwnerCount - 1 do
    if AModule.GetOwner(i) = CnOtaGetCurrentProject then
    begin
      Result := AModule.GetOwner(i);
      Break;
    end;
end;

function TCnUsesToolsWizard.CompileUnits(AKind: TCnUsesCleanKind): Boolean;
var
  Module: IOTAModule;
  Project: IOTAProject;
  ProjectGroup: IOTAProjectGroup;
  i: Integer;

  function DoBuildProjectAction: Boolean;
  var
    Action: TContainedAction;
  begin
{$IFDEF DEBUG}
    CnDebugger.LogEnter('DoBuildProjectAction');
{$ENDIF}

    InfoDlg('Will Build Current Project.');

    Action := FindIDEAction(csProjectBuildCommand);
    if Action <> nil then
      Result := Action.Execute
    else
      Result := False;

{$IFDEF DEBUG}
    CnDebugger.LogLeave('DoBuildProjectAction');
{$ENDIF}
  end;

  function DoBuildAllProjectAction: Boolean;
  var
    Action: TContainedAction;
  begin
{$IFDEF DEBUG}
    CnDebugger.LogEnter('DoBuildAllProjectAction');
{$ENDIF}

    InfoDlg('Will Build All Projects.');

    Action := FindIDEAction(csProjectBuildAllCommand);
    if Action <> nil then
      Result := Action.Execute
    else
      Result := False;

{$IFDEF DEBUG}
    CnDebugger.LogLeave('DoBuildAllProjectAction');
{$ENDIF}
  end;

begin
  Result := False;
  try
    case AKind of
      ukCurrUnit:
        begin
          if FUseBuildAction then
          begin
            Result := DoBuildAllProjectAction; // ��֪����ǰ��Ԫ�����ĸ� Project��ֻ��ȫ����
          end
          else
          begin
            Module := CnOtaGetCurrentModule;
            Assert(Assigned(Module) and (Module.OwnerCount > 0));
            Project := GetProjectFromModule(Module);
            Result := CompileProject(Project);
          end;
        end;
      ukCurrProject:
        begin
          Project := CnOtaGetCurrentProject;
          Assert(Assigned(Project));
          if FUseBuildAction then
            Result := DoBuildProjectAction
          else
            Result := CompileProject(Project);
        end;
    else
      begin
        if FUseBuildAction then
        begin
          Result := DoBuildAllProjectAction;
        end
        else
        begin
          ProjectGroup := CnOtaGetProjectGroup;
          Assert(Assigned(ProjectGroup));
          for i := 0 to ProjectGroup.ProjectCount - 1 do
          begin
            Result := CompileProject(ProjectGroup.Projects[i]);
            if not Result then
              Break;
          end;
        end;
      end;
    end;
  except
    on E: Exception do
      DoHandleException(E.Message);
  end;
end;

function TCnUsesToolsWizard.ProcessUnits(AKind: TCnUsesCleanKind;
  List: TObjectList): Boolean;
var
  Module: IOTAModule;
  Project: IOTAProject;
  ProjectGroup: IOTAProjectGroup;
  DcuPath: string;
  DcuName: string;
  ProjectInfo: TCnProjectUsesInfo;
  UsesInfo: TCnEmptyUsesInfo;
  i: Integer;

  function ModuleExists(const FileName: string): Boolean;
  var
    i, j: Integer;
  begin
    for i := 0 to List.Count - 1 do
      with TCnProjectUsesInfo(List[i]) do
        for j := 0 to Units.Count - 1 do
          if SameFileName(TCnEmptyUsesInfo(Units[i]).SourceFileName,
            FileName) then
          begin
            Result := True;
            Exit;
          end;
    Result := False;
  end;

  function GetDcuName(const ADcuPath, ASourceFileName: string): string;
  begin
    if ADcuPath = '' then
      Result := _CnChangeFileExt(ASourceFileName, csDcuExt)
    else
      Result := _CnChangeFileExt(ADcuPath + _CnExtractFileName(ASourceFileName), csDcuExt);
  end;

  // ��������������Ԫ
  function ProcessAUnit(const ADcuName, ASourceFileName: string;
    AProject: IOTAProject; var AInfo: TCnEmptyUsesInfo): Boolean;
  begin
    AInfo := nil;
    Result := False;
  {$IFDEF DEBUG}
    CnDebugger.LogMsg('UsesCleaner ProcessAUnit: ' + ADcuName);
  {$ENDIF}

    if IsDprOrPas(ASourceFileName) and FileExists(ADcuName) then
    begin
      AInfo := TCnEmptyUsesInfo.Create(ADcuName, ASourceFileName, AProject);
      Result := AInfo.Process;
      if not Result then
        FreeAndNil(AInfo);
    end;
  end;

  function ProcessAProject(AProject: IOTAProject; OpenedOnly, AProcessDependencies: Boolean): Boolean;
  var
    ProcessedUnitNames: TStringList;

    function RecursiveProcessUnit(const AUnitName: string): Boolean;
    var
      UnitUsesInfo: TCnUnitUsesInfo;
      DcuName: string;
      SourceFileName: string;
      i: Integer;
    begin
      Result := True;
      if ProcessedUnitNames.IndexOf(LowerCase(AUnitName)) <> -1 then
        Exit;

      DcuName := GetDcuName(DcuPath, AUnitName + '.pas');
      if not FileExists(DcuName) then
        Exit;

      SourceFileName := GetFileNameFromModuleName(AUnitName);

      if (SourceFileName = '') or not FileExists(SourceFileName) or
        ModuleExists(SourceFileName) then
        Exit;

      if ProcessAUnit(DcuName, SourceFileName, Project, UsesInfo) then
      begin
        if (UsesInfo.IntfCount > 0) or (UsesInfo.ImplCount > 0) then
          ProjectInfo.Units.Add(UsesInfo)
        else
          FreeAndNil(UsesInfo);
      end
      else if not QueryDlg(Format(SCnUsesCleanerProcessError,
        [_CnExtractFileName(SourceFileName)])) then
      begin
        Result := False;
        Exit;
      end;

      ProcessedUnitNames.Add(LowerCase(AUnitName));

      UnitUsesInfo := TCnUnitUsesInfo.Create(DcuName);
      try
        for i := 0 to UnitUsesInfo.IntfUsesCount - 1 do
        begin
          Result := RecursiveProcessUnit(UnitUsesInfo.IntfUses[i]);
          if not Result then
            Exit;
        end;

        for i := 0 to UnitUsesInfo.ImplUsesCount - 1 do
        begin
          Result := RecursiveProcessUnit(UnitUsesInfo.ImplUses[i]);
          if not Result then
            Exit;
        end;
      finally
        FreeAndNil(UnitUsesInfo);
      end;
      Result := True;
    end;

    function ProcessModuleDependencies(const ADcuName: string): Boolean;
    var
      UnitUsesInfo: TCnUnitUsesInfo;
      i: Integer;
    begin
      UnitUsesInfo := TCnUnitUsesInfo.Create(ADcuName);
      try
        for i := 0 to UnitUsesInfo.IntfUsesCount - 1 do
        begin
          Result := RecursiveProcessUnit(UnitUsesInfo.IntfUses[i]);
          if not Result then
            Exit;
        end;

        for i := 0 to UnitUsesInfo.ImplUsesCount - 1 do
        begin
          Result := RecursiveProcessUnit(UnitUsesInfo.ImplUses[i]);
          if not Result then
            Exit;
        end;
      finally
        FreeAndNil(UnitUsesInfo);
      end;
      Result := True;
    end;
  var
    i: Integer;
    ModuleInfo: IOTAModuleInfo;
    Opened: Boolean;
  begin
    Result := False;
    DcuPath := GetProjectDcuPath(Project);
    ProjectInfo := TCnProjectUsesInfo.Create;
    ProjectInfo.Project := AProject;
    try
      for i := 0 to AProject.GetModuleCount - 1 do
      begin
        ModuleInfo := AProject.GetModule(i);
        if not Assigned(ModuleInfo) or not IsPas(ModuleInfo.FileName) or
          ModuleExists(ModuleInfo.FileName) then
          Continue;

        Opened := CnOtaIsFileOpen(ModuleInfo.FileName);
        if OpenedOnly and not Opened then
          Continue;

        Module := ModuleInfo.OpenModule;
        try
          if not Assigned(Module) or not IsDprOrPas(Module.FileName) then
            Continue;

          DcuName := GetDcuName(DcuPath, Module.FileName);
          if not FileExists(DcuName) then
            Continue;

          if ProcessAUnit(DcuName, Module.FileName, Project, UsesInfo) then
          begin
            if (UsesInfo.IntfCount > 0) or (UsesInfo.ImplCount > 0) then
              ProjectInfo.Units.Add(UsesInfo)
            else
              FreeAndNil(UsesInfo);
          end
          else if not QueryDlg(Format(SCnUsesCleanerProcessError,
            [_CnExtractFileName(Module.FileName)])) then
          begin
            Exit;
          end;
        finally
          if not Opened and Assigned(Module) then
            Module.CloseModule(True);
        end;
      end;

      if AProcessDependencies then
      begin
        ProcessedUnitNames := TStringList.Create;
        try
          for i := 0 to AProject.GetModuleCount - 1 do
          begin
            ModuleInfo := AProject.GetModule(i);
            if not Assigned(ModuleInfo) or not IsPas(ModuleInfo.FileName) then
              Continue;

            DcuName := GetDcuName(DcuPath, Module.FileName);
            if not FileExists(DcuName) then
              Continue;

            if not ProcessModuleDependencies(DcuName) then
              Exit;
          end;
        finally
          FreeAndNil(ProcessedUnitNames);
        end;
      end;

      if ProjectInfo.Units.Count > 0 then
        List.Add(ProjectInfo);
      Result := True;
    finally
      if not Result then
        ProjectInfo.Free;
    end;                
  end;
begin
  Result := False;
  try
    List.Clear;
    case AKind of
      ukCurrUnit:
        begin
          Module := CnOtaGetCurrentModule;
          Assert(Assigned(Module) and (Module.OwnerCount > 0));
          Project := GetProjectFromModule(Module);
          DcuPath := GetProjectDcuPath(Project);
          DcuName := GetDcuName(DcuPath, Module.FileName);
          Result := ProcessAUnit(DcuName, Module.FileName, Project, UsesInfo);
          if Result then
          begin
            if (UsesInfo.IntfCount > 0) or (UsesInfo.ImplCount > 0) then
            begin
              ProjectInfo := TCnProjectUsesInfo.Create;
              ProjectInfo.Project := Project;
              ProjectInfo.Units.Add(UsesInfo);
              List.Add(ProjectInfo);
            end
            else
            begin
              FreeAndNil(UsesInfo);
            end;
          end
          else
            ErrorDlg(Format(SCnUsesCleanerUnitError, [_CnExtractFileName(Module.FileName)]))
        end;
      ukCurrProject:
        begin
          Project := CnOtaGetCurrentProject;
          Assert(Assigned(Project));
          Result := ProcessAProject(Project, False, FProcessDependencies);
        end;
    else
      begin
        ProjectGroup := CnOtaGetProjectGroup;
        Assert(Assigned(ProjectGroup));
        for i := 0 to ProjectGroup.ProjectCount - 1 do
        begin
          Project := ProjectGroup.GetProject(i);
          Result := ProcessAProject(Project, AKind = ukOpenedUnits, FProcessDependencies);
          if not Result then
            Break;
        end;
      end;
    end;
  except
    on E: Exception do
      DoHandleException(E.Message);
  end;
end;

procedure TCnUsesToolsWizard.ParseUnitKind(const FileName: string;
  var Kinds: TCnUsesKinds);
var
  Stream: TMemoryStream;
  Lex: TmwPasLex;
  Token: TTokenKind;
  RegDecl: Boolean;
begin
  Stream := TMemoryStream.Create;
  try
    EditFilerSaveFileToStream(FileName, Stream);
    Lex := TmwPasLex.Create;
    try
      Lex.Origin := PAnsiChar(Stream.Memory);
      RegDecl := False;
      Token := Lex.TokenID;
      while not (Lex.TokenID in [tkImplementation, tkNull]) do
      begin
        if (Lex.TokenID = tkRegister) and (Token = {$IFDEF DELPHI2010_UP}TTokenKind.{$ENDIF}tkProcedure) then
          RegDecl := True;
        Token := Lex.TokenID;
        Lex.NextNoJunk;
      end;

      Token := Lex.TokenID;
      while Lex.TokenID <> tkNull do
      begin
        if RegDecl and (Lex.TokenID = tkRegister) and (Token = {$IFDEF DELPHI2010_UP}TTokenKind.{$ENDIF}tkProcedure) then
          Include(Kinds, ukHasRegProc);

        // initialization ���Ǳ�ʶ���� begin �Ȳű�ʾ��Ч��ʼ���ڣ���̫�Ͻ���
        if Token = tkInitialization then
          if (Lex.TokenID in [tkIdentifier, tkBegin, tkFinalization, tkCompDirect]) then
            Include(Kinds, ukHasInitSection);

        Token := Lex.TokenID;
        Lex.NextNoJunk;
      end;
    finally
      Lex.Free;
    end;
  finally
    Stream.Free;
  end;
end;

procedure TCnUsesToolsWizard.GetCompRefUnits(AModule: IOTAModule; AProject:
  IOTAProject; Units: TStrings);
var
  FormEditor: IOTAFormEditor;
  Root: TComponent;
  i: Integer;

  // ����������丸��Ķ��嵥Ԫ
  procedure DoAddCompRef(ACls: TClass);
  var
    TypeData: PTypeData;
  begin
    if (ACls <> nil) and (ACls.ClassInfo <> nil) then
    begin
      TypeData := GetTypeData(PTypeInfo(ACls.ClassInfo));
      if (TypeData <> nil) and (Units.IndexOf({$IFDEF UNICODE}string{$ENDIF}(TypeData^.UnitName)) < 0) then
        Units.Add({$IFDEF UNICODE}string{$ENDIF}(TypeData^.UnitName));
      DoAddCompRef(ACls.ClassParent);
    end;
  end;

  // ����������������õ��ⲿ���嵥Ԫ
  procedure DoAddPropRef(AObj: TPersistent);
  var
    PropList: PPropList;
    Count, i, j: Integer;
    Obj: TObject;
    FormName, UnitName: string;
  begin
    try
      Count := GetPropList(AObj.ClassInfo, [tkClass], nil);
    except
      Exit;
    end;

    if Count > 0 then
    begin
      GetMem(PropList, Count * SizeOf(PPropInfo));
      try
        GetPropList(AObj.ClassInfo, [tkClass], PropList);
        for i := 0 to Count - 1 do
        begin
          Obj := TObject(GetOrdProp(AObj, PropList[I]));
          if Obj <> nil then
          begin
            if Obj is TComponent then
            begin
              if (TComponent(Obj).Owner <> nil) and (TComponent(Obj).Owner <> Root) then
              begin
                FormName := TComponent(Obj).Owner.Name;
                for j := 0 to AProject.GetModuleCount - 1 do
                  if SameText(AProject.GetModule(j).FormName, FormName) then
                  begin
                    UnitName := _CnChangeFileExt(_CnExtractFileName(
                      AProject.GetModule(j).FileName), '');
                    if Units.IndexOf(UnitName) < 0 then
                      Units.Add(UnitName);
                  end;
              end;
            end
            else if Obj is TCollection then
            begin
              for j := 0 to TCollection(Obj).Count - 1 do
                DoAddPropRef(TCollection(Obj).Items[j]);
            end
            else if Obj is TPersistent then
            begin
              DoAddPropRef(TPersistent(Obj));
            end;  
          end;
        end;
      finally
        FreeMem(PropList);
      end;
    end;      
  end;
begin
  Units.Clear;
  try
    FormEditor := CnOtaGetFormEditorFromModule(AModule);
    if Assigned(FormEditor) then
    begin
      Root := CnOtaGetRootComponentFromEditor(FormEditor);
      if Assigned(Root) then
      begin
        for i := 0 to Root.ComponentCount - 1 do
        begin
          DoAddCompRef(Root.Components[i].ClassType);
          DoAddPropRef(Root.Components[i]);
        end;
      end;
    end;
  except
    on E: Exception do
      DoHandleException(E.Message);
  end;   
end;

procedure TCnUsesToolsWizard.CheckUnits(List: TObjectList);
var
  UnitList, CompRef: TStringList;
  i, j, k, u: Integer;
  FileName: string;
  Kinds: TCnUsesKinds;
  Checked: Boolean;
begin
  // ���������ĵ�Ԫ
  UnitList := TStringList.Create;
  try
    // ȡ���������õ��ĵ�Ԫ
    UnitList.Sorted := True;
    for i := 0 to List.Count - 1 do
      for j := 0 to TCnProjectUsesInfo(List[i]).Units.Count - 1 do
        with TCnEmptyUsesInfo(TCnProjectUsesInfo(List[i]).Units[j]) do
        begin
          for k := 0 to IntfCount - 1 do
            if UnitList.IndexOf(IntfItems[k].Name) < 0 then
              UnitList.AddObject(IntfItems[k].Name, TObject(Pointer(Project)));
          for k := 0 to ImplCount - 1 do
            if UnitList.IndexOf(ImplItems[k].Name) < 0 then
              UnitList.AddObject(ImplItems[k].Name, TObject(Pointer(Project)));
        end;

    // ������Ԫ����
    for u := 0 to UnitList.Count - 1 do
    begin
      Kinds := [];

      if MatchInListWithExpr(FCleanList, UnitList[u]) then
        Include(Kinds, ukInCleanList);
      if MatchInListWithExpr(FIgnoreList, UnitList[u]) then
        Include(Kinds, ukInIgnoreList);

      FileName := GetFileNameFromModuleName(UnitList[u],
        IOTAProject(Pointer(UnitList.Objects[u])));
    {$IFDEF DEBUG}
      CnDebugger.LogMsg('Check Unit ' + UnitList[u] + ': ' + FileName);
    {$ENDIF}

      if FileName = '' then
        Include(Kinds, ukNoSource)
      else
        ParseUnitKind(FileName, Kinds);

      // �ж��Ƿ�Ĭ��ѡ��
      if ukInCleanList in Kinds then
        Checked := True
      else if ukInIgnoreList in Kinds then
        Checked := False
      else if FIgnoreInit and (ukHasInitSection in Kinds) then
        Checked := False
      else if FIgnoreReg and (ukHasRegProc in Kinds) then
        Checked := False
      else if FIgnoreNoSrc and (ukNoSource in Kinds) then
        Checked := False
      else
        Checked := True;

      for i := 0 to List.Count - 1 do
        for j := 0 to TCnProjectUsesInfo(List[i]).Units.Count - 1 do
          with TCnEmptyUsesInfo(TCnProjectUsesInfo(List[i]).Units[j]) do
          begin
            for k := 0 to IntfCount - 1 do
              if SameText(UnitList[u], IntfItems[k].Name) then
              begin
                IntfItems[k].Kinds := Kinds;
                IntfItems[k].Checked := Checked;
              end;
            for k := 0 to ImplCount - 1 do
              if SameText(UnitList[u], ImplItems[k].Name) then
              begin
                ImplItems[k].Kinds := Kinds;
                ImplItems[k].Checked := Checked;
              end;
          end;
    end;

  finally
    UnitList.Free;
  end;

  // ����ÿ����Ԫ��������õ�Ԫ
  CompRef := TStringList.Create;
  try
    for i := 0 to List.Count - 1 do
      for j := 0 to TCnProjectUsesInfo(List[i]).Units.Count - 1 do
        with TCnEmptyUsesInfo(TCnProjectUsesInfo(List[i]).Units[j]) do
        begin
          CompRef.Clear;
          GetCompRefUnits(CnOtaGetModule(SourceFileName), Project, CompRef);
          if CompRef.Count > 0 then
          begin
            for k := 0 to IntfCount - 1 do
              if CompRef.IndexOf(IntfItems[k].Name) >= 0 then
              begin
                IntfItems[k].Kinds := IntfItems[k].Kinds + [tkCompRef];
                if FIgnoreCompRef and not (ukInCleanList in IntfItems[k].Kinds) then
                  IntfItems[k].Checked := False;
              end;
            for k := 0 to ImplCount - 1 do
              if CompRef.IndexOf(ImplItems[k].Name) >= 0 then
              begin
                ImplItems[k].Kinds := ImplItems[k].Kinds + [tkCompRef];
                if FIgnoreCompRef and not (ukInCleanList in ImplItems[k].Kinds) then
                  ImplItems[k].Checked := False;
              end;
          end;
        end;
  finally
    CompRef.Free;
  end;
end;

type
  TPrvUsesItem = class
    Name: string;
    BeginPos: Longint;
    EndPos: Longint; // Position at the end of the unit name
    CommaBeforePos: Longint; // Position of ',' before unit name
    CommaAfterPos: Longint;  // Position of ',' after unit name
    SpaceAfter: Boolean;
  end;

function TCnUsesToolsWizard.DoCleanUnit(Buffer: IOTAEditBuffer; Intf, Impl:
  TStrings): Boolean;
var
  SrcStream: TMemoryStream;
  Writer: IOTAEditWriter;
  Lex: TmwPasLex;
  Source: string;

  // ���´��벿�ֲο��� GExperts �� GX_UsesManager ��Ԫ
  // liuxiao ����Դ�����ļ�����֧��
  function GetUsesSource(List: TStrings): AnsiString;
  var
    UsesList: TObjectList;
    Item: TPrvUsesItem;
    LastCommaPos: Integer;
    CPos, BegPos, EndPos: Integer;
    I, UnitStartPos, UnitEndPos: Integer;
    S: string;
  begin
{$IFDEF DEBUG}
    CnDebugger.LogFmt('GetUsesSource List: %s.', [List.Text]);
{$ENDIF}
    Result := '';
    CPos := Lex.TokenPos;
    UsesList := TObjectList.Create;
    try
      Item := nil;
      LastCommaPos := 0;
      UnitStartPos := 0;
      UnitEndPos := 0;
      while not (Lex.TokenID in [tkNull, tkSemiColon]) do
      begin
        if Lex.TokenID = tkIdentifier then
        begin
          if UnitStartPos = 0 then
            UnitStartPos := Lex.TokenPos;
          UnitEndPos := Lex.RunPos;
          S := S + string(Lex.Token);
        end
        else if Lex.TokenID = tkPoint then
        begin
          S := S + '.';
          UnitEndPos := Lex.RunPos;
        end
        else if Trim(S) <> '' then
        begin
          Item := TPrvUsesItem.Create;
          Item.Name := S;
          Item.BeginPos := UnitStartPos;
          Item.EndPos := UnitEndPos;
          if LastCommaPos <> 0 then
            Item.CommaBeforePos := LastCommaPos - 1;
          Item.CommaAfterPos := 0;
          UsesList.Add(Item);
{$IFDEF DEBUG}
//        CnDebugger.LogFmt('GetUsesSource UsesList Add: %s.', [Item.Name]);
{$ENDIF}
          S := '';
          UnitStartPos := 0;
          UnitEndPos := 0;
        end;

        if Lex.TokenID = tkComma then
        begin
          LastCommaPos := Lex.RunPos;
          if Item <> nil then
          begin
            Item.CommaAfterPos := LastCommaPos - 1;
            if Lex.Origin[Lex.RunPos] = ' ' then
              Item.SpaceAfter := True;
          end;
        end;
        
        Lex.NextNoJunk;
      end;
      if (Lex.TokenID = tkSemiColon) and (Trim(S) <> '') then
      begin
        // Add last unit before the semicolon
        Item := TPrvUsesItem.Create;
        Item.Name := S;
        Item.BeginPos := UnitStartPos;
        Item.EndPos := UnitEndPos;
        if LastCommaPos <> 0 then
          Item.CommaBeforePos := LastCommaPos - 1;
        Item.CommaAfterPos := 0;
        UsesList.Add(Item);
{$IFDEF DEBUG}
//      CnDebugger.LogFmt('GetUsesSource UsesList Add Last: %s.', [Item.Name]);
{$ENDIF}
      end;

{$IFDEF DEBUG}
      CnDebugger.LogFmt('GetUsesSource UsesList Count: %d. List Count %d.',
        [UsesList.Count, List.Count]);
{$ENDIF}
      if Lex.TokenID <> tkNull then
        Lex.Next;
      SetLength(Result, Lex.TokenPos - CPos);
      CopyMemory(Pointer(Result), Pointer(Integer(Lex.Origin) + CPos), Lex.TokenPos - CPos);

{$IFDEF DEBUG}
//    CnDebugger.LogFmt('GetUsesSource First Copy Result %s.', [Result]);
{$ENDIF}
      for I := UsesList.Count - 1 downto 0 do
      begin
        Item := TPrvUsesItem(UsesList[I]);
        if List.IndexOf(Item.Name) >= 0 then
        begin
{$IFDEF DEBUG}
//        CnDebugger.LogFmt('GetUsesSource Has Name %s.', [Item.Name]);
{$ENDIF}
          if I = 0 then // First in the uses clause
          begin
            if Item.CommaAfterPos <> 0 then
              EndPos := Item.CommaAfterPos + 1
            else
              EndPos := Item.EndPos;
            BegPos := Item.BeginPos;
          end
          else if I = UsesList.Count - 1 then // Last in the uses clause
          begin
            EndPos := Item.EndPos;
            if Item.CommaBeforePos <> 0 then
              BegPos := Item.CommaBeforePos
            else
              BegPos := Item.BeginPos;
          end
          else // In the middle of the uses clause
          begin
            if Item.CommaAfterPos = Item.EndPos then
            begin // Comma directly after unit
              BegPos := Item.BeginPos;
              EndPos := Item.CommaAfterPos + 1;
            end
            else // Comma before unit
            begin
              if Item.CommaBeforePos <> 0 then
                BegPos := Item.CommaBeforePos
              else
                BegPos := Item.BeginPos;
              EndPos := Item.EndPos;
            end;
          end;
          if Item.SpaceAfter then
            Inc(EndPos);

          // ��ֹɾ������ ; ��
          EndPos := Min(EndPos, CPos + Length(Result) - 1);
{$IFDEF DEBUG}
//        CnDebugger.LogFmt('GetUsesSource Before a Delete BegPos %d, CPos %d, EndPos %d.',
//          [BegPos, CPos, EndPos]);
{$ENDIF}
          Delete(Result, BegPos - CPos + 1, EndPos - BegPos);
{$IFDEF DEBUG}
//        CnDebugger.LogFmt('GetUsesSource After a Delete Result %s.', [Result]);
{$ENDIF}
          UsesList.Delete(I);
        end;
      end;
      
      if UsesList.Count = 0 then
        Result := '';
{$IFDEF DEBUG}
      CnDebugger.LogMsg('GetUsesSource Return: ' + string(Result));
{$ENDIF}
    finally
      UsesList.Free;
    end;
  end;
begin
  Result := False;
  try
    if Buffer.IsReadOnly then Exit;

    SrcStream := nil;
    Lex := nil;
    try
      SrcStream := TMemoryStream.Create;
      EditFilerSaveFileToStream(Buffer.FileName, SrcStream);
      // CnOtaSaveEditorToStream(Buffer, SrcStream, False, False);
      Lex := TmwPasLex.Create;
      Lex.Origin := PAnsiChar(SrcStream.Memory);

      Writer := Buffer.CreateUndoableWriter;
      
      while not (Lex.TokenID in [tkImplementation, tkUses, tkNull]) do
        Lex.NextNoJunk;

      if (Intf.Count > 0) and (Lex.TokenID = tkUses) then
      begin
        Writer.CopyTo(Lex.TokenPos);
        Source := string(ConvertEditorTextToText(GetUsesSource(Intf)));
        Writer.DeleteTo(Lex.TokenPos);
        if Source <> '' then
        begin
          Writer.Insert(PAnsiChar(ConvertTextToEditorText({$IFDEF UNICODE}AnsiString{$ENDIF}(Source))));
{$IFDEF DEBUG}
          CnDebugger.LogMsg('Intf write: ' + Source);
{$ENDIF}
        end;
      end;
      
      // ������ǰ�ķ��ţ������� impl ������ intf �� uses
      Lex.Next;
      Writer.CopyTo(Lex.TokenPos);

      if Impl.Count > 0 then
      begin
        while not (Lex.TokenID in [tkUses, tkNull]) do
          Lex.NextNoJunk;

        if Lex.TokenID = tkUses then
        begin
          Writer.CopyTo(Lex.TokenPos);
          Source := string(ConvertEditorTextToText(GetUsesSource(Impl)));
          Writer.DeleteTo(Lex.TokenPos);
          if Source <> '' then
          begin
            Writer.Insert(PAnsiChar(ConvertTextToEditorText({$IFDEF UNICODE}AnsiString{$ENDIF}(Source))));
{$IFDEF DEBUG}
            CnDebugger.LogMsg('Impl write: ' + Source);
{$ENDIF}
          end;
        end;
      end;

      Writer.CopyTo(SrcStream.Size);
      Result := True;
    finally
      Writer := nil;
      Lex.Free;
      SrcStream.Free;
    end;
  except
    ;
  end;          
end;

procedure TCnUsesToolsWizard.CleanUnitUses(List: TObjectList);

  function GetEditBuffer(const aUsesInfo: TCnEmptyUsesInfo; out ABuffer: IOTAEditBuffer): Boolean;
  var
    SrcEditor: IOTAEditor;
  begin
    ABuffer := nil;
    SrcEditor := CnOtaGetEditor(aUsesInfo.SourceFileName);
    if not Assigned(SrcEditor) then
    begin
      if CnOtaOpenFile(aUsesInfo.SourceFileName) then
        SrcEditor := CnOtaGetEditor(aUsesInfo.SourceFileName);
    end;

    if Assigned(SrcEditor) then
      ABuffer := SrcEditor as IOTAEditBuffer;

    Result := Assigned(ABuffer);
  end;

var
  Intf, Impl, Logs: TStringList;
  i, j, k: Integer;
  UCnt, Cnt: Integer;
  FileName: string;
  Buffer: IOTAEditBuffer;
  UsesInfo: TCnEmptyUsesInfo;
  Opened: Boolean;
begin
  Intf := nil;
  Impl := nil;
  Logs := nil;
  UCnt := 0;
  Cnt := 0;
  try
    Intf := TStringList.Create;
    Impl := TStringList.Create;
    Logs := TStringList.Create;
    for i := 0 to List.Count - 1 do
    begin
      for j := 0 to TCnProjectUsesInfo(List[i]).Units.Count - 1 do
      begin
        UsesInfo := TCnEmptyUsesInfo(TCnProjectUsesInfo(List[i]).Units[j]);
        Intf.Clear;
        Impl.Clear;
        for k := 0 to UsesInfo.IntfCount - 1 do
          if UsesInfo.IntfItems[k].Checked then
            Intf.Add(UsesInfo.IntfItems[k].Name);
        for k := 0 to UsesInfo.ImplCount - 1 do
          if UsesInfo.ImplItems[k].Checked then
            Impl.Add(UsesInfo.ImplItems[k].Name);

        if (Intf.Count > 0) or (Impl.Count > 0) then
        begin
          Opened := CnOtaIsFileOpen(UsesInfo.SourceFileName);
          try
            if GetEditBuffer(UsesInfo, Buffer) and
              DoCleanUnit(Buffer, Intf, Impl) then
            begin
              Inc(UCnt);
              Inc(Cnt, Intf.Count + Impl.Count);
              Logs.Add(UsesInfo.SourceFileName);
              if Intf.Count > 0 then
                Logs.Add('  Interface Uses: ' + Intf.CommaText);
              if Impl.Count > 0 then
                Logs.Add('  Implementation Uses: ' + Impl.CommaText);
            end
            else if not QueryDlg(Format(SCnUsesCleanerProcessError,
              [_CnExtractFileName(UsesInfo.SourceFileName)])) then
              Exit;
          finally
            if not Opened and FSaveAndClose and FileExists(UsesInfo.SourceFileName) then
            begin
{$IFDEF DEBUG}
              CnDebugger.LogMsg('Clean Result. Auto Save and Close ' + UsesInfo.SourceFileName);
{$ENDIF}
              CnOtaSaveFile(UsesInfo.SourceFileName, True);
              Sleep(0);
              CnOtaCloseFileByAction(UsesInfo.SourceFileName);
            end;
          end;
        end;
      end;
    end;
  finally
    Intf.Free;
    Impl.Free;
    if Cnt > 0 then
    begin
      if QueryDlg(Format(SCnUsesCleanerReport, [Cnt, UCnt])) then
      begin
        FileName := GetWindowsTempPath + 'CnUsesCleaner.txt';
        Logs.SaveToFile(FileName);
        RunFile(FileName);
      end;
    end;
    Logs.Free;
  end;
end;

procedure TCnUsesToolsWizard.LoadSettings(Ini: TCustomIniFile);
begin
  inherited;
  FIgnoreInit := Ini.ReadBool('', csIgnoreInit, FIgnoreInit);
  FIgnoreReg := Ini.ReadBool('', csIgnoreReg, FIgnoreReg);
  FIgnoreNoSrc := Ini.ReadBool('', csIgnoreNoSrc, FIgnoreNoSrc);
  FIgnoreCompRef := Ini.ReadBool('', csIgnoreCompRef, FIgnoreCompRef);
  FProcessDependencies := Ini.ReadBool('', csProcessDependencies, FProcessDependencies);
  FUseBuildAction := Ini.ReadBool('', csUseBuildAction, FUseBuildAction);
  FSaveAndClose := Ini.ReadBool('', csSaveAndClose, FSaveAndClose);
  WizOptions.LoadUserFile(FIgnoreList, csIgnoreList);
  WizOptions.LoadUserFile(FCleanList, csCleanList);
end;

procedure TCnUsesToolsWizard.SaveSettings(Ini: TCustomIniFile);
begin
  inherited;
  Ini.WriteBool('', csIgnoreInit, FIgnoreInit);
  Ini.WriteBool('', csIgnoreReg, FIgnoreReg);
  Ini.WriteBool('', csIgnoreNoSrc, FIgnoreNoSrc);
  Ini.WriteBool('', csIgnoreCompRef, FIgnoreCompRef);
  Ini.WriteBool('', csProcessDependencies, FProcessDependencies);
  Ini.WriteBool('', csUseBuildAction, FUseBuildAction);
  Ini.WriteBool('', csSaveAndClose, FSaveAndClose);
  WizOptions.SaveUserFile(FIgnoreList, csIgnoreList);
  WizOptions.SaveUserFile(FCleanList, csCleanList);
end;

function TCnUsesToolsWizard.GetCaption: string;
begin
  Result := SCnUsesToolsMenuCaption;
end;

function TCnUsesToolsWizard.GetDefShortCut: TShortCut;
begin
  Result := 0;
end;

function TCnUsesToolsWizard.GetHint: string;
begin
  Result := SCnUsesToolsMenuHint;
end;

function TCnUsesToolsWizard.GetState: TWizardState;
begin
  if CnOtaGetProjectGroup <> nil then
    Result := [wsEnabled]
  else
    Result := [];
end;

class procedure TCnUsesToolsWizard.GetWizardInfo(var Name, Author, Email,
  Comment: string);
begin
  Name := SCnUsesToolsName;
  Author := SCnPack_Zjy;
  Email := SCnPack_ZjyEmail;
  Comment := SCnUsesToolsComment;
end;

function TCnUsesToolsWizard.MatchInListWithExpr(List: TStrings;
  const Str: string): Boolean;
var
  I: Integer;
begin
  Result := False;
  if (List = nil) or (Str = '') then
    Exit;

  for I := 0 to List.Count - 1 do
  begin
    if (Str = List[I]) or RegExpContainsText(FRegExpr, Str, List[I]) then
    begin
      Result := True;
      Exit;
    end;
  end;
end;

procedure TCnUsesToolsWizard.AcquireSubActions;
begin
  FIdCleaner := RegisterASubAction(SCnUsesToolsCleaner, SCnUsesCleanerMenuCaption,
    0, SCnUsesCleanerMenuHint);
  FIdInitTree := RegisterASubAction(SCnUsesToolsInitTree, SCnUsesInitTreeMenuCaption,
    0, SCnUsesInitTreeMenuHint);
  FIdFromIdent := RegisterASubAction(ScnUsesToolsFromIdent, SCnUsesUnitFromIdentMenuCaption,
    0, SCnUsesUnitFromIdentMenuHint);
end;

procedure TCnUsesToolsWizard.SubActionExecute(Index: Integer);
begin
  if Index = FIdCleaner then
    CleanExecute
  else if Index = FIdInitTree then
    InitTreeExecute
  else if Index = FIdFromIdent then
    FromIdentExecute;
end;

procedure TCnUsesToolsWizard.SubActionUpdate(Index: Integer);
begin
  if (Index = FIdCleaner) or (Index = FIdInitTree) then
    SubActions[Index].Enabled := CnOtaGetProjectGroup <> nil;
end;

procedure TCnUsesToolsWizard.InitTreeExecute;
begin
  with TCnUsesInitTreeForm.Create(Application) do
  begin
    ShowModal;
    Free;
  end;
end;

procedure TCnUsesToolsWizard.CheckReLoadUnitsMap;
var
  ToReload: Boolean;
  Paths: TStringList;
  S: string;
begin
  ToReload := False;

  if FUnitsMap = nil then
  begin
    FUnitsMap := TCnStrToStrHashMap.Create;
{$IFDEF DEBUG}
    CnDebugger.LogMsg('First Init. To Reload Dcus.');
{$ENDIF}
    ToReload := True;

    // ����¼��������
{$IFDEF SUPPORT_CROSS_PLATFORM}
    FCurrPlatform := CnOtaGetProjectPlatform(nil);
{$ENDIF}

    Paths := TStringList.Create;
    try
      GetLibraryPath(Paths, False);
      FSysPath := Paths.Text;
    finally
      Paths.Free;
    end;
  end
  else
  begin
    // ����Ƿ�Ҫ��������ϵͳ Units������Ϊ�����ǰ���̵�ƽ̨�����ı䣨֧�ֿ�ƽ̨ʱ������ϵͳ·�������ı�
{$IFDEF SUPPORT_CROSS_PLATFORM}
    S := CnOtaGetProjectPlatform(nil);
    if S <> FCurrPlatform then
    begin
{$IFDEF DEBUG}
      CnDebugger.LogFmt('Current Platform Changed from %s to %s. To Reload Dcus.', [FCurrPlatform, S]);
{$ENDIF}
      ToReload := True;
      FCurrPlatform := S;
    end;
{$ENDIF}

    if not ToReload then
    begin
      Paths := TStringList.Create;
      try
        GetLibraryPath(Paths, False);
        if FSysPath <> Paths.Text then
        begin
          ToReload := True;
          FSysPath := Paths.Text; // �ȱ���
{$IFDEF DEBUG}
          CnDebugger.LogMsg('System Library Paths Changed. To Reload Dcus.');
{$ENDIF}
        end;
      finally
        Paths.Free;
      end;
    end;
  end;

  if ToReload then
  begin
    Screen.Cursor := crHourGlass;
    try
      ShowProgress(SCnUsesUnitAnalyzeWaiting);
      if FUnitIdents = nil then
        FUnitIdents := TStringList.Create
      else
        FUnitIdents.Clear;

      LoadSysUnitsToList(FUnitIdents);
{$IFDEF DEBUG}
      CnDebugger.LogMsg('LoadSysUnitsToList Complete.');
{$ENDIF}
    finally
      Screen.Cursor := crDefault;
      HideProgress;
    end;
  end;
end;

procedure TCnUsesToolsWizard.LoadSysUnitsToList(DataList: TStringList);
var
  I, T, H: Integer;
  Info: TCnUnitUsesInfo;
  Decl: TDCURec;
  S, V: string;
  IdentPair: TCnIdentUnitInfo;

  procedure CorrectCase;
  var
    J, Idx: Integer;
    OldPaths, OldNames: TStringList;
  begin
    OldNames := TStringList.Create;
    OldPaths := TStringList.Create;
    FUnitNames.Sort;

    try
      for J := 0 to FUnitNames.Count - 1 do
      begin
        OldPaths.Add(_CnExtractFilePath(FUnitNames[J]));
        FUnitNames[J] := _CnChangeFileExt(_CnExtractFileName(FUnitNames[J]), '');
        OldNames.Add(FUnitNames[J]); // ��ֱ���ԭ�е�·�����ļ���
      end;

      CorrectCaseFromIdeModules(FUnitNames); // ֻ֧�ִ��ļ�������������ź���
      FUnitNames.Sorted := False;

      for J := 0 to FUnitNames.Count - 1 do
      begin
        Idx := OldNames.IndexOf(FUnitNames[J]); // ���ݸ��ĺ���ļ����ҵ�ԭ����Ӧ��·��
        FUnitNames[J] := MakePath(OldPaths[Idx]) + FUnitNames[J] + '.dcu';
      end;
    finally
      OldPaths.Free;
      OldNames.Free;
    end;
  end;

  function ExtractSymbol(const Symbol: string): string;
  var
    K, Idx, C, Front, Back: Integer;
    Deled: Boolean;
  begin
    // �����Ϲ淶�� Symbol�����ؿ��ַ���������� Symbol ��ȥ����������
    Result := '';

    // ��������� initialization �� finalization Ҫȥ�����Ƿֺ�����Ҫȥ����
    // �ٴӺ���ǰ������ <> ���Ҫȥ����{} ���Ҫȥ�������һ����ź��
    if (Symbol = '') or IsInt(Symbol) then
      Exit;

    if (lstrcmpi(PChar(Symbol), 'initialization') = 0) or
      (lstrcmpi(PChar(Symbol), 'finalization') = 0) then
      Exit;

    Result := Symbol;
    if Result[1] in [':', '.'] then
      Delete(Result, 1, 1);
    if IsInt(Result) then
    begin
      Result := '';
      Exit;
    end;

    // ���������ȥ����ͷ�� } �Ĳ���
    Idx := LastCharPos(Result, '}');
    if Idx > 0 then
      Result := Copy(Result, Idx + 1, MaxInt);

    // Ȼ���β������ɨ�跺�� <>��ע�����Ƕ�ײ����ж��
    while Pos('<', Result) > 0 do
    begin
      C := 0;
      Front := 0;
      Back := 0;
      Deled := False;

      for K := Length(Result) downto 1 do
      begin
        if Result[K] = '>' then
        begin
          if C = 0 then
            Back := K;
          Inc(C);
        end
        else if Result[K] = '<' then
        begin
          Dec(C);
          if C = 0 then
          begin
            Front := K;
            if (Back > 0) and (Front > 0) and (Back > Front) then
            begin
              Delete(Result, Front, Back - Front + 1);  // �õ�һ���������������� <> Ȼ��ɾ��
              Deled := True;
              Break;
            end;
          end;
        end;
      end;

      // Break ���⣬�������ûɾ˵��û��ɾ��
      if not Deled then
        Break;
    end;

    // û��ɾ�Ķ�����Ȼ��ɾ���һ�� < ������ݣ���ֹ���ֲ���Ե����
    Idx := LastCharPos(Result, '<');
    if Idx > 0 then
      Result := Copy(Result, 1, Idx - 1);

{$IFDEF SUPPORT_GENERIC}
    // ɾ���һ�� ` �ź��
    Idx := LastCharPos(Result, '`');
    if Idx > 0 then
      Result := Copy(Result, 1, Idx - 1);
{$ENDIF}

    // ��������һ����ź��
    Idx := LastCharPos(Result, '.');
    if Idx > 0 then
      Result := Copy(Result, Idx + 1, MaxInt);

{$IFDEF SUPPORT_CLASS_CONSTRUCTOR}
    if Result = '$ClassInitFlag' then
      Result := '';
{$ENDIF}

    if (Length(Result) >= 1) and (Result[1] = ':') then // ȥ�� TAClass.:-1 ����
      Delete(Result, 1, 1);
    if IsInt(Result) then
      Result := '';
  end;

begin
  if FUnitNames = nil then
    FUnitNames := TStringList.Create
  else
    FUnitNames.Clear;

{$IFDEF DEBUG}
  CnDebugger.LogMsg('Prepare to Call IdeEnumUsesIncludeUnits');
{$ENDIF}

  if IdeEnumUsesIncludeUnits(UsesEnumCallback, False, [mstSystemSearch]) then
  begin
{$IFDEF DEBUG}
    CnDebugger.LogFmt('After Call IdeEnumUsesIncludeUnits. Get %d', [FUnitNames.Count]);
{$ENDIF}

    // ȡ�������֣�������Сд
    if FUnitNames.Count > 0 then
    begin
      CorrectCase;

      // ��Сд������ϣ����� HashMap
      H := -1;
      for I := 0 to FUnitNames.Count - 1 do
      begin
        Info := TCnUnitUsesInfo.Create(FUnitNames[I]);

        T := (100 * I) div FUnitNames.Count;
        if T <> H then
        begin
          H := T;
          UpdateProgress(H);
        end;

{$IFDEF DEBUG}
//        CnDebugger.LogMsg(FUnitNames[I]);
{$ENDIF}
        try
          for T := 0 to Info.ExportedNames.Count - 1 do
          begin
            Decl := TDCURec(Info.ExportedNames.Objects[T]);
            S := Decl.Name^.GetStr;
            if (S <> '') and (Decl.GetSecKind <> skNone) then
            begin
              S := ExtractSymbol(S);
              if S = '' then
                Continue;

              // ��� DataList ��� S �� FUnitNames[I]����ȥ��
              if FUnitsMap.Find(S, V) then
              begin
                if V = FUnitNames[I] then
                begin
                  Decl := Decl.Next;
                  Continue;
                end;
              end;
              FUnitsMap.Add(S, FUnitNames[I]);

              IdentPair := TCnIdentUnitInfo.Create;
              IdentPair.Text := S;
              IdentPair.FullNameWithPath := FUnitNames[I];
              IdentPair.ImageIndex := 78; // Units
              DataList.AddObject(S, IdentPair);
            end;
          end;
        finally
          Info.Free;
        end;
      end;
      FUnitNames.Clear;
{$IFDEF DEBUG}
      CnDebugger.LogFmt('Ident Unit Form DataList Count %d', [DataList.Count]);
{$ENDIF}
    end;
    FreeAndNil(FUnitNames); // �����һ����ڴ�
  end;
end;

procedure TCnUsesToolsWizard.UsesEnumCallback(const AUnitFullName: string;
  Exists: Boolean; FileType: TCnUsesFileType;
  ModuleSearchType: TCnModuleSearchType);
begin
  if FileType = uftPascalDcu then
    FUnitNames.Add(AUnitFullName);
end;

procedure TCnUsesToolsWizard.FromIdentExecute;
var
  Token: TCnIdeTokenString;
  Idx: Integer;
  S, UnitName: string;
  Ini: TCustomIniFile;
begin
  CheckReLoadUnitsMap;
  S := '';
  if CurrentIsSource and CnOtaGeneralGetCurrPosToken(Token, Idx) then
    S := string(Token);

  with TCnUsesIdentForm.Create(Application, FUnitIdents) do
  begin
    Ini := CreateIniFile;
    try
      LoadSettings(Ini, '');
    finally
      Ini.Free;
    end;

    if S <> '' then
    begin
      edtMatchSearch.Text := S;
      edtMatchSearch.SelStart := Length(S);
{$IFDEF DEBUG}
      CnDebugger.LogFmt('Set Text %s to Search, Got Result %d',
        [S, lvList.Items.Count]);
{$ENDIF}

      if lvList.Items.Count = 0 then
      begin
        ErrorDlg(Format(SCNUsesUnitFromIdentErrorFmt, [S]));
        Exit;
      end
    end
    else
      edtMatchSearch.Text := '';

    if ShowModal = mrOk then
    begin
      // uses �������ڴ����ڴ���
      BringIdeEditorFormToFront;
    end;

    Ini := CreateIniFile;
    try
      SaveSettings(Ini, '');
    finally
      Ini.Free;
    end;
    Free;
  end;
end;

{ TCnUsesCleanerForm }

function TCnUsesCleanerForm.GetHelpTopic: string;
begin
  Result := 'CnUsesUnitsTools';
end;

procedure TCnUsesCleanerForm.btnHelpClick(Sender: TObject);
begin
  ShowFormHelp;
end;

procedure TCnUsesCleanerForm.rbCurrUnitClick(Sender: TObject);
begin
  chkProcessDependencies.Enabled := not rbCurrUnit.Checked;
end;

initialization
  RegisterCnWizard(TCnUsesToolsWizard); // ע��ר��

{$ENDIF CNWIZARDS_CNUSESTOOLS}
end.