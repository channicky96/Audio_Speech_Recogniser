function writeProtoFile(fileName, NumStates, VectorSize)
    % Creates an HTK prototype file to model a HMM.
    % Inputs:
    % fileName - intended file to be written to.
    % NumStates - number of states to model the HMM.
    % VectorSize - feature vector size used to model the means and
    % variances of the HMM.
    
    fid = fopen(fileName, 'wt');
    HTKnumStates = NumStates + 2;
    
    % Header info
    fprintf(fid, '%s\n', '<BeginHMM>'); 
    fprintf(fid, '%s%d%s%d%s\n' , '<NumStates> ', HTKnumStates, ...
                 ' <VecSize> ', VectorSize, ...
                 ' <USER> <nullD> <diagC>');
    
    % State generation
    for i=2:HTKnumStates-1
        fprintf(fid, '%s%d%s%d\n', '<State> ', i, ' <NumMixes> ', 1);
        fprintf(fid, '%s%d% .1f\n', '<Mixture> ', 1, 1.0);
        fprintf(fid, '%s%d\n', '<Mean> ', VectorSize);
        for j=1:VectorSize
           fprintf(fid, '%.1f%s', 0.0, ' ');  
        end
        
        fprintf(fid, '%s\n', ' '); %purely to starts a new line
        fprintf(fid, '%s%d\n', '<Variance> ', VectorSize);
        for k=1:VectorSize
           fprintf(fid, '%.1f%s', 1.0, ' ');  
        end
        
        fprintf(fid, '%s\n', ' '); %purely to starts a new line        
    end
    
    % Transition matrix
    fprintf(fid, '%s%d\n', '<TransP> ',  HTKnumStates);
    transitionMatrix = zeros(HTKnumStates); 
    tempi1 = 0;
    tempi2 = 1;
    
    % Generating matrix
    for i=1:HTKnumStates % ith index os for collumns
        for j=1:HTKnumStates % jth index is for rows
           if i == 1 || i == HTKnumStates
              % do nothing, keep the probabilities at zero.
           else
               if tempi1 == 1
                   transitionMatrix(tempi1, i) = 1.0;
                   transitionMatrix(tempi2, i) = 0.6;
               elseif tempi2 == (HTKnumStates -1)
                   transitionMatrix(tempi1, i) = 0.4;
                   transitionMatrix(tempi2, i) = 0.9;
                   transitionMatrix(tempi2, i+1) = 0.1;
               else    
                   transitionMatrix(tempi1, i) = 0.4;
                   transitionMatrix(tempi2, i) = 0.6;
               end
           end 
        end        
        tempi1 = tempi1 + 1;
        tempi2 = tempi2 + 1;
    end
    
    % Writting matrix
    for i=1:HTKnumStates
        for j=1:HTKnumStates
           if j == HTKnumStates
               fprintf(fid, '\t%.1f\n', transitionMatrix(i,j));
           else
               fprintf(fid, '\t%.1f', transitionMatrix(i,j));
           end
        end
    end
    
    % End HMM
    fprintf(fid, '%s\n', '<EndHMM> ');
    
    % Close file
    fclose(fid);
end