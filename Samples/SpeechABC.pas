// Copyright (c) Maxim Puchkin, Stanislav Mihalkovich (for details please see \doc\copyright.txt)
// This code is distributed under the GNU LGPL (for details please see \doc\license.txt)

///Модуль реализует воспроизведение речи (text-to-speech) на английском и русском.
///Также реализовано распознавание речи (speech recognition) русского и английского языков.
///Используется платформа Microsoft Speech Platform 11.

unit SpeechABC;
{$reference 'Microsoft.Speech.dll'}

{Для корректной работы должны быть скачаны и установлены языки - для синтеза 
    речи, и для распознавания.
    1. Скачать и установить Runtime - https://www.microsoft.com/en-us/download/details.aspx?id=27225
    2. Необязательно – скачать и установить SDK - это, наверное, не нужно https://www.microsoft.com/en-us/download/details.aspx?id=27226
    3. Скачать дополнительные языки - рекомендуются британский и английский, русский
       https://www.microsoft.com/en-us/download/details.aspx?id=27224
       Там список. Из них те, что TTS - голоса, SR - распознавалки.
       Качать en-GB, en-US и ru-RU - их надо устанавливать.
    4. В папке с этой программой должна быть Microsoft.Speech.dll, если её нет,
       то искать в папке, в которую установился SDK. 
       }
       
interface

uses Microsoft.Speech;
uses Microsoft.Speech.Synthesis;
uses Microsoft.Speech.Recognition;
uses System.Globalization;

///  Языки для воспроизведения и распознавания. Британский и американский английский синтезатором не различаются
type Languages = (Russian, English, American);
///  Статус генератора речи
type SpeakerState = (Ready, Speaking, Paused);

/// Класс для воспроизведения речи
type Speaker = class 
  private
    synth : Microsoft.Speech.Synthesis.SpeechSynthesizer;
    Lang : Languages;
    AudioVol : integer := 99;
    currRuIndex, currEngIndex : integer;

    procedure SetLang(newLang : Languages);
    function GetLang : Languages;
    procedure SetVolume(Volume : integer);
    function GetVolume : integer;

    function GetRussianVoices : System.Collections.Generic.List<InstalledVoice>;
    function GetEnglishVoices : System.Collections.Generic.List<InstalledVoice>;
    function GetState : SpeakerState;
  public
    ///  Язык воспроизведения речи – русский или английский
    property Language : Languages write SetLang;
    ///  Громкость воспроизведения (от 0 до 100)
    property Volume : integer read GetVolume write SetVolume;
    ///  Состояние воспроизведения речи
    property State : SpeakerState read GetState;
    ///  Проговорить фразу. Язык и голос используются ранее заданные
    procedure Speak(Phrase : string);
    ///  Проговорить фразу. Язык и голос используются ранее заданные. 
    ///  Не блокирует выполнение - программа продолжится не дожидаясь окончания фразы.
    procedure SpeakAsync(Phrase : string);
    ///  Конструктор объекта воспроизведения речи с заданным языком
    constructor Create(Language : Languages := Languages.Russian);
    ///  Конструктор с проговариванием указанной фразы. Язык выбирается автоматически
    constructor Create(Phrase : string);
    ///  Выбор англоговорящего голоса по индексу (индексация от 0)
    procedure SelectEnglishVoice(VoiceIndex :integer := 0);
    ///  Выбор русскоговорящего голоса по индексу (индексация от 0)
    procedure SelectRussianVoice(VoiceIndex :integer := 0);
    ///  Выбор голоса по номеру для текущего языка(индексация от 0)
    procedure SelectVoice(VoiceIndex : integer);
    ///  Количество установленных голосов для текущего языка
    function VoicesCount : integer;
end;

type RecognizerStates = (NotReady, Inited, Recognizing, Wait);

type StringArray = array of string;
/// Класс объектов для распознавания речи
type Recognizer = class
  
    PhrasesArr : array of string;
    State : RecognizerStates;
    Recogn : Microsoft.Speech.Recognition.SpeechRecognitionEngine;
    LanguageDefined : boolean;
    Lang : Languages;
    
    function GetState : RecognizerStates;
    procedure SetPhrases(Phrases : array of string);
    ///  Автоматическое распознавание языка фраз
    function  DetectLanguage(Phrases : array of string) : Languages;
    procedure SetLang(Language : Languages);
    procedure SpeechRecognized(sender : object; e : Microsoft.Speech.Recognition.SpeechRecognizedEventArgs);
    procedure SpeechRecognitionRejected(sender : object; e :  Microsoft.Speech.Recognition.SpeechRecognitionRejectedEventArgs);
    procedure RecognizeCompleted(sender : object; e : RecognizeCompletedEventArgs);
    function Init : boolean;
    
  public
    ///  Обработчик события распознавания
    OnRecognized : procedure(Phrase : string);
    ///  Обработчик ошибки распознавания
    OnError : procedure(Phrase : string);
    ///  Язык распознавателя. Можно не указывать, тогда определяется по фразам для распознавания
    property Language : Languages write SetLang;
    ///  Создание распознавателя с указанием языка
    constructor Create(Language : Languages := Languages.Russian);
    ///  Создание распознавателя с указанием вариантов для распознавания. Язык выводится автоматически
    constructor Create(Phrases : array of string);
    ///  Фразы для распознавания в виде массива строк. Результатом распознавания будет одна из этих фраз
    property Phrases : array of string write SetPhrases;
    
    //function Recognize : boolean;
    ///  Старт распознавания. Объект должен быть корректно настроен - заданы фразы и указан обработчик
    procedure Start;
    ///  Остановка распознавания
    procedure Stop;
end;
///  Информация об установленных "говорилках" и "голосах"
procedure SpeechInfo;
///  Озвучивание одной фразы. Язык выбирается автоматически
procedure Say(Phrase : string);
//------------------------------------------------------------------------------
implementation

///  Вывод вспомогательной информации и справки
procedure SpeechInfo;
begin
  ///  Проверить наличие устройств воспроизведения и записи звука - не сделано
  ///  Проверить установленные компоненты для воспроизведения и записи звука
  ///  Проверить наличие голосов для распознавания и воспроизведения звука
      
  try
  begin
    var synth := new SpeechSynthesizer();
    var iv := synth.GetInstalledVoices(CultureInfo.GetCultureInfoByIetfLanguageTag('ru-RU'));
    Writeln('Для корректной работы убедитесь, что у вас в системе установлено устройство воспроизведения звука и микрофон.');
  
    var UnitReady := true;
  
    if iv.Count > 0 then
      begin
        WriteLn('Установлены русскоговорящие голоса:');
        foreach var v in iv do writeln('  ', v.VoiceInfo.Name);
      end
    else
      begin
        UnitReady := false;
        WriteLn('Не установлен русскоговорящий голос!');
        Write('Вам необходимо скачать и установить русскоговорящие голоса для синтеза речи. ');
        Write('Скачать можно со страницы https://www.microsoft.com/en-us/download/details.aspx?id=27224. ');
        Write('Русскоговорящие – голоса со строкой TTS_ru-RU в названии. Открыть страницу скачивания? [Y/N]');
        if UpCase(ReadChar)='Y' then
          System.Diagnostics.Process.Start('https://www.microsoft.com/en-us/download/details.aspx?id=27224');
      end;
  
    var ivUS := synth.GetInstalledVoices(CultureInfo.GetCultureInfoByIetfLanguageTag('en-US'));
    var ivGB := synth.GetInstalledVoices(CultureInfo.GetCultureInfoByIetfLanguageTag('en-GB'));
    var ivGB_US := ivUS.Concat(ivGB);

    if ivGB_US.Count > 0 then
      begin
        WriteLn('Установлены англоговорящие голоса:');
        foreach var v in ivGB_US do writeln('  ', v.VoiceInfo.Name);
      end
    else
      begin
        UnitReady := false;
        WriteLn('Не установлен англоговорящий голос!');
        Write('Вам необходимо скачать и установить англоговорящие голоса для синтеза речи. ');
        Write('Скачать можно со страницы https://www.microsoft.com/en-us/download/details.aspx?id=27224. ');
        Write('Англоговорящие – голоса со строкой TTS_en в названии. Открыть страницу скачивания? [Y/N]');
        if UpCase(ReadChar)='Y' then
          System.Diagnostics.Process.Start('https://www.microsoft.com/en-us/download/details.aspx?id=27224');
      end;
  
    //  Проверяем установленные голоса для распознавания
    var RecognizerInfo := SpeechRecognitionEngine.InstalledRecognizers()
                .Where(ri -> (ri.Culture.Name = 'ru-RU'));
    if RecognizerInfo.Count > 0 then
      begin
        WriteLn('Установлены модули распознавания русского языка:');
        foreach var v in RecognizerInfo do writeln('  ', v.Name);
      end
    else
      begin
        UnitReady := false;
        WriteLn('Не установлен модуль распознавания русской речи!');
        Write('Вам необходимо скачать и установить распознаватели русской речи. ');
        Write('Скачать можно со страницы https://www.microsoft.com/en-us/download/details.aspx?id=27224. ');
        Write('Для английского языка – со строкой SR_ru-RU в названии. Открыть страницу скачивания? [Y/N]');
        if UpCase(ReadChar)='Y' then
          System.Diagnostics.Process.Start('https://www.microsoft.com/en-us/download/details.aspx?id=27224');
      end;

    RecognizerInfo := SpeechRecognitionEngine.InstalledRecognizers()
                .Where(ri -> (ri.Culture.Name = 'en-US')or(ri.Culture.Name = 'en-GB'));
  
    if RecognizerInfo.Count > 0 then
      begin
        WriteLn('Установлены модули распознавания английского языка:');
        foreach var v in RecognizerInfo do writeln('  ', v.Name);
      end
    else
      begin
        UnitReady := false;
        WriteLn('Не установлен модуль распознавания английской речи!');
        Write('Вам необходимо скачать и установить распознаватели английской речи. ');
        Write('Скачать можно со страницы https://www.microsoft.com/en-us/download/details.aspx?id=27224. ');
        Write('Для английского языка – со строкой SR_en-GB или SR_en-US в названии. Открыть страницу скачивания? [Y/N]');
        if UpCase(ReadChar)='Y' then
          System.Diagnostics.Process.Start('https://www.microsoft.com/en-us/download/details.aspx?id=27224');
      end;
      
    if UnitReady then 
        WriteLn('Голоса и распознаватели обнаружены, модуль готов к работе.');      
  end 
  except
    writeln('При получении информации возникла ошибка - проверьте корректность установки Microsoft Speech Platform.');
  end;
end;
///  Автоматическое определения языка строки - английского или руского, по преобладанию букв соответствующего алфавита
function DetectLanguage(Phrase : string) : Languages;
begin
  var RussianLetters := 0;
  foreach var ch in phrase do
    begin
      var code := OrdUnicode(UpCase(ch));
      if (code >= OrdUnicode('А')) and (code <= OrdUnicode('Я')) then
        inc(RussianLetters)
      else
        if (code >= OrdUnicode('A')) and (code <= OrdUnicode('Z')) then
          dec(RussianLetters);
      if Abs(RussianLetters)>=100 then 
        begin
          if RussianLetters>=0 then 
            Result := Languages.Russian
          else
            Result := Languages.English;
          exit;
        end;
    end;
  if RussianLetters>=0 then 
    Result := Languages.Russian
  else
    Result := Languages.English;  
end;
//------------------------------------------------------------------------------
constructor Speaker.Create(Language : Languages);
begin
  synth := new SpeechSynthesizer;
  synth.SetOutputToDefaultAudioDevice;
  currRuIndex := 0;
  currEngIndex := 0;
  if Language=Languages.American then Language := Languages.English;
  SetLang(Language);
end;
constructor Speaker.Create(Phrase : string);
begin
  synth := new SpeechSynthesizer;
  synth.SetOutputToDefaultAudioDevice;
  currRuIndex := 0;
  currEngIndex := 0;
  if Lang=Languages.American then Lang := Languages.English;
  SetLang(DetectLanguage(Phrase));
  Speak(Phrase);
end;
function Speaker.GetRussianVoices : System.Collections.Generic.List<InstalledVoice>;
begin
  Result := new System.Collections.Generic.List<InstalledVoice>(synth.GetInstalledVoices(CultureInfo.GetCultureInfoByIetfLanguageTag('ru-RU')));
end;
function Speaker.GetEnglishVoices : System.Collections.Generic.List<InstalledVoice>;
begin
  var ivUS := synth.GetInstalledVoices(CultureInfo.GetCultureInfoByIetfLanguageTag('en-US'));
  var ivGB := synth.GetInstalledVoices(CultureInfo.GetCultureInfoByIetfLanguageTag('en-GB'));
  var iv := ivUS.Concat(ivGB);
  Result := new System.Collections.Generic.List<InstalledVoice>(iv);
end;
function Speaker.GetState : SpeakerState;
  begin
    case synth.State of
      Microsoft.Speech.Synthesis.SynthesizerState.Ready : Result := SpeakerState.Ready;
      Microsoft.Speech.Synthesis.SynthesizerState.Paused : Result := SpeakerState.Paused;
      Microsoft.Speech.Synthesis.SynthesizerState.Speaking : Result := SpeakerState.Speaking;
    end;
  end;
procedure Speaker.SetLang(newLang : Languages);
begin
  if newLang=Languages.American then newLang := Languages.English;
  if newLang = lang then exit;
  
  if newLang = Languages.Russian then
    SelectRussianVoice(currRuIndex)
  else
    SelectEnglishVoice(currEngIndex);
end;
function Speaker.GetLang : Languages;
  begin
    Result := Lang;
  end;
procedure Speaker.SetVolume(Volume : integer);
  begin
    AudioVol := min(100, max(0,Volume));
    if synth <> nil then synth.Volume := AudioVol;
  end;  
function Speaker.GetVolume : integer;
begin
  Result := AudioVol;
end;
procedure Speaker.Speak(Phrase : string);
begin
  synth.Speak(Phrase);
end;
procedure Speaker.SpeakAsync(Phrase : string);
begin
  var t := new System.Threading.Thread(() -> synth.Speak(Phrase));
  t.Start();
end;
procedure Speaker.SelectEnglishVoice(VoiceIndex :integer);
begin
  var EngVC := GetEnglishVoices;
  var VoicesCount := EngVC.Count;
  if VoicesCount = 0 then raise new Exception('Ошибка! Не установлены англоговорящие голоса.');
  currEngIndex := min(VoicesCount-1,max(0,VoiceIndex));
  synth.SelectVoice(EngVC.ElementAt(currEngIndex).VoiceInfo.Name);
  Lang := Languages.English;
end;
procedure Speaker.SelectRussianVoice(VoiceIndex :integer);
begin
  var RusVC := GetRussianVoices;
  var VoicesCount := GetRussianVoices.Count;
  if VoicesCount = 0 then raise new Exception('Ошибка! Не установлены русскоговорящие голоса.');
  currRuIndex := min(VoicesCount-1,max(0,VoiceIndex));
  synth.SelectVoice(RusVC.ElementAt(currRuIndex).VoiceInfo.Name);
  Lang := Languages.Russian;
end;
procedure Speaker.SelectVoice(VoiceIndex : integer);
begin
  if Lang = Languages.American then Lang := Languages.English;
  var Voices : System.Collections.Generic.List<InstalledVoice>;
  if Lang = Languages.English then 
    Voices := GetEnglishVoices
  else
    Voices := GetRussianVoices;
  VoiceIndex := max(0,min(Voices.Count-1,VoiceIndex));
  synth.SelectVoice(Voices.ElementAt(VoiceIndex).VoiceInfo.Name);
end;
function Speaker.VoicesCount : integer;
begin
  if Lang = Languages.Russian then
    Result := GetRussianVoices.Count
  else
    Result := GetEnglishVoices.Count;
end;
//------------------------------------------------------------------------------
constructor Recognizer.Create(Language : Languages);
begin
  recogn := nil;
  lang := Language;
  languageDefined := true;
  State := RecognizerStates.NotReady;
end;

constructor Recognizer.Create(Phrases : array of string);
begin
  recogn := nil;
  languageDefined := false;
  State := RecognizerStates.NotReady;
  SetPhrases(Phrases);
end;

///  Инициализация распознавателя
function Recognizer.Init : boolean;
begin
  if PhrasesArr.Length = 0 then 
    begin
      Result := false;
      exit;
    end;
 
  if not LanguageDefined then
    Lang := DetectLanguage(PhrasesArr);
  LanguageDefined := true;

  var recognLanguage := 'ru-RU';  //  Варианты: en-GB, en-US, ru-RU
  case Lang of
    Languages.American : recognLanguage := 'en-US';
    Languages.English : recognLanguage := 'en-GB';
  end;
    
  var RecognizerInfo := SpeechRecognitionEngine.InstalledRecognizers.Where(ri -> ri.Culture.Name = recognLanguage).FirstOrDefault();
  
  if Recogn <> nil then 
    begin
      if State = RecognizerStates.Recognizing then
        begin
          Recogn.RecognizeAsyncCancel;
          State := RecognizerStates.NotReady;
        end;
      Recogn.UnloadAllGrammars;
    end
  else
    begin
      Recogn := new Microsoft.Speech.Recognition.SpeechRecognitionEngine(RecognizerInfo.Id);
      Recogn.SpeechRecognized += SpeechRecognized;
      Recogn.SpeechRecognitionRejected += SpeechRecognitionRejected;
      Recogn.RecognizeCompleted += RecognizeCompleted;
    end;
  
  var Choises := new Microsoft.Speech.Recognition.Choices();
  Choises.Add(PhrasesArr.ToArray);

  var gb := new Microsoft.Speech.Recognition.GrammarBuilder();
  gb.Culture := RecognizerInfo.Culture;
  gb.Append(Choises);
  
  var gr := new Microsoft.Speech.Recognition.Grammar(gb);
  Recogn.LoadGrammar(gr);
  Recogn.RequestRecognizerUpdate();
  try 
    Recogn.SetInputToDefaultAudioDevice();
  except 
    Writeln('Не могу найти устройство записи звука (микрофон не подключен)');
  end;
  state := RecognizerStates.Inited;
end;

function Recognizer.GetState : RecognizerStates;
begin
  Result := State;
end;
procedure Recognizer.SetPhrases(Phrases : array of string);
begin  
  PhrasesArr := Copy(Phrases);
  Init;
end;
function Recognizer.DetectLanguage(Phrases : array of string) : Languages;
begin
  var RussianLetters := 0;
  foreach var s in phrases do
    foreach var ch in s do
      begin
        var code := OrdUnicode(UpCase(ch));
        if (code >= OrdUnicode('А')) and (code <= OrdUnicode('Я')) then
          inc(RussianLetters)
        else
          if (code >= OrdUnicode('A')) and (code <= OrdUnicode('Z')) then
            dec(RussianLetters);
        if Abs(RussianLetters)>=100 then 
          begin
            if RussianLetters>=0 then 
              Result := Languages.Russian
            else
              Result := Languages.English;
            exit;
          end;
      end;
  if RussianLetters>=0 then 
    Result := Languages.Russian
  else
    Result := Languages.English;
end;
procedure Recognizer.SetLang(Language : Languages);
begin
  Lang := Language;
  LanguageDefined := true;
  State := RecognizerStates.NotReady;
end;
procedure Recognizer.SpeechRecognized(sender : object; e : Microsoft.Speech.Recognition.SpeechRecognizedEventArgs);
begin
  Recogn.RecognizeAsyncCancel;
  State := RecognizerStates.Wait;
  var tx := e.Result.Text;
  if OnRecognized <> nil then
    OnRecognized(tx);
  if State <> RecognizerStates.Recognizing then
    begin
      State := RecognizerStates.Recognizing;
      Recogn.RecognizeAsync;
    end;
end;

procedure Recognizer.SpeechRecognitionRejected(sender : object; e :  Microsoft.Speech.Recognition.SpeechRecognitionRejectedEventArgs);
begin
  Recogn.RecognizeAsyncCancel;
  State := RecognizerStates.Wait;
  var tx := e.Result.Text;
  if OnError <> nil then
    OnError(tx);
  if State <> RecognizerStates.Recognizing then
    begin
      State := RecognizerStates.Recognizing;
      Recogn.RecognizeAsync;
    end;
end;

procedure Recognizer.RecognizeCompleted(sender : object; e : RecognizeCompletedEventArgs);
begin
  //  Not implemented yet
end;

procedure Recognizer.Start;
begin
  if (State = RecognizerStates.Inited) or (State = RecognizerStates.Wait) then 
    begin
      if OnRecognized = nil then 
        begin
          //writeln('No defined!');
          exit;
        end;
      try
        Recogn.RecognizeAsync(Microsoft.Speech.Recognition.RecognizeMode.Multiple);
        State := RecognizerStates.Recognizing;
      except
        begin
          writeln('Не найдено устройство записи звука!');
          State := RecognizerStates.NotReady;  
        end;
      end;
    end;
end;

procedure Recognizer.Stop;
begin
  if State = RecognizerStates.Recognizing then 
    begin
      Recogn.RecognizeAsyncCancel;
      State := RecognizerStates.Wait;
    end;
end;
//------------------------------------------------------------------------------
procedure Say(Phrase : string);
begin
  Speaker.Create(Phrase);
end;

end.
