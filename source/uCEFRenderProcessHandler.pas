// ************************************************************************
// ***************************** CEF4Delphi *******************************
// ************************************************************************
//
// CEF4Delphi is based on DCEF3 which uses CEF3 to embed a chromium-based
// browser in Delphi applications.
//
// The original license of DCEF3 still applies to CEF4Delphi.
//
// For more information about CEF4Delphi visit :
//         https://www.briskbard.com/index.php?lang=en&pageid=cef
//
//        Copyright � 2017 Salvador D�az Fau. All rights reserved.
//
// ************************************************************************
// ************ vvvv Original license and comments below vvvv *************
// ************************************************************************
(*
 *                       Delphi Chromium Embedded 3
 *
 * Usage allowed under the restrictions of the Lesser GNU General Public License
 * or alternatively the restrictions of the Mozilla Public License 1.1
 *
 * Software distributed under the License is distributed on an "AS IS" basis,
 * WITHOUT WARRANTY OF ANY KIND, either express or implied. See the License for
 * the specific language governing rights and limitations under the License.
 *
 * Unit owner : Henri Gourvest <hgourvest@gmail.com>
 * Web site   : http://www.progdigy.com
 * Repository : http://code.google.com/p/delphichromiumembedded/
 * Group      : http://groups.google.com/group/delphichromiumembedded
 *
 * Embarcadero Technologies, Inc is not permitted to use or redistribute
 * this source code without explicit permission.
 *
 *)

unit uCEFRenderProcessHandler;

{$IFNDEF CPUX64}
  {$ALIGN ON}
  {$MINENUMSIZE 4}
{$ENDIF}

{$I cef.inc}

interface

uses
  {$IFDEF DELPHI16_UP}
  System.Classes,
  {$ELSE}
  Classes,
  {$ENDIF}
  uCEFBaseRefCounted, uCEFInterfaces, uCEFTypes, uCEFListValue, uCEFBrowser, uCEFFrame, uCEFRequest,
  uCEFv8Context, uCEFv8Exception, uCEFv8StackTrace, uCEFDomNode, uCEFProcessMessage;

type
  TCefRenderProcessHandlerOwn = class(TCefBaseRefCountedOwn, ICefRenderProcessHandler)
    protected
      procedure OnRenderThreadCreated(const extraInfo: ICefListValue); virtual;
      procedure OnWebKitInitialized; virtual;
      procedure OnBrowserCreated(const browser: ICefBrowser); virtual;
      procedure OnBrowserDestroyed(const browser: ICefBrowser); virtual;
      function  GetLoadHandler: PCefLoadHandler; virtual;
      function  OnBeforeNavigation(const browser: ICefBrowser; const frame: ICefFrame; const request: ICefRequest; navigationType: TCefNavigationType; isRedirect: Boolean): Boolean; virtual;
      procedure OnContextCreated(const browser: ICefBrowser; const frame: ICefFrame; const context: ICefv8Context); virtual;
      procedure OnContextReleased(const browser: ICefBrowser; const frame: ICefFrame; const context: ICefv8Context); virtual;
      procedure OnUncaughtException(const browser: ICefBrowser; const frame: ICefFrame; const context: ICefv8Context; const exception: ICefV8Exception; const stackTrace: ICefV8StackTrace); virtual;
      procedure OnFocusedNodeChanged(const browser: ICefBrowser; const frame: ICefFrame; const node: ICefDomNode); virtual;
      function  OnProcessMessageReceived(const browser: ICefBrowser; sourceProcess: TCefProcessId; const message: ICefProcessMessage): Boolean; virtual;
    public
      constructor Create; virtual;
  end;

  TCefCustomRenderProcessHandler = class(TCefRenderProcessHandlerOwn)
    protected
      FMessageName     : ustring;
      FOnCustomMessage : TOnCustomMessage;
      FOnWebKitReady   : TOnWebKitReady;

      procedure OnWebKitInitialized; override;
      function  OnProcessMessageReceived(const browser: ICefBrowser; sourceProcess: TCefProcessId; const message: ICefProcessMessage): Boolean; override;

    public
      constructor Create; override;

      property MessageName     : ustring            read FMessageName       write FMessageName;
      property OnCustomMessage : TOnCustomMessage   read FOnCustomMessage   write FOnCustomMessage;
      property OnWebKitReady   : TOnWebKitReady     read FOnWebKitReady     write FOnWebKitReady;
  end;

implementation

uses
  uCEFMiscFunctions, uCEFLibFunctions;


procedure cef_render_process_handler_on_render_thread_created(
  self: PCefRenderProcessHandler; extra_info: PCefListValue); stdcall;
begin
  with TCefRenderProcessHandlerOwn(CefGetObject(Self)) do
    OnRenderThreadCreated(TCefListValueRef.UnWrap(extra_info));
end;

procedure cef_render_process_handler_on_web_kit_initialized(self: PCefRenderProcessHandler); stdcall;
begin
  with TCefRenderProcessHandlerOwn(CefGetObject(Self)) do
    OnWebKitInitialized;
end;

procedure cef_render_process_handler_on_browser_created(self: PCefRenderProcessHandler;
  browser: PCefBrowser); stdcall;
begin
  with TCefRenderProcessHandlerOwn(CefGetObject(Self)) do
    OnBrowserCreated(TCefBrowserRef.UnWrap(browser));
end;

procedure cef_render_process_handler_on_browser_destroyed(self: PCefRenderProcessHandler;
  browser: PCefBrowser); stdcall;
begin
  with TCefRenderProcessHandlerOwn(CefGetObject(Self)) do
    OnBrowserDestroyed(TCefBrowserRef.UnWrap(browser));
end;

function cef_render_process_handler_get_load_handler(self: PCefRenderProcessHandler): PCefLoadHandler; stdcall;
begin
  with TCefRenderProcessHandlerOwn(CefGetObject(Self)) do
    Result := GetLoadHandler();
end;

function cef_render_process_handler_on_before_navigation(self: PCefRenderProcessHandler;
  browser: PCefBrowser; frame: PCefFrame; request: PCefRequest;
  navigation_type: TCefNavigationType; is_redirect: Integer): Integer; stdcall;
begin
  with TCefRenderProcessHandlerOwn(CefGetObject(Self)) do
    Result := Ord(OnBeforeNavigation(TCefBrowserRef.UnWrap(browser),
      TCefFrameRef.UnWrap(frame), TCefRequestRef.UnWrap(request),
      navigation_type, is_redirect <> 0));
end;

procedure cef_render_process_handler_on_context_created(self: PCefRenderProcessHandler;
  browser: PCefBrowser; frame: PCefFrame; context: PCefv8Context); stdcall;
begin
  with TCefRenderProcessHandlerOwn(CefGetObject(Self)) do
    OnContextCreated(TCefBrowserRef.UnWrap(browser), TCefFrameRef.UnWrap(frame), TCefv8ContextRef.UnWrap(context));
end;

procedure cef_render_process_handler_on_context_released(self: PCefRenderProcessHandler;
  browser: PCefBrowser; frame: PCefFrame; context: PCefv8Context); stdcall;
begin
  with TCefRenderProcessHandlerOwn(CefGetObject(Self)) do
    OnContextReleased(TCefBrowserRef.UnWrap(browser), TCefFrameRef.UnWrap(frame), TCefv8ContextRef.UnWrap(context));
end;

procedure cef_render_process_handler_on_uncaught_exception(self: PCefRenderProcessHandler;
  browser: PCefBrowser; frame: PCefFrame; context: PCefv8Context;
  exception: PCefV8Exception; stackTrace: PCefV8StackTrace); stdcall;
begin
  with TCefRenderProcessHandlerOwn(CefGetObject(Self)) do
    OnUncaughtException(TCefBrowserRef.UnWrap(browser), TCefFrameRef.UnWrap(frame),
      TCefv8ContextRef.UnWrap(context), TCefV8ExceptionRef.UnWrap(exception),
      TCefV8StackTraceRef.UnWrap(stackTrace));
end;

procedure cef_render_process_handler_on_focused_node_changed(self: PCefRenderProcessHandler;
  browser: PCefBrowser; frame: PCefFrame; node: PCefDomNode); stdcall;
begin
  with TCefRenderProcessHandlerOwn(CefGetObject(Self)) do
    OnFocusedNodeChanged(TCefBrowserRef.UnWrap(browser), TCefFrameRef.UnWrap(frame),
      TCefDomNodeRef.UnWrap(node));
end;

function cef_render_process_handler_on_process_message_received(self: PCefRenderProcessHandler;
  browser: PCefBrowser; source_process: TCefProcessId;
  message: PCefProcessMessage): Integer; stdcall;
begin
  with TCefRenderProcessHandlerOwn(CefGetObject(Self)) do
    Result := Ord(OnProcessMessageReceived(TCefBrowserRef.UnWrap(browser), source_process,
      TCefProcessMessageRef.UnWrap(message)));
end;


// TCefRenderProcessHandlerOwn


constructor TCefRenderProcessHandlerOwn.Create;
begin
  inherited CreateData(SizeOf(TCefRenderProcessHandler));

  with PCefRenderProcessHandler(FData)^ do
    begin
      on_render_thread_created    := cef_render_process_handler_on_render_thread_created;
      on_web_kit_initialized      := cef_render_process_handler_on_web_kit_initialized;
      on_browser_created          := cef_render_process_handler_on_browser_created;
      on_browser_destroyed        := cef_render_process_handler_on_browser_destroyed;
      get_load_handler            := cef_render_process_handler_get_load_handler;
      on_before_navigation        := cef_render_process_handler_on_before_navigation;
      on_context_created          := cef_render_process_handler_on_context_created;
      on_context_released         := cef_render_process_handler_on_context_released;
      on_uncaught_exception       := cef_render_process_handler_on_uncaught_exception;
      on_focused_node_changed     := cef_render_process_handler_on_focused_node_changed;
      on_process_message_received := cef_render_process_handler_on_process_message_received;
    end;
end;

function TCefRenderProcessHandlerOwn.GetLoadHandler: PCefLoadHandler;
begin
  Result := nil;
end;

function TCefRenderProcessHandlerOwn.OnBeforeNavigation(
  const browser: ICefBrowser; const frame: ICefFrame;
  const request: ICefRequest; navigationType: TCefNavigationType;
  isRedirect: Boolean): Boolean;
begin
  Result := False;
end;

procedure TCefRenderProcessHandlerOwn.OnBrowserCreated(
  const browser: ICefBrowser);
begin

end;

procedure TCefRenderProcessHandlerOwn.OnBrowserDestroyed(
  const browser: ICefBrowser);
begin

end;

procedure TCefRenderProcessHandlerOwn.OnContextCreated(
  const browser: ICefBrowser; const frame: ICefFrame;
  const context: ICefv8Context);
begin

end;

procedure TCefRenderProcessHandlerOwn.OnContextReleased(
  const browser: ICefBrowser; const frame: ICefFrame;
  const context: ICefv8Context);
begin

end;

procedure TCefRenderProcessHandlerOwn.OnFocusedNodeChanged(
  const browser: ICefBrowser; const frame: ICefFrame; const node: ICefDomNode);
begin

end;

function TCefRenderProcessHandlerOwn.OnProcessMessageReceived(
  const browser: ICefBrowser; sourceProcess: TCefProcessId;
  const message: ICefProcessMessage): Boolean;
begin
  Result := False;
end;

procedure TCefRenderProcessHandlerOwn.OnRenderThreadCreated(const extraInfo: ICefListValue);
begin

end;

procedure TCefRenderProcessHandlerOwn.OnUncaughtException(
  const browser: ICefBrowser; const frame: ICefFrame;
  const context: ICefv8Context; const exception: ICefV8Exception;
  const stackTrace: ICefV8StackTrace);
begin

end;

procedure TCefRenderProcessHandlerOwn.OnWebKitInitialized;
begin

end;


// TCefCustomRenderProcessHandler

constructor TCefCustomRenderProcessHandler.Create;
begin
  inherited Create;

  FMessageName     := '';
  FOnCustomMessage := nil;
  FOnWebKitReady   := nil;
end;

procedure TCefCustomRenderProcessHandler.OnWebKitInitialized;
begin
  if assigned(FOnWebKitReady) then FOnWebKitReady();
end;

function TCefCustomRenderProcessHandler.OnProcessMessageReceived(const browser       : ICefBrowser;
                                                                       sourceProcess : TCefProcessId;
                                                                 const message       : ICefProcessMessage): Boolean;
begin
  if assigned(FOnCustomMessage) and (message.Name = FMessageName) then
    begin
      FOnCustomMessage(browser, sourceProcess, message);
      Result := True;
    end
   else
    Result := inherited OnProcessMessageReceived(browser, sourceProcess, message);
end;

end.
