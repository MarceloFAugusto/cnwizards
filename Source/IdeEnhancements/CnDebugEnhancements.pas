{******************************************************************************}
{                       CnPack For Delphi/C++Builder                           }
{                     中国人自己的开放源码第三方开发包                         }
{                   (C)Copyright 2001-2023 CnPack 开发组                       }
{                   ------------------------------------                       }
{                                                                              }
{            本开发包是开源的自由软件，您可以遵照 CnPack 的发布协议来修        }
{        改和重新发布这一程序。                                                }
{                                                                              }
{            发布这一开发包的目的是希望它有用，但没有任何担保。甚至没有        }
{        适合特定目的而隐含的担保。更详细的情况请参阅 CnPack 发布协议。        }
{                                                                              }
{            您应该已经和开发包一起收到一份 CnPack 发布协议的副本。如果        }
{        还没有，可访问我们的网站：                                            }
{                                                                              }
{            网站地址：http://www.cnpack.org                                   }
{            电子邮件：master@cnpack.org                                       }
{                                                                              }
{******************************************************************************}

unit CnDebugEnhancements;
{ |<PRE>
================================================================================
* 软件名称：CnPack IDE 专家包
* 单元名称：调试功能扩展单元
* 单元作者：刘啸 (liuxiao@cnpack.org)
* 备    注：
* 开发平台：PWin7Pro + Delphi 10.3
* 兼容测试：暂无
* 本 地 化：该单元中的字符串支持本地化处理方式
* 修改记录：2023.09.05 V1.0
*               实现单元
================================================================================
|</PRE>}

interface

{$I CnPack.inc}

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, IniFiles, ToolsAPI, CnConsts, CnWizConsts, CnWizClasses, CnWizOptions,
  ComCtrls, StdCtrls;

type
  TCnDebugEnhanceWizard = class(TCnIDEEnhanceWizard)
  private
    FRegistered: Boolean;
    FVisualCalls: TStringList;
{$IFDEF IDE_HAS_DEBUGGERVISUALIZER}
    FReplacer: IOTADebuggerVisualizerValueReplacer;
{$ENDIF}
  protected
    procedure SetActive(Value: Boolean); override;
    function GetHasConfig: Boolean; override;
  public
    constructor Create; override;
    destructor Destroy; override;

    class function IsInternalWizard: Boolean; override;
    class procedure GetWizardInfo(var Name, Author, Email, Comment: string); override;

    procedure LoadSettings(Ini: TCustomIniFile); override;
    procedure SaveSettings(Ini: TCustomIniFile); override;
    procedure ResetSettings(Ini: TCustomIniFile); override;

    procedure Config; override;

    property VisualCalls: TStringList read FVisualCalls;
    {* 求值的替换调用方式，形式为 1|类名.方法名}
  end;

{$IFDEF IDE_HAS_DEBUGGERVISUALIZER}

  TCnDebuggerValueReplacer = class(TInterfacedObject, IOTAThreadNotifier,
    IOTADebuggerVisualizerValueReplacer)
  private
    FRes: array[0..2047] of Char;
    FWizard: TCnDebugEnhanceWizard;
    FNames, FFunctions: TStrings;
    FNotifierIndex: Integer;
    FEvalComplete: Boolean;
    FEvalSuccess: Boolean;
    FCanModify: Boolean;
    FEvalResult: string;
  protected
    procedure ParseReplacers;
  public
    constructor Create(AWizard: TCnDebugEnhanceWizard);
    destructor Destroy; override;

    procedure AfterSave;
    procedure BeforeSave;
    procedure Destroyed;
    procedure Modified;

    procedure ThreadNotify(Reason: TOTANotifyReason);
    procedure EvaluteComplete(const ExprStr, ResultStr: string; CanModify: Boolean;
      ResultAddress, ResultSize: LongWord; ReturnCode: Integer);
     procedure ModifyComplete(const ExprStr, ResultStr: string; ReturnCode: Integer);

    function GetSupportedTypeCount: Integer;
    procedure GetSupportedType(Index: Integer; var TypeName: string;
      var AllDescendants: Boolean); overload;
    function GetVisualizerIdentifier: string;
    function GetVisualizerName: string;
    function GetVisualizerDescription: string;

    function GetReplacementValue(const Expression, TypeName, EvalResult: string): string;
  end;

{$ENDIF}

  TCnDebugEnhanceForm = class(TForm)
    btnOK: TButton;
    btnCancel: TButton;
    btnHelp: TButton;
    pgc1: TPageControl;
    tsDebugHint: TTabSheet;
    lblEnhanceHint: TLabel;
    lvVisualCalls: TListView;
  private

  public
    procedure LoadFromStrings(List: TStringList);
    procedure SaveToStrings(List: TStringList);
  end;

implementation

{$R *.dfm}

{$IFDEF DEBUG}
uses
  CnDebug;
{$ENDIF}

{ TCnDebugEnhanceWizard }

procedure TCnDebugEnhanceWizard.Config;
begin
  with TCnDebugEnhanceForm.Create(nil) do
  begin
    LoadFromStrings(FVisualCalls);
    if ShowModal = mrOK then
    begin
      SaveToStrings(FVisualCalls);
      DoSaveSettings;
      (FReplacer as TCnDebuggerValueReplacer).ParseReplacers;
    end;
    Free;
  end;
end;

constructor TCnDebugEnhanceWizard.Create;
begin
  inherited;
  FVisualCalls := TStringList.Create;
{$IFDEF IDE_HAS_DEBUGGERVISUALIZER}
  FReplacer := TCnDebuggerValueReplacer.Create(Self);
{$ENDIF}
end;

destructor TCnDebugEnhanceWizard.Destroy;
{$IFDEF IDE_HAS_DEBUGGERVISUALIZER}
var
  ID: IOTADebuggerServices;
{$ENDIF}
begin
{$IFDEF IDE_HAS_DEBUGGERVISUALIZER}
  if FRegistered then
    if Supports(BorlandIDEServices, IOTADebuggerServices, ID) then
      ID.UnregisterDebugVisualizer(FReplacer);

  FReplacer := nil;
{$ENDIF}
  FVisualCalls.Free;
  inherited;
end;

function TCnDebugEnhanceWizard.GetHasConfig: Boolean;
begin
  Result := True;
end;

class procedure TCnDebugEnhanceWizard.GetWizardInfo(var Name, Author,
  Email, Comment: string);
begin
  Name := SCnDebugEnhanceWizardName;
  Author := SCnPack_LiuXiao;
  Email := SCnPack_LiuXiaoEmail;
  Comment := SCnDebugEnhanceWizardComment;
end;

class function TCnDebugEnhanceWizard.IsInternalWizard: Boolean;
begin
  Result := True;
end;

procedure TCnDebugEnhanceWizard.LoadSettings(Ini: TCustomIniFile);
{$IFDEF IDE_HAS_DEBUGGERVISUALIZER}
var
  S: string;
{$ENDIF}
begin
  inherited;
{$IFDEF IDE_HAS_DEBUGGERVISUALIZER}
  S := WizOptions.GetUserFileName(SCnDebugReplacerDataName, True);
{$IFDEF DEBUG}
  CnDebugger.LogMsg('TCnDebugEnhanceWizard Load: ' + S);
{$ENDIF}

  if FileExists(S) then
  begin
    FVisualCalls.LoadFromFile(S);
    (FReplacer as TCnDebuggerValueReplacer).ParseReplacers;
  end;
{$ENDIF}
end;

procedure TCnDebugEnhanceWizard.ResetSettings(Ini: TCustomIniFile);
begin

end;

procedure TCnDebugEnhanceWizard.SaveSettings(Ini: TCustomIniFile);
{$IFDEF IDE_HAS_DEBUGGERVISUALIZER}
var
  S: string;
{$ENDIF}
begin
{$IFDEF IDE_HAS_DEBUGGERVISUALIZER}
  S := WizOptions.GetUserFileName(SCnDebugReplacerDataName, False);
  FVisualCalls.SaveToFile(S);
{$ENDIF}
  inherited;
end;

procedure TCnDebugEnhanceWizard.SetActive(Value: Boolean);
var
  ID: IOTADebuggerServices;
begin
  inherited;

{$IFDEF IDE_HAS_DEBUGGERVISUALIZER}

  if not Supports(BorlandIDEServices, IOTADebuggerServices, ID) then
    Exit;

  if Active then
  begin
    ID.RegisterDebugVisualizer(FReplacer);
    FRegistered := True;
  end
  else
  begin
    ID.UnregisterDebugVisualizer(FReplacer);
    FRegistered := False;
  end;

{$ENDIF}
end;

{$IFDEF IDE_HAS_DEBUGGERVISUALIZER}

{ TCnDebuggerValueReplacer }

constructor TCnDebuggerValueReplacer.Create(AWizard: TCnDebugEnhanceWizard);
begin
  inherited Create;
  FWizard := AWizard;
  FNames := TStringList.Create;
  FFunctions := TStringList.Create;
  ParseReplacers;
end;

destructor TCnDebuggerValueReplacer.Destroy;
begin
  FFunctions.Free;
  FNames.Free;
  inherited;
end;

procedure TCnDebuggerValueReplacer.ParseReplacers;
var
  I, Idx: Integer;
  S, N, F: string;
  Sub: Boolean;
begin
  FNames.Clear;
  FFunctions.Clear;

  for I := 0 to FWizard.VisualCalls.Count - 1 do
  begin
    Sub := False;
    S := FWizard.VisualCalls[I];
    Idx := Pos('|', S);         // 1| 代表包括子类，其他情况均不包括
    if Idx > 1 then
    begin
      N := Copy(S, 1, Idx - 1);
      if N = '1' then
        Sub := True;

      Delete(S, 1, Idx);
    end;

    Idx := Pos('.', S); // 到此处 S 不包括 |
    if (Idx > 1) and (Idx < Length(S)) then
    begin
      N := Copy(S, 1, Idx - 1);
      F := Copy(S, Idx + 1, MaxInt);
      FNames.Add(N);

      if Sub then
        FNames.Objects[FNames.Count - 1] := TObject(1);
      FFunctions.Add(F);
    end;
  end;
{$IFDEF DEBUG}
  CnDebugger.LogInteger(FNames.Count, 'TCnDebuggerValueReplacer Parse Replacers');
{$ENDIF}
end;

function TCnDebuggerValueReplacer.GetReplacementValue(const Expression,
  TypeName, EvalResult: string): string;
var
  I: Integer;
  Found: Boolean;
  ID: IOTADebuggerServices;
  CP: IOTAProcess;
  CT: IOTAThread;
  NewExpr: string;
  EvalRes: TOTAEvaluateResult;
  ResultAddr: TOTAAddress;
  ResultSize, ResultVal: Cardinal;
begin
{$IFDEF DEBUG}
  CnDebugger.LogFmt('TCnDebuggerValueReplacer get %s: %s, Display %s',
    [Expression, TypeName, EvalResult]);
{$ENDIF}
  Result := EvalResult;

  if not Supports(BorlandIDEServices, IOTADebuggerServices, ID) then
    Exit;

  CP := ID.CurrentProcess;
  if CP = nil then
    Exit;

  CT := CP.CurrentThread;
  if CT = nil then
    Exit;

  Found := False;
  for I := 0 to FNames.Count - 1 do
  begin
    if TypeName = FNames[I] then
    begin
      NewExpr := Expression + '.' + FFunctions[I];
      Found := True;
      Break;
    end;
  end;

{$IFDEF DEBUG}
  if Found then
    CnDebugger.LogMsg('TCnDebuggerValueReplacer to Evaluate: ' + NewExpr)
  else
  begin
    CnDebugger.LogMsg('TCnDebuggerValueReplacer NO Match. Exit');
    Exit;
  end;
{$ENDIF}

  EvalRes := CT.Evaluate(NewExpr, @FRes[0], SizeOf(FRes), FCanModify, True,
    '', ResultAddr, ResultSize, ResultVal);

  case EvalRes of
{$IFDEF DEBUG}
    erError: CnDebugger.LogMsg('TCnDebuggerValueReplacer Evaluate Error');
    erBusy: CnDebugger.LogMsg('TCnDebuggerValueReplacer Evaluate Busy');
{$ENDIF}
    erOK: Result := EvalResult + ': ' + FRes;
    erDeferred:
      begin
{$IFDEF DEBUG}
        CnDebugger.LogMsg('TCnDebuggerValueReplacer Evaluate Deferred. Wait for Events.');
{$ENDIF}
        FEvalComplete := False;
        FEvalSuccess := False;
        FEvalResult := '';

        FNotifierIndex := CT.AddNotifier(Self);
        while not FEvalComplete do
          ID.ProcessDebugEvents;
        CT.RemoveNotifier(FNotifierIndex);

        if FEvalSuccess then
        begin
{$IFDEF DEBUG}
          CnDebugger.LogMsg('TCnDebuggerValueReplacer Evaluate Deferred Success.');
{$ENDIF}
          Result := EvalResult + ': ' + FEvalResult;
        end;
      end;
  end;
end;

procedure TCnDebuggerValueReplacer.GetSupportedType(Index: Integer;
  var TypeName: string; var AllDescendants: Boolean);
begin
  TypeName := FNames[index];
  AllDescendants := FNames.Objects[Index] <> nil;
end;

function TCnDebuggerValueReplacer.GetSupportedTypeCount: Integer;
begin
  Result := FNames.Count;
end;

function TCnDebuggerValueReplacer.GetVisualizerDescription: string;
begin
  Result := SCnDebugVisualizerDescription;
end;

function TCnDebuggerValueReplacer.GetVisualizerIdentifier: string;
begin
  Result := SCnDebugVisualizerIdentifier;
end;

function TCnDebuggerValueReplacer.GetVisualizerName: string;
begin
  Result := SCnDebugVisualizerName;
end;


procedure TCnDebuggerValueReplacer.AfterSave;
begin

end;

procedure TCnDebuggerValueReplacer.BeforeSave;
begin

end;

procedure TCnDebuggerValueReplacer.Destroyed;
begin

end;

procedure TCnDebuggerValueReplacer.EvaluteComplete(const ExprStr,
  ResultStr: string; CanModify: Boolean; ResultAddress,
  ResultSize: LongWord; ReturnCode: Integer);
begin
  // Defer 的结果 Evaluate 完毕，如果 ReturnCode 不等于 0，ResultStr 里可能是出错信息
{$IFDEF DEBUG}
  CnDebugger.LogFmt('TCnDebuggerValueReplacer EvaluteComplete for %s: %d, %s',
    [ExprStr, ReturnCode, ResultStr]);
{$ENDIF}

  FEvalSuccess := ReturnCode = 0;

  if FEvalSuccess then
  begin
    FEvalResult := AnsiDequotedStr(ResultStr, '''');
  end
  else
    FEvalResult := '';

  FEvalComplete := True;
end;

procedure TCnDebuggerValueReplacer.Modified;
begin

end;

procedure TCnDebuggerValueReplacer.ModifyComplete(const ExprStr,
  ResultStr: string; ReturnCode: Integer);
begin

end;

procedure TCnDebuggerValueReplacer.ThreadNotify(Reason: TOTANotifyReason);
begin

end;

{$ENDIF}

{ TCnDebugEnhanceForm }

procedure TCnDebugEnhanceForm.LoadFromStrings(List: TStringList);
var
  Item: TListItem;
  I, Idx: Integer;
  S: string;
begin
  lvVisualCalls.Clear;
  for I := 0 to List.Count - 1 do
  begin
    Item := lvVisualCalls.Items.Add;
    Item.Caption := '';

    Item.Checked := False;
    S := List[I];
    Idx := Pos('|', S);
    if Idx > 1 then
    begin
      if Copy(S, 1, Idx - 1) = '1' then
        Item.Checked := True;
      Delete(S, 1, Idx);
    end;
    Item.SubItems.Add(S);
  end;
end;

procedure TCnDebugEnhanceForm.SaveToStrings(List: TStringList);
var
  I: Integer;
begin
  List.Clear;
  for I := 0 to lvVisualCalls.Items.Count - 1 do
  begin
    if lvVisualCalls.Items[I].Checked then
      List.Add('1|' + lvVisualCalls.Items[I].SubItems[0])
    else
      List.Add('0|' + lvVisualCalls.Items[I].SubItems[0]);
  end;
end;

initialization
{$IFDEF IDE_HAS_DEBUGGERVISUALIZER}
  RegisterCnWizard(TCnDebugEnhanceWizard);
{$ENDIF}

end.
