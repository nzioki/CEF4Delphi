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

unit uJSExtension;

{$I cef.inc}

interface

uses
  {$IFDEF DELPHI16_UP}
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.StdCtrls, Vcl.ExtCtrls, Vcl.ComCtrls,
  {$ELSE}
  Windows, Messages, SysUtils, Variants, Classes, Graphics,
  Controls, Forms, Dialogs, StdCtrls, ExtCtrls, ComCtrls,
  {$ENDIF}
  uCEFChromium, uCEFWindowParent, uCEFInterfaces, uCEFApplication, uCEFTypes, uCEFConstants;

const
  MINIBROWSER_CREATED        = WM_APP + $100;
  MINIBROWSER_SHOWTEXTVIEWER = WM_APP + $105;

  MINIBROWSER_CONTEXTMENU_SETJSEVENT   = MENU_ID_USER_FIRST + 1;
  MINIBROWSER_CONTEXTMENU_JSVISITDOM   = MENU_ID_USER_FIRST + 2;

type
  TJSExtensionFrm = class(TForm)
    NavControlPnl: TPanel;
    Edit1: TEdit;
    GoBtn: TButton;
    StatusBar1: TStatusBar;
    CEFWindowParent1: TCEFWindowParent;
    Chromium1: TChromium;
    procedure FormShow(Sender: TObject);
    procedure GoBtnClick(Sender: TObject);
    procedure Chromium1BeforeContextMenu(Sender: TObject;
      const browser: ICefBrowser; const frame: ICefFrame;
      const params: ICefContextMenuParams; const model: ICefMenuModel);
    procedure Chromium1ContextMenuCommand(Sender: TObject;
      const browser: ICefBrowser; const frame: ICefFrame;
      const params: ICefContextMenuParams; commandId: Integer;
      eventFlags: Cardinal; out Result: Boolean);
    procedure Chromium1ProcessMessageReceived(Sender: TObject;
      const browser: ICefBrowser; sourceProcess: TCefProcessId;
      const message: ICefProcessMessage; out Result: Boolean);
    procedure Chromium1AfterCreated(Sender: TObject;
      const browser: ICefBrowser);
  protected
    FText : string;

    procedure BrowserCreatedMsg(var aMessage : TMessage); message MINIBROWSER_CREATED;
    procedure ShowTextViewerMsg(var aMessage : TMessage); message MINIBROWSER_SHOWTEXTVIEWER;
    procedure WMMove(var aMessage : TWMMove); message WM_MOVE;
    procedure WMMoving(var aMessage : TMessage); message WM_MOVING;
  public
    { Public declarations }
  end;

var
  JSExtensionFrm: TJSExtensionFrm;

implementation

{$R *.dfm}

uses
  uSimpleTextViewer;

// The CEF3 document describing extensions is here :
// https://bitbucket.org/chromiumembedded/cef/wiki/JavaScriptIntegration.md

// This demo has a TTestExtension class that is registered in the OnWebKitReady event
// of a custom ProcessHandler when the application is initializing.

// TTestExtension can send information back to the browser with a process message.
// The TTestExtension.mouseover function do this by calling TCefv8ContextRef.Current.Browser.SendProcessMessage(PID_BROWSER, msg);

// TCefv8ContextRef.Current returns the v8 context for the frame that is currently executing JS,
// TCefv8ContextRef.Current.Browser.SendProcessMessage should send a message to the right browser even
// if you have created several browsers in one app.

// That message is received in the TChromium.OnProcessMessageReceived event.
// Even if you create several TChromium objects you should have no problem because each of them will have its own
// TChromium.OnProcessMessageReceived event to receive the messages from the extension.

procedure TJSExtensionFrm.GoBtnClick(Sender: TObject);
begin
  Chromium1.LoadURL(Edit1.Text);
end;

procedure TJSExtensionFrm.Chromium1AfterCreated(Sender: TObject;
  const browser: ICefBrowser);
begin
  PostMessage(Handle, MINIBROWSER_CREATED, 0, 0);
end;

procedure TJSExtensionFrm.Chromium1BeforeContextMenu(Sender: TObject;
  const browser: ICefBrowser; const frame: ICefFrame;
  const params: ICefContextMenuParams; const model: ICefMenuModel);
begin
  // Adding some custom context menu entries
  model.AddSeparator;
  model.AddItem(MINIBROWSER_CONTEXTMENU_SETJSEVENT,  'Set mouseover event');
  model.AddItem(MINIBROWSER_CONTEXTMENU_JSVISITDOM,  'Visit DOM in JavaScript');
end;

procedure TJSExtensionFrm.Chromium1ContextMenuCommand(Sender: TObject;
  const browser: ICefBrowser; const frame: ICefFrame;
  const params: ICefContextMenuParams; commandId: Integer;
  eventFlags: Cardinal; out Result: Boolean);
begin
  Result := False;

  // Here is the code executed for each custom context menu entry

  case commandId of
    MINIBROWSER_CONTEXTMENU_SETJSEVENT :
      if (browser <> nil) and (browser.MainFrame <> nil) then
        browser.MainFrame.ExecuteJavaScript(
          'document.body.addEventListener("mouseover", function(evt){'+
            'function getpath(n){'+
              'var ret = "<" + n.nodeName + ">";'+
              'if (n.parentNode){return getpath(n.parentNode) + ret} else '+
              'return ret'+
            '};'+
            'myextension.mouseover(getpath(evt.target))}'+   // This is the call from JavaScript to the extension with DELPHI code in uTestExtension.pas
          ')', 'about:blank', 0);

    MINIBROWSER_CONTEXTMENU_JSVISITDOM :
      if (browser <> nil) and (browser.MainFrame <> nil) then
        browser.MainFrame.ExecuteJavaScript(
          'var testhtml = document.body.innerHTML;' +
          'myextension.sendresulttobrowser(testhtml, ''customname'');',  // This is the call from JavaScript to the extension with DELPHI code in uTestExtension.pas
          'about:blank', 0);
  end;
end;

procedure TJSExtensionFrm.Chromium1ProcessMessageReceived(Sender: TObject;
  const browser: ICefBrowser; sourceProcess: TCefProcessId;
  const message: ICefProcessMessage; out Result: Boolean);
begin
  if (message = nil) or (message.ArgumentList = nil) then exit;

  // This function receives the messages with the JavaScript results

  // Many of these events are received in different threads and the VCL
  // doesn't like to create and destroy components in different threads.

  // It's safer to store the results and send a message to the main thread to show them.

  // The message names are defined in the extension or in JS code.

  if (message.Name = 'mouseover') then
    begin
      StatusBar1.Panels[0].Text := message.ArgumentList.GetString(0); // this doesn't create/destroy components
      Result := True;
    end
   else
    if (message.Name = 'customname') then
      begin
        FText := message.ArgumentList.GetString(0);
        PostMessage(Handle, MINIBROWSER_SHOWTEXTVIEWER, 0, 0);
        Result := True;
      end
     else
      Result := False;
end;

procedure TJSExtensionFrm.FormShow(Sender: TObject);
begin
  Chromium1.CreateBrowser(CEFWindowParent1, '');
end;

procedure TJSExtensionFrm.WMMove(var aMessage : TWMMove);
begin
  inherited;

  if (Chromium1 <> nil) then Chromium1.NotifyMoveOrResizeStarted;
end;

procedure TJSExtensionFrm.WMMoving(var aMessage : TMessage);
begin
  inherited;

  if (Chromium1 <> nil) then Chromium1.NotifyMoveOrResizeStarted;
end;

procedure TJSExtensionFrm.ShowTextViewerMsg(var aMessage : TMessage);
begin
  // This form will show the HTML received from JavaScript
  SimpleTextViewerFrm.Memo1.Lines.Text := FText;
  SimpleTextViewerFrm.ShowModal;
end;

procedure TJSExtensionFrm.BrowserCreatedMsg(var aMessage : TMessage);
begin
  NavControlPnl.Enabled := True;
  GoBtn.Click;
end;

end.
