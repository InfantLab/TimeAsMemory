function [timeIntervals,memoryRepresentations] = getFadingGaussians(gaussianParams)
%function [timeIntervals,memoryRepresentations] = getFadingGaussians(gaussianParams)
%
% Build a representative set of gaussians as specified by the params
%       .inputType      - [0 = Analytic, 1=fading gaussian]
%       .inputWidth     - how wide is input vector?
%       .minTimeInterval 
%       .maxTimeInterval
%       .numTimeIntervals  - how many steps 
%       .memorytimeunit  % K
%       .memorysigmaunit % s  
%       .lognormalIntervals  - how are intervals distributed?
%
% OUTPUTS are 
%   intervals - vector all the time steps
%   allMemories - matrix where rows are the associated memory
%   representation
%
% Caspar Addyman 2010
% caspar@onemonkey.org
% version 01 - 26 Sep 2010
% version 02 - 16 Dec 2010

ANALYTIC_GAUSSIAN = 0;
FADING_GAUSSIAN = 1;

if gaussianParams.lognormalIntervals
    intervalRange = log(gaussianParams.maxInterval)-log(gaussianParams.minInterval);
    intervalStep = intervalRange/(gaussianParams.numIntervals-1);
    logintervals = log(gaussianParams.minInterval):intervalStep:log(gaussianParams.maxInterval);
    timeIntervals = exp(logintervals);
else
    intervalRange = gaussianParams.maxInterval-gaussianParams.minInterval;
    intervalStep = intervalRange/(gaussianParams.numIntervals-1);
    timeIntervals = gaussianParams.minInterval:intervalStep:gaussianParams.maxInterval;
end
%%%%%%%%%%%%%%%%%%% INPUTS %%%%%%%%%%%%%%%%%%%%%%%%
%what type of input (& test) distribution do we have? 
if gaussianParams.inputType == ANALYTIC_GAUSSIAN % my original inputs

    inputRuler = 1:gaussianParams.inputWidth;  %a counter useful for calculating distributions

    %all percepts at centre of field
    percepts = floor(gaussianParams.inputWidth/2) * ones(gaussianParams.numIntervals,1);

    % each memories[1:inputWidth, i] is normally distributed with mean percept(i)
    % and stddev given by interval(i) 
    murange= repmat(inputRuler,gaussianParams.numIntervals,1) - repmat(percepts,1,gaussianParams.inputWidth); 

    for k=1:length(timeIntervals)
        %doesn't seem to be a way to avoid this loop
        memoryRepresentations(k,:) = normdist(murange(k,:)/gaussianParams.memorywidthunit,0,timeIntervals(k)/gaussianParams.memorytimeunit);
    end
     
elseif gaussianParams.inputType == FADING_GAUSSIAN % Bob's squash and spread function
    %PARAMS
     
%     gaussianParams.spread_factor =  0.0045; % visual
%     gaussianParams.leakage_factor = 0.0105;
%     gaussianParams.self_excitation = 0.001;
    
    [X, Y, no_of_timesteps, Stddev] = squash_and_spread (gaussianParams.spread_factor, gaussianParams.leakage_factor, gaussianParams.self_excitation, false, true);

%     inputRuler = X;
%     inputWidth = length(X);    %how wide is input vector?
    
    % squash_and_spread gives us no_of_timesteps gaussians as rows of Y
    % which represent the evoling memory trace
    % for training and testing we want N= NumIntervals even-spaced samples 
    % from this set.
    if  gaussianParams.lognormalIntervals
        %pick the value nearest the log
        intcount = 1;
        intervalRange = gaussianParams.maxInterval-gaussianParams.minInterval;
        timestepsize = intervalRange/(no_of_timesteps-1);
        for j = 0:no_of_timesteps-1
            steptime = gaussianParams.minInterval + j * timestepsize;
            if steptime >= timeIntervals(intcount)
                timeIntervals(intcount) = steptime;
                samplerows(intcount) = j+1;
                intcount = intcount + 1;
            end
        end
    else
        step  = floor((no_of_timesteps -1)/gaussianParams.numIntervals);
        samplerows = 1:step:no_of_timesteps;
        timeIntervals = gaussianParams.minInterval + samplerows .* (gaussianParams.maxInterval-gaussianParams.minInterval) / no_of_timesteps;
    end
    memoryRepresentations = Y(samplerows, :);
end

%finally multiply by amplitude
memoryRepresentations = memoryRepresentations * gaussianParams.Amplitude;
   
   