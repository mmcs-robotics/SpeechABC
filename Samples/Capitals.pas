program Capitals;
  uses SpeechABC,ABCObjects,GraphABC;

/// Количество вариантов ответа
const answersCount = 4;  

     /// Загаданная столица
     var   capital : string;
     /// Полный список стран и столиц
     var countries : array of (string, string);
     /// Список стран со столицами, отобранных для вопроса     
     var quiz      : array of (string, string);
     ///  Объект для распознавания речи      
     var    recogn : recognizer;
     /// Массив надписей - вопрос, варианты и счёт
     var       txt : array of TextABC;
     /// Число верно угаданных столиц  
     var   correct : integer;
     /// Число неверных ответов
     var     wrong : integer;

/// Формулировка нового вопроса и вывод на экран
procedure NewQuestion;
begin
  //  Останавливаем распознавание
  recogn.Stop;
  
  //  Перемешиваем исходный массив и берём нужное количество вариантов
  quiz := countries.Shuffle.Take(answersCount).ToArray;
  
  //  Настраиваем массив ответов
  var phrases : array of string;
  SetLength(phrases,answersCount);
  for var i := 0 to answersCount-1 do
  begin
    phrases[i] := quiz[i].Item1;  //  Вариант ответа заносим в массив
    txt[i+1].Text := quiz[i].Item1;  //  Этот же вариант выводим на экран
    txt[i+1].Color := Color.DarkBlue;  //  Надпись красим в тёмно-синий
  end;
  
  //  Случайно выбираем один из вариантов - это будет правильный ответ
  var index := Random(answersCount);
  //  Выводим текст вопроса
  txt[0].Text := 'Столицей какого государства является ' + quiz[index].Item2 + '?';
  //  Правильный ответ записываем в глобальную переменную
  capital := quiz[index].Item1;
  //  Настраиваем распознаватель - задаём новый массив фраз
  recogn.Phrases := phrases;
  //  Запускаем распознавание
  recogn.Start;
end;

///  Начальная настройка - чтение списка городов, создание надписей и проч.
procedure Init;
begin
  //  Создание массива надписей - для вопроса, ответов, и счёта
  SetLength(txt,answersCount+2);
  //  Создаём и располагаем надписи по порядку
  for var i:=0 to answersCount+1 do
    txt[i] := TextABC.Create(150,70*i+20,30,'Text '+ i.ToString,clBlack); 
  //  Настраиваем "нулевую" - это надпись с вопросом
  txt[0].Left := 20;
  txt[0].Color := Color.DarkRed;
  //  И последнюю в массиве - это для счёта
  txt[answersCount + 1].Text := 'Счёт : 0 верно из 0';
  txt[answersCount + 1].Left := 20;
  
  //  Настройка окна - заголовок, размер и центрирование
  Window.Caption := 'Викторина «Столицы стран»';
  SetWindowSize(1200,txt[answersCount + 1].Top + 100);
  CenterWindow;
  
  //   Читаем массив стран. Файл вида «страна;столица»
  SetLength(countries, 0);
  foreach var s in ReadLines('Capitals.csv') do
    begin
      var lexem := s.ToWords(';');
      SetLength(countries, countries.Length + 1);
      countries[ countries.Length - 1 ] := (lexem[0],lexem[1]);
    end;
end;

///  Обработчик распознавания. Процедура срабатывает, когда что-то распознано
procedure OnRecogn(phrase : string);
begin
  //  Останавливаем распознавание
  recogn.Stop;
  if phrase = capital then
    begin
      //  Если верный ответ - учитываем и формируем новый вопрос
      Say('Верно');
      correct += 1;
      txt[answersCount + 1].Text := 'Счёт : ' + correct.ToString + ' верно из ' + (correct+wrong).ToString;
      NewQuestion;
    end
  else
    begin
      //  Если неверно - отмечаем неверный вариант, меняем счёт
      Say('Нет');
      wrong += 1;
      txt[answersCount + 1].Text := 'Счёт : ' + correct.ToString + ' верно из ' + (correct+wrong).ToString;
      for var i:=1 to answersCount do
        if txt[i].Text = phrase then
          txt[i].Color := Color.Red;
    end;
  //  Возобновляем распознавание
  recogn.Start;
end;

begin
  //  Инициализируем надписи, окно и читаем из файла список столиц
  Init;
  //  Создаём объект для распознавания
  recogn := new Recognizer;
  //  Указываем обработчик
  recogn.OnRecognized := OnRecogn;
  //  Формируем новый вопрос. Там же задаются варианты для распознавания
  NewQuestion;
end.