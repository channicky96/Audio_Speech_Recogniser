r = audiorecorder(16000, 16 ,1);
str = 'speech';
wav = '.wav';
for fileNumber = 1:1
    disp('Say utterance');
    record(r);
    pause(8);
    stop(r);
    x = getaudiodata(r,'double');
    xNorm = x / max(abs(x));
    chr = int2str(fileNumber);
    s = strcat(str,chr,wav);
    s = 'demo.wav';
    audiowrite(s,xNorm, 16000);
% prompt speaker to say utterance
% record audio
% normalise audio
% save audio to next wav file
end