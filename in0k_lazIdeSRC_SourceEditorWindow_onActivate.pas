unit in0k_lazIdeSRC_SourceEditorWindow_onActivate;

{$mode objfpc}{$H+}

interface

uses SrcEditorIntf, //< you must use IDEIntf
     Forms, Classes, SysUtils;

type

 tIn0k_lazIdeSRC_SourceEditor_onActivate=class
  {%region --- onActivate EVENT ----------------------------------- /fold}
  private
  _onEvent_:TNotifyEvent;
   procedure _do_onEvent_(const Sender:TObject);
  {%endRegion}
  {%region --- Active Editor SourceEditor ------------------------- /fold}
  private //< текущий АКТИВНЫЙ редактор в окне (вкладка, таб)
   _ide_object_ESE_:TSourceEditorInterface;
    procedure _ESE_set_(const value:TSourceEditorInterface);
  {%endRegion}
  {%region --- Active Window SourceEditor ------------------------- /fold}
  private //< текущee АКТИВНОЕ окно редактирования
   _ide_object_WSE_:TSourceEditorWindowInterface;
    procedure _WSE_set_(const wnd:TSourceEditorWindowInterface);
  private
   _ide_object_WSE_onDeactivate_original:TNotifyEvent;    //< его событие
    procedure _WSE_onDeactivate_myCustom(Sender:TObject); //< моя подстава
    procedure _WSE_rePlace_onDeactivate(const wnd:tForm);
    procedure _WSE_reStore_onDeactivate(const wnd:tForm);
  {%endRegion}
  {%region --- IdeEVENT ------------------------------------------- /fold}
  private //< обработка событий IDE Lazasur
    procedure _ideEvent_SUMMARY;
    procedure _ideEvent_semEditorActivate(Sender:TObject);
    procedure _ideEvent_semWindowFocused (Sender:TObject);
  {%endRegion}
  public
    property    onEvent:TNotifyEvent read _onEvent_ write _onEvent_;
  public
    constructor Create;
    procedure   LazarusIDE_SetUP;
    procedure   LazarusIDE_Clean;
  end;


implementation

constructor tIn0k_lazIdeSRC_SourceEditor_onActivate.Create;
begin
   _onEvent_:=nil;
   _ide_object_ESE_:=nil;
   _ide_object_WSE_:=nil;
end;

//------------------------------------------------------------------------------

{%region --- Active Editor SourceEditor --------------------------- /fold}

procedure tIn0k_lazIdeSRC_SourceEditor_onActivate._ESE_set_(const value:TSourceEditorInterface);
begin
    if value<>_ide_object_ESE_ then begin
      _ide_object_ESE_:=value;
      _do_onEvent_(_ide_object_ESE_);
    end
end;

{%endRegion}

{%region --- Active Window SourceEditor --------------------------- /fold}

{ ТЕКУЩЕЕ окно "Редактирования Исходного Кода"
  - Именно то, на котором в данный момент находтся "ФОКУС".
  - Окон "Редактирования Исходного Кода" может быть НЕСКОЛЬКО.
    В "фОКУСе" может находится или ОДНО, или НИКОГО.
}
{ Идея: отловить момент "выхода" из окна редактирования.
  Используем "грязны" метод: аля "сабКлассинг", заменяем на СОБСТВЕННУЮ
  реализацию событие `onDeactivate`.
}

// НАШЕ событие, при `onDeactivate` ActiveSrcWND
procedure tIn0k_lazIdeSRC_SourceEditor_onActivate._WSE_onDeactivate_myCustom(Sender:TObject);
begin
    {$ifDEF _EventLOG_}
    DEBUG('_SEW_onDeactivate_myCustom','--->>> Sender'+addr2txt(Sender));
    {$endIf}

    // отмечаем что ВЫШЛИ из окна
   _ide_object_WSE_:=NIL;
   _ESE_set_(NIL);
    // восстановить событие `onDeactivate` на исходное, и выполнияем его
    if Assigned(Sender) then begin
        if Sender is TSourceEditorWindowInterface then begin
           _WSE_reStore_onDeactivate(tForm(Sender));
            with TSourceEditorWindowInterface(Sender) do begin
                if Assigned(OnDeactivate) then OnDeactivate(Sender);
                {$ifDEF _EventLOG_}
                DEBUG('OK','TSourceEditorWindowInterface('+addr2txt(sender)+').OnDeactivate executed');
                {$endIf}
            end;
        end
        else begin
            {$ifDEF _EventLOG_}
            DEBUG('ER','Sender is NOT TSourceEditorWindowInterface');
            {$endIf}
        end;
    end
    else begin
        {$ifDEF _EventLOG_}
        DEBUG('ER','Sender==NIL');
        {$endIf}
    end;

    {$ifDEF _EventLOG_}
    DEBUG('_SEW_onDeactivate_myCustom','---<<<');
    {$endIf}
end;

//------------------------------------------------------------------------------

// ЗАМЕНЯЕМ `onDeactivate` на собственное
procedure tIn0k_lazIdeSRC_SourceEditor_onActivate._WSE_rePlace_onDeactivate(const wnd:tForm);
begin
    if Assigned(wnd) and (wnd.OnDeactivate<>@_WSE_onDeactivate_myCustom) then begin
       _ide_object_WSE_onDeactivate_original:=wnd.OnDeactivate;
        wnd.OnDeactivate:=@_WSE_onDeactivate_myCustom;
        {$ifDEF _EventLOG_}
        DEBUG('_SEW_rePlace_onDeactivate','rePALCE wnd'+addr2txt(wnd));
        {$endIf}
    end
    else begin
        {$ifDEF _EventLOG_}
        DEBUG('_SEW_rePlace_onDeactivate','SKIP wnd'+addr2txt(wnd));
        {$endIf}
    end
end;

// ВОСТАНАВЛИВАЕМ `onDeactivate` на то что было
procedure tIn0k_lazIdeSRC_SourceEditor_onActivate._WSE_reStore_onDeactivate(const wnd:tForm);
begin
    if Assigned(wnd) and (wnd.OnDeactivate=@_WSE_onDeactivate_myCustom) then begin
        wnd.OnDeactivate:=_ide_object_WSE_onDeactivate_original;
       _ide_object_WSE_onDeactivate_original:=NIL;
        {$ifDEF _EventLOG_}
        DEBUG('_SEW_reStore_onDeactivate','wnd'+addr2txt(wnd));
        {$endIf}
    end
    else begin
        {$ifDEF _EventLOG_}
        DEBUG('_SEW_reStore_onDeactivate','SKIP wnd'+addr2txt(wnd));
        {$endIf}
    end;
end;

//------------------------------------------------------------------------------

procedure tIn0k_lazIdeSRC_SourceEditor_onActivate._WSE_set_(const wnd:TSourceEditorWindowInterface);
begin
    if wnd<>_ide_object_WSE_ then begin
        if Assigned(_ide_object_WSE_)
        then begin
           _WSE_reStore_onDeactivate(_ide_object_WSE_);
            {$ifDEF _EventLOG_}
            DEBUG('ERROR','_SEW_SET inline var _ide_Window_SEW_<>NIL');
            ShowMessage('_SEW_SET inline var _ide_Window_SEW_<>NIL'+_cPleaseReport_);
            {$endIf}
        end;
       _WSE_rePlace_onDeactivate(wnd);
       _ide_object_WSE_:=wnd;
    end;
end;

{%endRegion}

{%region --- IdeEVENT semEditorActivate --------------------------- /fold}

// основное рабочее событие
procedure tIn0k_lazIdeSRC_SourceEditor_onActivate._ideEvent_SUMMARY;
var tmpSourceEditor:TSourceEditorInterface;
begin
    {*1> причины использования _ide_object_ESE_
        механизм с приходится использовать из-за того, что
        при переключение "Вкладок Редактора Исходного Кода" вызов данного
        события происходит аж 3(три) раза. Используем только ПЕРВЫЙ вход.
        -----
        еще это событие происходит КОГДА идет навигация (прыжки внутри файла)
    }
    if Assigned(SourceEditorManagerIntf) then begin //< запредельной толщины презерватив
        tmpSourceEditor:=SourceEditorManagerIntf.ActiveEditor;
        if Assigned(tmpSourceEditor) then begin //< чуть потоньше, но тоже толстоват
            if (tmpSourceEditor<>_ide_object_ESE_) then begin
               _ESE_set_(tmpSourceEditor);
            end
            else begin
                {$ifDEF _EventLOG_}
                DEBUG('SKIP','already processed');
                {$endIf}
            end;
        end
        else begin
           _ESE_set_(nil);
            {$ifDEF _EventLOG_}
            DEBUG('ER','ActiveEditor is NULL');
            {$endIf}
        end;
    end
    else begin
        {$ifDEF _EventLOG_}
        DEBUG('ER','IDE not ready');
        {$endIf}
    end;
end;

//------------------------------------------------------------------------------

procedure tIn0k_lazIdeSRC_SourceEditor_onActivate._ideEvent_semEditorActivate(Sender:TObject);
begin
    {$ifDEF _EventLOG_}
    DEBUG('ideEVENT:semEditorActivate','--->>>'+' sender'+addr2txt(Sender));
    {$endIf}

    //< запускаемся только если окно редактирования в ФОКУСЕ
    if assigned(_ide_object_WSE_) then _ideEvent_SUMMARY
    else begin
        {$ifDEF _EventLOG_}
        DEBUG('SKIP','ActiveSourceWindow is UNfocused');
        {$endIf}
    end;

    {$ifDEF _EventLOG_}
    DEBUG('ideEVENT:semEditorActivate','---<<<');
    {$endIf}
end;

procedure tIn0k_lazIdeSRC_SourceEditor_onActivate._ideEvent_semWindowFocused(Sender:TObject);
begin
    {$ifDEF _EventLOG_}
    DEBUG('ideEVENT:semWindowFocused','--->>>'+' sender'+addr2txt(Sender));
    {$endIf}

    if Assigned(Sender) and (Sender is TSourceEditorWindowInterface) then begin
       _WSE_set_(TSourceEditorWindowInterface(Sender));
        if Assigned(_ide_object_WSE_) then _ideEvent_SUMMARY
        else begin
            {$ifDEF _EventLOG_}
            DEBUG('SKIP WITH ERROR','BIG ERROR: ower _ide_Window_SEW_ found');
            {$endIf}
        end;
    end
    else begin
        {$ifDEF _EventLOG_}
        DEBUG('SKIP','Sender undef');
        {$endIf}
    end;

    {$ifDEF _EventLOG_}
    DEBUG('ideEVENT:semWindowFocused','---<<<');
    {$endIf}
end;

{%endRegion}

//------------------------------------------------------------------------------

procedure tIn0k_lazIdeSRC_SourceEditor_onActivate._do_onEvent_(const Sender:TObject);
begin
    if Assigned(_onEvent_) then _onEvent_(Sender);
end;

//------------------------------------------------------------------------------

// настроить LazarusIDE для работы
procedure tIn0k_lazIdeSRC_SourceEditor_onActivate.LazarusIDE_SetUP;
begin
    SourceEditorManagerIntf.RegisterChangeEvent(semWindowFocused,  @_ideEvent_semWindowFocused);
    SourceEditorManagerIntf.RegisterChangeEvent(semEditorActivate, @_ideEvent_semEditorActivate);
end;

// очистить наши настройки из LazarusIDE
procedure tIn0k_lazIdeSRC_SourceEditor_onActivate.LazarusIDE_Clean;
begin
    SourceEditorManagerIntf.UnRegisterChangeEvent(semWindowFocused,  @_ideEvent_semWindowFocused);
    SourceEditorManagerIntf.UnRegisterChangeEvent(semEditorActivate, @_ideEvent_semEditorActivate);
end;

end.

