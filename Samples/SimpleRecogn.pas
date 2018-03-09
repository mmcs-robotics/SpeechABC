uses SpeechABC, GraphABC;
  var Speak : Speaker;
        Ear : Recognizer;
procedure Response(phrase : string);
begin
  Writeln(phrase);
end;
procedure KeyDown(key :integer);
begin
  writeln(Ear.State);
end;
begin
  SpeechInfo;
  OnKeyDown := KeyDown;
  var Phrases := new string[] ('Привет', 'ИТ или ПМ', 'Язык программирования', 'Выход', 'Хаскель', 'Какую', 'Кино', 'Зелёный');
  Ear := new Recognizer(Phrases);
  Ear.OnRecognized := Response;
  Ear.Start;
  
end.