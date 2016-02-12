unit in0k_lazIdeSRC_SourceEditor_onActivate;

{todo: описание и документация}

interface

{%region --- Описание НАСТРОЕК уровня КОМПИЛЯЦИИ ----------------- /fold }

//// ВНИМАНИЕ !!!
//// настройки могут быть ПЕРЕОПРЕДЕЛЕНЫ ниже при подключении
//// файла настроек "компанента-Расширения" (`in0k_lazExt_SETTINGs.inc`).

//--- # DebugLOG_mode ----------------------------------------------------------
// Режим логирования.
//  В код включаются вызовы `DEBUG` с описанием текущих событий и состояний.
//
//{$define in0k_lazIdeSRC_SourceEditor_onActivate__DebugLOG_mode}
//
//------------------------------------------------------------------------------

//--- # inFocusONLY ------------------------------------------------------------
// Только в АКТИВНОМ окне.
//  Пользовательское событие `onEvent` вызывается ТОЛЬКО если редактор кода
//  находится в фокусе (тоесть окно "Редактор Кода" АКТИВНО).
//
//{$define in0k_lazIdeSRC_SourceEditor_onActivate__inFocusONLY}
//
//------------------------------------------------------------------------------

{%endregion}

{$i in0k_lazExt_SETTINGs.inc} //< настройки "компанента-Расширения".
//< Можно смело убирать, так как будеть работать только в моей специальной
//< "системе имен и папок" `in0k_LazExt_..`.


uses {$ifDef in0k_lazIdeSRC_SourceEditor_onActivate__DebugLOG_mode}in0k_lazExt_DEBUG,{$endIf}
    SrcEditorIntf, //< you must use IDEIntf
    Forms, Classes;

type

 tIn0k_lazIdeSRC_SourceEditor_onActivate=class
  {%region --- onActivate EVENT ----------------------------------- /fold}
  protected
  _onEvent_:TNotifyEvent;
   procedure _do_onEvent_; virtual;
  {%endRegion}
  {%region --- Active Editor SourceEditor ------------------------- /fold}
  private //< текущий АКТИВНЫЙ редактор в окне (вкладка, таб)
   _ide_object_ESE_:TSourceEditorInterface;
    procedure _ESE_set_(const value:TSourceEditorInterface);
  {%endRegion}
  {$ifDef in0k_lazIdeSRC_SourceEditor_onActivate__inFocusONLY}
  {%region --- Active Window SourceEditor ------------------------- /fold}
  private //< текущee АКТИВНОЕ окно редактирования
   _ide_object_WSE_:TSourceEditorWindowInterface;
    procedure _WSE_set_(const wnd:TSourceEditorWindowInterface);
  private
   _ide_object_WSE_onDeactivate_original_:TNotifyEvent;    //< его событие
    procedure _WSE_onDeactivate_myCustom_(Sender:TObject); //< моя подстава
    procedure _WSE_rePlace_onDeactivate_(const wnd:tForm);
    procedure _WSE_reStore_onDeactivate_(const wnd:tForm);
  {%endRegion}
  {$endIf}
  {%region --- IdeEVENT ------------------------------------------- /fold}
  private //< основное событие
    procedure _ideEvent_SUMMARY;
  private //< обработка событий IDE Lazarus
    procedure _ideEvent_semEditorActivate({%H-}Sender:TObject);
    {$ifDef in0k_lazIdeSRC_SourceEditor_onActivate__inFocusONLY}
    procedure _ideEvent_semWindowFocused (     Sender:TObject);
    {$endIf}
  {%endRegion}
  public
    property    onEvent:TNotifyEvent read _onEvent_ write _onEvent_;
    //property    SourceEditorWindow:TSourceEditorWindowInterface read _ide_object_WSE_;
    property    SourceEditor      :TSourceEditorInterface read _ide_object_ESE_;
  public
    constructor Create;
    procedure   LazarusIDE_SetUP; virtual;
    procedure   LazarusIDE_Clean; virtual;
  end;

implementation

{%region --- возня с ДЕБАГОМ -------------------------------------- /fold}
{$if defined(in0k_lazIdeSRC_FuckUpForm__DebugLOG_mode) AND declared(in0k_lazIde_DEBUG)}
    // `in0k_lazIde_DEBUG` - это функция ИНДИКАТОР что используется
    //                       моя "система имен и папок"
    {$define _debugLOG_}     //< типа да ... можно делать ДЕБАГ отметки
{$else}
    {$undef _debugLOG_}
{$endIf}
{%endregion}

constructor tIn0k_lazIdeSRC_SourceEditor_onActivate.Create;
begin
   _onEvent_:=nil;
   _ide_object_ESE_:=nil;
    {$ifDef in0k_lazIdeSRC_SourceEditor_onActivate__inFocusONLY}
   _ide_object_WSE_:=nil;
   _ide_object_WSE_onDeactivate_original_:=nil;
    {$endIf}
 end;

//------------------------------------------------------------------------------

{%region --- Active Editor SourceEditor --------------------------- /fold}

procedure tIn0k_lazIdeSRC_SourceEditor_onActivate._ESE_set_(const value:TSourceEditorInterface);
begin
    if value<>_ide_object_ESE_ then begin
      _ide_object_ESE_:=value;
      _do_onEvent_;
    end
end;

{%endRegion}

{%region --- IdeEVENT semEditorActivate --------------------------- /fold}

// основное рабочее событие
procedure tIn0k_lazIdeSRC_SourceEditor_onActivate._ideEvent_SUMMARY;
var tmpSourceEditor:TSourceEditorInterface;
begin
    {*1> причины использования _ide_object_ESE_
        механизм приходится использовать из-за того, что
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
                {$ifDEF _debugLOG_}
                DEBUG('SKIP','already processed');
                {$endIf}
            end;
        end
        else begin
           _ESE_set_(nil);
            {$ifDEF _debugLOG_}
            DEBUG('ER','ActiveEditor is NULL');
            {$endIf}
        end;
    end
    else begin
        {$ifDEF _debugLOG_}
        DEBUG('ER','IDE not ready');
        {$endIf}
    end;
end;

//------------------------------------------------------------------------------

procedure tIn0k_lazIdeSRC_SourceEditor_onActivate._ideEvent_semEditorActivate(Sender:TObject);
begin
    {$ifDEF _debugLOG_}
    DEBUG('ideEVENT:semEditorActivate','--->>>'+' sender'+addr2txt(Sender));
    {$endIf}

    {$ifDef in0k_lazIdeSRC_SourceEditor_onActivate__inFocusONLY}
    // запускаемся только если окно редактирования в ФОКУСЕ
    if Assigned(_ide_object_WSE_) then _ideEvent_SUMMARY
    else begin
        {$ifDEF _debugLOG_}
        DEBUG('SKIP','ActiveSourceWindow is UNfocused');
        {$endIf}
    end;
    {$else}
   _ideEvent_SUMMARY;
    {$endIf}

    {$ifDEF _debugLOG_}
    DEBUG('ideEVENT:semEditorActivate','---<<<');
    {$endIf}
end;

{$ifDef in0k_lazIdeSRC_SourceEditor_onActivate__inFocusONLY}
procedure tIn0k_lazIdeSRC_SourceEditor_onActivate._ideEvent_semWindowFocused(Sender:TObject);
begin
    {$ifDEF _debugLOG_}
    DEBUG('ideEVENT:semWindowFocused','--->>>'+' sender'+addr2txt(Sender));
    {$endIf}

    if Assigned(Sender) and (Sender is TSourceEditorWindowInterface) then begin
       _WSE_set_(TSourceEditorWindowInterface(Sender));
        if Assigned(_ide_object_WSE_) then _ideEvent_SUMMARY
        else begin
            {$ifDEF _debugLOG_}
            DEBUG('SKIP WITH ERROR','BIG ERROR: ower _ide_Window_SEW_ found');
            {$endIf}
        end;
    end
    else begin
        {$ifDEF _debugLOG_}
        DEBUG('SKIP','Sender undef');
        {$endIf}
    end;

    {$ifDEF _debugLOG_}
    DEBUG('ideEVENT:semWindowFocused','---<<<');
    {$endIf}
end;
{$endIf}

{%endRegion}

{$ifDef in0k_lazIdeSRC_SourceEditor_onActivate__inFocusONLY}
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
procedure tIn0k_lazIdeSRC_SourceEditor_onActivate._WSE_onDeactivate_myCustom_(Sender:TObject);
begin
    {$ifDEF _debugLOG_}
    DEBUG('_WSE_onDeactivate_myCustom_','--->>> Sender'+addr2txt(Sender));
    {$endIf}

    // отмечаем что ВЫШЛИ из окна
   _ide_object_WSE_:=NIL;
   _ESE_set_(NIL);
    // восстановить событие `onDeactivate` на исходное, и выполнияем его
    if Assigned(Sender) then begin
        if Sender is TSourceEditorWindowInterface then begin
           _WSE_reStore_onDeactivate_(tForm(Sender));
            with TSourceEditorWindowInterface(Sender) do begin
                if Assigned(OnDeactivate) then OnDeactivate(Sender);
                {$ifDEF _debugLOG_}
                DEBUG('OK','TSourceEditorWindowInterface('+addr2txt(sender)+').OnDeactivate executed');
                {$endIf}
            end;
        end
        else begin
            {$ifDEF _debugLOG_}
            DEBUG('ER','Sender is NOT TSourceEditorWindowInterface');
            {$endIf}
        end;
    end
    else begin
        {$ifDEF _debugLOG_}
        DEBUG('ER','Sender==NIL');
        {$endIf}
    end;

    {$ifDEF _debugLOG_}
    DEBUG('_WSE_onDeactivate_myCustom_','---<<<');
    {$endIf}
end;

//------------------------------------------------------------------------------

// ЗАМЕНЯЕМ `onDeactivate` на собственное
procedure tIn0k_lazIdeSRC_SourceEditor_onActivate._WSE_rePlace_onDeactivate_(const wnd:tForm);
begin
    if Assigned(wnd) and (wnd.OnDeactivate<>@_WSE_onDeactivate_myCustom_) then begin
       _ide_object_WSE_onDeactivate_original_:=wnd.OnDeactivate;
        wnd.OnDeactivate:=@_WSE_onDeactivate_myCustom_;
        {$ifDEF _debugLOG_}
        DEBUG('_WSE_rePlace_onDeactivate_','rePALCE wnd'+addr2txt(wnd));
        {$endIf}
    end
    else begin
        {$ifDEF _debugLOG_}
        DEBUG('_WSE_rePlace_onDeactivate_','SKIP wnd'+addr2txt(wnd));
        {$endIf}
    end
end;

// ВОСТАНАВЛИВАЕМ `onDeactivate` на то что было
procedure tIn0k_lazIdeSRC_SourceEditor_onActivate._WSE_reStore_onDeactivate_(const wnd:tForm);
begin
    if Assigned(wnd) and (wnd.OnDeactivate=@_WSE_onDeactivate_myCustom_) then begin
        wnd.OnDeactivate:=_ide_object_WSE_onDeactivate_original_;
       _ide_object_WSE_onDeactivate_original_:=NIL;
        {$ifDEF _debugLOG_}
        DEBUG('_WSE_reStore_onDeactivate_','wnd'+addr2txt(wnd));
        {$endIf}
    end
    else begin
        {$ifDEF _debugLOG_}
        DEBUG('_WSE_reStore_onDeactivate_','SKIP wnd'+addr2txt(wnd));
        {$endIf}
    end;
end;

//------------------------------------------------------------------------------

procedure tIn0k_lazIdeSRC_SourceEditor_onActivate._WSE_set_(const wnd:TSourceEditorWindowInterface);
begin
    if wnd<>_ide_object_WSE_ then begin
        if Assigned(_ide_object_WSE_)
        then begin
           _WSE_reStore_onDeactivate_(_ide_object_WSE_);
            {$ifDEF _debugLOG_}
            DEBUG('ERROR','_WSE_set_ inline var _ide_object_WSE_<>NIL');
            //ShowMessage('_WSE_set_ inline var _ide_object_WSE_<>NIL'+_c_DBG_PleaseReport_);
            {$endIf}
        end;
       _WSE_rePlace_onDeactivate_(wnd);
       _ide_object_WSE_:=wnd;
    end;
end;

{%endRegion}
{$endIf}

//------------------------------------------------------------------------------

procedure tIn0k_lazIdeSRC_SourceEditor_onActivate._do_onEvent_;
begin
    if Assigned(_onEvent_) then _onEvent_(SELF);
end;

//------------------------------------------------------------------------------

// настроить LazarusIDE для работы
procedure tIn0k_lazIdeSRC_SourceEditor_onActivate.LazarusIDE_SetUP;
begin
    SourceEditorManagerIntf.RegisterChangeEvent(semEditorActivate, @_ideEvent_semEditorActivate);
    {$ifDef in0k_lazIdeSRC_SourceEditor_onActivate__inFocusONLY}
    SourceEditorManagerIntf.RegisterChangeEvent(semWindowFocused,  @_ideEvent_semWindowFocused);
    {$endIf}
end;

// очистить наши настройки из LazarusIDE
procedure tIn0k_lazIdeSRC_SourceEditor_onActivate.LazarusIDE_Clean;
begin
    SourceEditorManagerIntf.UnRegisterChangeEvent(semEditorActivate, @_ideEvent_semEditorActivate);
    {$ifDef in0k_lazIdeSRC_SourceEditor_onActivate__inFocusONLY}
    SourceEditorManagerIntf.UnRegisterChangeEvent(semWindowFocused,  @_ideEvent_semWindowFocused);
    {$endIf}
end;

end.

