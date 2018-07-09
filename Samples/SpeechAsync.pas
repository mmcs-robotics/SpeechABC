uses SpeechABC;
begin
  //  Создаём говорилку для русского языка
  var sp := Speaker.Create(Languages.Russian);
  //  Вызываем проговаривание четырёх фраз
  sp.SpeakAsync('Проверка речи. Я умею говорить!');
  sleep(10);
  sp.SpeakAsync('Вторая фраза');
  sleep(10);
  sp.SpeakAsync('Третья фраза');
  sleep(10);
  sp.SpeakAsync('Четвёртая фраза');
  //  Вывод текста – эта фраза будет напечатана ещё до того, как закончится 
  //  произнесение первой фразы
  writeln('Я всё сказала!');
end.