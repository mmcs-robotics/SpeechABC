uses SpeechABC;
begin
  var Arnold := new Speaker(Languages.English);
  Arnold.Volume := 100;
  for var i := 0 to Arnold.VoicesCount-1 do
    begin
      Arnold.SelectVoice(i);
      Arnold.Speak('Hasta la vista, baby!');
    end;
end.