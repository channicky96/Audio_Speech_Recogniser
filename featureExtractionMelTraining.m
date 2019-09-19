str = 'speech';
wav = '.wav';
mfc = '.mfc';
names = {'Adrian.wav','Ali.wav','Andrew.wav','Andy.wav','Ce.wav','Chaorong.wav','Jeremy.wav','Ke.wav',...
        'Liam.wav','Martino.wav','Mateusz.wav','Minghong.wav','Nicholas.wav','Nicole.wav',...
        'Oliver.wav','Sarah.wav','Shaun.wav','Travis.wav','Vincent.wav','Vinny.wav'};
    
names2 = {'Adrian.mfc','Ali.mfc','Andrew.mfc','Andy.mfc','Ce.mfc','Chaorong.mfc','Jeremy.mfc','Ke.mfc',...
        'Liam.mfc','Martino.mfc','Mateusz.mfc','Minghong.mfc','Nicholas.mfc','Nicole.mfc',...
        'Oliver.mfc','Sarah.mfc','Shaun.mfc','Travis.mfc','Vincent.mfc','Vinny.mfc'};
    
for idx = 1:numel(names)
    name = names{idx};
    s = name;
    disp(s);
    
    % y is the audio data, fs is the sampling frequency
    [y,fs] = audioread(s);
    
    % Pre-emphasis
%     a = 0.98;
%     for x = 1:(length(y))
%         if x ~=1
%             y(x) = y(x) -(a*(y(x-1)));
%         end
%     end
       
    duration = length(y)/fs;
    
    % size of window in milliseconds
    windowSize = 20;
    
    overlap = 0.5;
    
    % equation when window size = 20ms with 50 percent overlap
    noOfWin = floor(length(y)/(((windowSize/1000)*fs)*(1-overlap))) - 2;

    % declaring start and end point
    startPoint = 1;
    endPoint = fs*(windowSize/1000);
    
    frameSize = endPoint;

    for winNumber = 1:noOfWin
        

        % extract speech frame section
        x = y(startPoint:endPoint);

        % creating a hamming wimndow for the speech frame
        h = hamming(length(x));
        i = x.*h;

        % fourier transform and obtain magSpec 
        xF = fft(i);
        magSpec = abs(xF);
        magSpec = magSpec(1:floor(length(magSpec)/2));


        % mel channels
        k = 20;

        freqToIndexScale = length(magSpec)/(fs/2);

        lower = 1;
        upper = fs/2; %8000

        % quefreq
        lowerMel = 2595*log10(1+lower/700); 
        upperMel = 2595*log10(1+upper/700);

        % List to record list of indexes that is mel-scaled
        melIndexes = [];

        % gap in-between each mel index if linear
        increment = (upperMel-lowerMel)/(k+1);

        % generate a list of indexes that is scaled to mel
        for i=0:(k+1)
            % Get the index for the next point in mels
            normIndex = (increment*i)+lowerMel;
            % convert back to frequency
            freqPoint = 700*((10^(normIndex/2595))-1);
            % compute index in terms of mel
            index = round(freqPoint*freqToIndexScale);
            melIndexes = [melIndexes,index];
        end

        if melIndexes(1) == 0
            melIndexes(1) = 1;
        end

        for i=1:k
            channelValue = 0;
            % For a triangular filter bank
            start = i;     % Starts at 0 amplitude
            mid = i+1;     % Peaks at second point (amplitude = 1)
            last = i+2;    % Return to 0 at 3rd point

            % Calculate the length of the left side of triangle
            leftSide = melIndexes(mid) - melIndexes(start);
            % Calculate evenly spaced values in between 0 and 1 equal
            % to the size of the left triangle e.g. for size 4,
            % 0,0.25,0.5,0.75,1
            leftScaleValues = 0:1/leftSide:1;

            rightSide = melIndexes(last) - melIndexes(mid);
            rightScaleValues = 1:-1/rightSide:0;

            rightScaleValues = rightScaleValues(2:length(rightScaleValues));

            % get the full scale values of the channel
            channelScaleValues = [leftScaleValues,rightScaleValues];  

            for j=1:length(channelScaleValues)
               channelValue = channelScaleValues(j)* magSpec(melIndexes(start)) + channelValue;
            end
            filterbank(i) = channelValue;
        end


        % applying the log and DCT to the filterbank
        theDCT = dct(log(filterbank));
        MFCC = []; 

        truncationLevel = 0;

        % adding everything to the MFCC - use half truncation level
        for i = 1:k*(1-truncationLevel)
            MFCC(i) = theDCT(i);   
        end
        

        totalEnergy = 0;
        % calculate energy levels
%             totalEnergy = sum(x.^2);
%             totalEnergy = log10(totalEnergy);
% 
% 
%             MFCC = [MFCC,totalEnergy];
        % store MFCC vectors in an array
        totalMFCC{winNumber} = MFCC;


        % redefining start and end points
        startPoint = startPoint + floor(length(x)*(1-overlap));
        endPoint = endPoint + floor(length(x)*(1-overlap));
    end
        
        % Velocity vectors
        loopLength = length(totalMFCC{1,i});
        for i=1:length(totalMFCC)
            % If you're at the start, take the difference between vector 1
            % and 2
            if i ==1
                V1 = totalMFCC{1,i};
                V2 = totalMFCC{1,i+1};
            elseif i == length(totalMFCC)
            % Or if at end, take the difference between the penultimate and
            % final vector.
                V1 = totalMFCC{1,i-1};
                V2 = totalMFCC{1,i};

            else 
                V1 = totalMFCC{1,i-1};
                V2 = totalMFCC{1,i+1};
                
            end
            
            for j=1:loopLength
                    dV(j) = V2(j) - V1(j);
            end 
            
            totalMFCC{1,i} = [totalMFCC{1,i},dV];
        end
        
        % Acceleration Vectors
        for i=1:length(totalMFCC)
            if i == 1
                % Get the second half of the vector aka the velocity
                A1 = totalMFCC{1,i}(loopLength+1:length(totalMFCC{1,i}));
                A2 = totalMFCC{1,i+1}(loopLength+1:length(totalMFCC{1,i+1}));
            elseif i == length(totalMFCC)
                A1 = totalMFCC{1,i-1}(loopLength+1:length(totalMFCC{1,i-1}));
                A2 = totalMFCC{1,i}(loopLength+1:length(totalMFCC{1,i}));
            else
                A1 = totalMFCC{1,i-1}(loopLength+1:length(totalMFCC{1,i-1}));
                A2 = totalMFCC{1,i+1}(loopLength+1:length(totalMFCC{1,i}));
            end
            
            for j=1:loopLength
                    aV(j) = A2(j) - A1(j);
            end
            
            totalMFCC{1,i} = [totalMFCC{1,i},aV];
        end

        
        
        %Write to file
        s = names2{idx};
        
        disp(s);
        

        % Open file for writing:
        fid = fopen(s, 'w', 'ieee-be');
        
        vectorSize = length(totalMFCC{1,1});

    %     disp(length(totalMFCC));

        % Write the header information% 
        fwrite(fid, noOfWin, 'int32');    % number of vectors in file (4 byte int)
        %10ms in 100ns unit - gap between each window
        fwrite(fid, (windowSize*(1-overlap)*10000), 'int32');  % sample period in 100ns units (4 byte int)
        fwrite(fid, vectorSize * 4, 'int16');   % number of bytes per vector (2 byte int)
        fwrite(fid, 9, 'int16');      % code for the sample kind (2 byte int)

        % Write the data: one frame at a time:
        for i = 1:noOfWin         
               fwrite(fid, totalMFCC{1, i}, 'float32');    
        end

        fclose(fid);
        

        clear totalMFCC;
        
end

noOfStates = 25;
        
chr = int2str(noOfStates);
% get the filename
stateFileName = strcat('proto',chr,'States.txt');
        
writeProtoFile(stateFileName,noOfStates,vectorSize);
clear;