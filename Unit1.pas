unit Unit1;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, sSkinManager, Vcl.StdCtrls, sListBox,
  sGroupBox, ZipForge, Vcl.ExtCtrls, sPanel, Vcl.Mask, sMaskEdit,
  sCustomComboEdit, sToolEdit, sLabel, Vcl.Menus, sButton, sBevel, StrUtils,
  acArcControls, Vcl.ComCtrls, sPageControl, sCheckBox, sComboBox;

type
  TForm1 = class(TForm)
    sSkinManager1: TsSkinManager;
    TrayIcon1: TTrayIcon;
    TrayPopupMenu: TPopupMenu;
    N8: TMenuItem;
    N9: TMenuItem;
    N10: TMenuItem;
    N11: TMenuItem;
    N12: TMenuItem;
    OpenDialog1: TOpenDialog;
    SaveDialog1: TSaveDialog;
    loading_panel: TsPanel;
    loading_label: TsLabel;
    sArcPreloader1: TsArcPreloader;
    sPageControl1: TsPageControl;
    sTabSheet1: TsTabSheet;
    sLabel1: TsLabel;
    sLabel2: TsLabel;
    hide_programm_to_tray_button: TsButton;
    source_folder_path_directory_edit: TsDirectoryEdit;
    zip_file_folder_path_directory_edit: TsDirectoryEdit;
    sTabSheet2: TsTabSheet;
    sGroupBox1: TsGroupBox;
    open_project_button: TsButton;
    save_project_button: TsButton;
    sButton5: TsButton;
    sLabel3: TsLabel;
    filename_type_combobox: TsComboBox;
    hide_programm_to_tray_checkBox: TsCheckBox;
    sGroupBox2: TsGroupBox;
    procedure N8Click(Sender: TObject);
    procedure hide_programm_to_tray_buttonClick(Sender: TObject);
    procedure archive_folder_buttonClick(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure TrayIcon1Click(Sender: TObject);
    procedure N10Click(Sender: TObject);
    procedure unzip_file_buttonClick(Sender: TObject);
    procedure N12Click(Sender: TObject);
    procedure save_project_buttonClick(Sender: TObject);
    procedure open_project_buttonClick(Sender: TObject);
    procedure sButton5Click(Sender: TObject);
  private
    { Private declarations }
  public
    { Public declarations }
  end;
//????? ?????? TMyThread:
TMyThread = class(TThread)
protected
procedure Execute; override;
procedure Do_action;
end;
//????? ?????? ??????

var
  Form1: TForm1;

//????? ??????????
MyThread:TMyThread; //?????
action,thread_action:string;
program_status:string;
information_message:string;
error:boolean;
ZipForge:TZipForge;
source_folder_path,zip_file_folder_path,zip_file_path:string;
hide_programm_to_tray,filename_type:string;
last_zip_file_path,current_project_path:string;
source_folder_exist,zip_file_folder_exist:boolean;
implementation

{$R *.dfm}

//??????? ??????????? ?????? ?? ?????? ?? ???????? ???????
function copy_part_of_string(string_text, string_symbol: string): string;
var
n: word;
begin
n:=pos(string_symbol,string_text);
Result:=copy(string_text,1,n-1);
end;


//??????? ???????? ?????? ?? ?????? ?? ???????? ???????
function delete_part_of_string(string_text, string_symbol: string): string;
var
n: word;
begin
n:= pos(string_symbol,string_text);
delete(string_text,1,n);
Result:=string_text;
end;

//??????? ????????? ??????????? ????? ??????  (??? Delphi 10)
function get_stext(First, Second, Where: string): string;
var
Pos1, Pos2: Integer;
WhereLower: string;
begin
First:=LowerCase(First);
Second:=LowerCase(Second);
WhereLower:=LowerCase(Where);
Assert(Length(WhereLower) = Length(Where));
Pos1:=PosEx(First, WhereLower, 1);
Pos2:=PosEx(Second, WhereLower, Pos1);
Result:=Copy(Where, Pos1 + Length(First), Pos2 - Pos1 - Length(First));
end;

//??????? ???????? ????????? ????????? (???????) ? ??????
function CountPos(const subtext: string; Text: string): Integer;
begin
if (Length(subtext)=0) or (Length(Text)=0) or (Pos(subtext, Text)=0) then
Result:=0
else
Result:=(Length(Text)-Length(StringReplace(Text, subtext, '', [rfReplaceAll]))) div
Length(subtext);
end;


//????????? ??? ????????? ??????? ? ????
procedure save_project_to_file(file_path:string);
var
i:integer;
FS: TFileStream;
file_data_list:TStringlist;
begin
source_folder_path:=Form1.source_folder_path_directory_edit.Text;
zip_file_folder_path:=Form1.zip_file_folder_path_directory_edit.Text;
if (Form1.hide_programm_to_tray_checkBox.Checked=true) then hide_programm_to_tray:='1' else hide_programm_to_tray:='0';
if (Form1.filename_type_combobox.ItemIndex=0) then filename_type:='normal';
if (Form1.filename_type_combobox.ItemIndex=1) then filename_type:='inextricable';
if (Form1.filename_type_combobox.ItemIndex=2) then filename_type:='numerical';




file_data_list:=tstringlist.create;
file_data_list.add('<?xml version="1.0" encoding="ANSI"?>');
file_data_list.add('<PROJECT_SETTINGS>');
file_data_list.add('<SOURCE_FOLDER_PATH>'+source_folder_path+'</SOURCE_FOLDER_PATH>');
file_data_list.add('<ZIP_FILE_FOLDER_PATH>'+zip_file_folder_path+'</ZIP_FILE_FOLDER_PATH>');
file_data_list.add('<HIDE_PROGRAMM_TO_TRAY>'+hide_programm_to_tray+'</HIDE_PROGRAMM_TO_TRAY>');
file_data_list.add('<FILENAME_TYPE>'+filename_type+'</FILENAME_TYPE>');
file_data_list.add('</PROJECT_SETTINGS>');
file_data_list.SaveToFile(file_path);
file_data_list.free;
end;


//????????? ??? ????????? ??????? ?? ?????
procedure read_project_from_file(file_path:string);
var
current_string:string;
text_file:TextFile;
income_tags:boolean;
begin
AssignFile (text_file, file_path);
Reset (text_file);
while not EOF(text_file) do
begin
readln(text_file, current_string);

if (CountPos('<PROJECT_SETTINGS>',current_string)>0) then income_tags:=true;
if (CountPos('</PROJECT_SETTINGS>',current_string)>0) then income_tags:=false;

if (income_tags=true) then
begin
if (CountPos('<SOURCE_FOLDER_PATH>',current_string)>0) then source_folder_path:=get_stext('<SOURCE_FOLDER_PATH>','</SOURCE_FOLDER_PATH>',current_string);
if (CountPos('<ZIP_FILE_FOLDER_PATH>',current_string)>0) then zip_file_folder_path:=get_stext('<ZIP_FILE_FOLDER_PATH>','</ZIP_FILE_FOLDER_PATH>',current_string);
end;

//????????? ?????
if (income_tags=false) then
begin
Form1.source_folder_path_directory_edit.Text:=source_folder_path;
Form1.zip_file_folder_path_directory_edit.Text:=zip_file_folder_path;
end;
end;
CloseFile (text_file);
end;



//????????????? ??? ????? - ??????? (normal), ??????????? (inextricable), ???????? (numerical)
function generate_filename(filename_type:string):string;
var
today : TDateTime;
result_filename:string;
str_date,str_time:string;
begin
result_filename:='can_not_generate_filename';
today := Now;
str_date:=DateToStr(today);
str_time:=TimeToStr(today);

//? ??????????? ?? ???????? ???? ? ????? (????) ????? ???? ? . ???  /
//???????? ?? ? ?????? ???? ? .
str_date:=StringReplace(str_date, '/', '.', [rfReplaceAll]);
//??? ????? ?? ????? ????????? :
str_time:=StringReplace(str_time, '/', '_', [rfReplaceAll]);
str_time:=StringReplace(str_time, ':', '_', [rfReplaceAll]);

if (filename_type='normal') then result_filename:=str_date+' '+str_time;

if (filename_type='inextricable') then
begin
str_date:=StringReplace(str_date, '.', '_', [rfReplaceAll]);
result_filename:=str_date+'_'+str_time;
end;

if (filename_type='numerical') then
begin
str_date:=StringReplace(str_date, '.', '', [rfReplaceAll]);
str_time:=StringReplace(str_time, ':', '', [rfReplaceAll]);
result_filename:=str_date+str_time;
end;

Result:=result_filename;
end;








//???? ? ?????, ???? ? ???????????? ??????
procedure ZipFolder(source_folder_path,zip_file_folder_path,filename_type:string);
begin
//?????????? ??? ????? ? ????????? ??? ? ????
if ((filename_type<>'inextricable') or (filename_type<>'numerical')) then filename_type:='normal';
zip_file_path:=zip_file_folder_path+'\'+generate_filename(filename_type)+'.zip';
ZipForge:=TZipForge.Create(nil);
ZipForge.BaseDir:=source_folder_path;
ZipForge.FileName:=zip_file_path;
ZipForge.OpenArchive(fmCreate);
ZipForge.AddFiles('*.*', faAnyFile - faDirectory);
ZipForge.CloseArchive;
ZipForge.Free;
end;

procedure UnzipFile(zip_file_folder_path,unzip_source_folder_path:string);
begin
ZipForge:=TZipForge.Create(nil);
ZipForge.FileName:=zip_file_path;
ZipForge.OpenArchive;
ZipForge.BaseDir:=unzip_source_folder_path;
ZipForge.ExtractFiles('*.*');
ZipForge.CloseArchive;
ZipForge.Free;
end;

procedure hide_programm();
begin
program_status:='tray';
Form1.TrayIcon1.visible:=true;
ShowWindow(Form1.Handle,SW_HIDE);
ShowWindow(Application.Handle,SW_HIDE);
SetWindowLong(Application.Handle, GWL_EXSTYLE,
GetWindowLong(Application.Handle, GWL_EXSTYLE) or (not WS_EX_APPWINDOW));
end;

procedure ShowProgramm();
begin
program_status:='normal';
Form1.TrayIcon1.ShowBalloonHint;
ShowWindow(Form1.Handle,SW_RESTORE);
SetForegroundWindow(Form1.Handle);
Form1.TrayIcon1.Visible:=False;
end;

procedure show_message();
begin
if (program_status='tray') then
begin
Form1.TrayIcon1.visible:=true;
Form1.TrayIcon1.balloontitle:='';
Form1.TrayIcon1.balloonhint:=information_message;
Form1.TrayIcon1.showballoonHint;
end;
if (program_status='normal') then
begin
Form1.loading_label.Caption:=information_message;

end;
end;




//???????????? ????????? ?????????
procedure enable_interface();
begin
form1.loading_panel.visible:=false;
end;

//?????????????? ????????? ?????????
procedure disable_interface();
begin
form1.loading_panel.visible:=true;
end;

//???????? ????????? ? ?????
procedure get_form_settings();
begin
source_folder_path:=Form1.source_folder_path_directory_edit.Text;
zip_file_folder_path:=Form1.zip_file_folder_path_directory_edit.Text;
end;




//????????? ????????? ? ?????
procedure check_form_settings();
begin
if (source_folder_path='') then
if (zip_file_folder_path='')then
end;

//???????? ? ??????
procedure TMyThread.Do_action();
begin
if (action='enable_interface') then enable_interface();
if (action='disable_interface') then disable_interface();
if (action='show_message') then show_message();
if (action='get_form_settings') then get_form_settings();
end;




//????????? ?????? TMyThread
procedure TMyThread.Execute;
label
End_of_the_programm;
var
i,j,k,h,n:integer; //????????
begin
error:=false;
//????????? ?????????
action:='disable_interface'; Synchronize(do_action);

//????????? ????????????? ? ??????????? ?????
source_folder_exist:=DirectoryExists(source_folder_path);
zip_file_folder_exist:=DirectoryExists(zip_file_folder_path);

//???? ???? ?? ???? ?? ????? ??????????, ?? ?????? ????????? ?????????? - ????????? ? ?????????? ?????????
//????? ????????? ???? ????? ?????????? ? ??????? ? ?????????? ?????????
if (source_folder_exist=false) then begin information_message:='???????????? ????? ??????????'; action:='show_message'; Synchronize(do_action); goto End_of_the_programm; end;
if (zip_file_folder_exist=false) then begin information_message:='????? ? ???????? ??????????'; action:='show_message'; Synchronize(do_action); goto End_of_the_programm; end;


//???????? ??? ????????? ? ?????
action:='get_form_settings'; Synchronize(do_action);


//????????????? ?????
if (thread_action='archive_folder') then
begin
information_message:='???????????? ?????'; action:='show_message'; Synchronize(do_action);
try
ZipFolder(source_folder_path,zip_file_folder_path,filename_type);
except
error:=true;
information_message:='?????? ????????????? ?????'; action:='show_message'; Synchronize(do_action);
end;
if (error=false) then
begin
information_message:='????? ??????? ??????'; action:='show_message'; Synchronize(do_action);
last_zip_file_path:=zip_file_path;
end;
end;

//???????????????? ?????
if (thread_action='unzip_file') then
begin

if (last_zip_file_path<>'') then
begin
information_message:='?????????????? ?????'; action:='show_message'; Synchronize(do_action);
try
UnzipFile(last_zip_file_path,source_folder_path);
except
error:=true;
information_message:='?????? ???????????????? ?????'; action:='show_message'; Synchronize(do_action);
end;
if (error=false) then information_message:='????? ??????? ??????????????'; action:='show_message'; Synchronize(do_action);
end;

if (last_zip_file_path='') then
begin
information_message:='?????? ???????????????'; action:='show_message'; Synchronize(do_action);
end;
end;



End_of_the_programm:
//???????????? ?????????
action:='enable_interface'; Synchronize(do_action);
end;







procedure TForm1.FormCreate(Sender: TObject);
begin
last_zip_file_path:='';
Form1.loading_panel.Left:=0;
Form1.loading_panel.Top:=0;



end;

procedure TForm1.N10Click(Sender: TObject);
begin
Form1.Close;
end;





procedure TForm1.N8Click(Sender: TObject);
begin
ShowProgramm();
end;

procedure TForm1.open_project_buttonClick(Sender: TObject);
begin
if not OpenDialog1.Execute then Exit;
read_project_from_file(OpenDialog1.FileName);
//????????? ??????? ?????? ? ?????????? ??????
form1.save_project_button.Enabled:=true;
current_project_path:=OpenDialog1.FileName;
end;

procedure TForm1.hide_programm_to_tray_buttonClick(Sender: TObject);
begin
hide_programm();
end;


procedure TForm1.save_project_buttonClick(Sender: TObject);
begin
save_project_to_file(current_project_path);
end;

procedure TForm1.sButton5Click(Sender: TObject);
begin
if not SaveDialog1.Execute then Exit;
form1.save_project_button.Enabled:=true;
current_project_path:=SaveDialog1.FileName;
save_project_to_file(SaveDialog1.FileName);
end;

procedure TForm1.archive_folder_buttonClick(Sender: TObject);
begin
thread_action:='archive_folder';
MyThread:=TMyThread.Create(False);
MyThread.Priority:=tpNormal;
end;

procedure TForm1.TrayIcon1Click(Sender: TObject);
begin
thread_action:='archive_folder';
MyThread:=TMyThread.Create(False);
MyThread.Priority:=tpNormal;
end;

procedure TForm1.unzip_file_buttonClick(Sender: TObject);
begin
thread_action:='unzip_file';
MyThread:=TMyThread.Create(False);
MyThread.Priority:=tpNormal;
end;

procedure TForm1.N12Click(Sender: TObject);
begin
thread_action:='unzip_file';
MyThread:=TMyThread.Create(False);
MyThread.Priority:=tpNormal;
end;



end.
