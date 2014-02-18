function [intervals,representations] = TimeAsMemory_v2(inputType, outputType, fixedLocation, ...
                                                    memorynoise, networknoise,showcolumnsgraph,...
                                                    showMainGraphs,trackdevelopment,showCorrelations, ...
                                                    showAttentionEffects)
% example of a neural network implementation of Embodied Memory model of
% time perception.
%
% The basic idea is in a mature system the time interval since an event 
% is derived from of how blurry (some aspect of) the memory for
% the perceptual event has become. An immature system calibrates this
% mechanism using the predictable and repeatable signals from physical
% movements. These obey Fitt's law which is a direct analogue of the Scalar
% Property in interval timing. 
% In this version, a network is 1st trained to predict the length of an 
% interval from 1 distribution. Input is distribution of activations along
% a 1d vector and output is a log-scale counter (aka ATOM representation)
% 
% Caspar Addyman 2010
% caspar@onemonkey.org
% version 01 - 26 Sep 2010
% version 02 - 16 Dec 2010
% version 03 - 23 Jan 2011 - calibration version
% version 04 - 07 Apr 2012 - version for NCPW

close all;

%input curve types
ANALYTIC_GAUSSIAN = 0;
FADING_GAUSSIAN = 1;
SQSH_SPRD = 2;
%output curve types
LINEAR_OUTPUT = 1;     
LOGLINEAR_OUTPUT = 0;

% Default settings
if nargin < 1, inputType = SQSH_SPRD; end                   %what shape is input function
if nargin < 2, outputType = LOGLINEAR_OUTPUT; end                   %what shape is input function
if nargin < 3, fixedLocation = true; end        %is percept centred on input field?
if nargin < 4, memorynoise = false; end             %is memory representation noisy
if nargin < 5, networknoise  = true; end           %internal network noise
if nargin < 6, showcolumnsgraph = true; end         %show graph of co
if nargin < 7, showMainGraphs = true; end         %show graph of main results
if nargin < 8, trackdevelopment = true; end        %make note of weights at intervvals during learning     
if nargin < 9, showCorrelations = false; end        %plot graph of correlation between modalities over learning
if nargin < 10, showAttentionEffects = false; end    %test the same for
if nargin < 11, showProspectiveAttentionEffects = false; end

includemodalitytwo = false;
modalitycount = 1 + includemodalitytwo;

nBabies = 20;
NEpochs = 10;
NTrainingItems = 10000;
LearningRate = 0.01;
momentum = 0.005;
OutputLoopSize = 10; %used for finding mean & std of network outputs


minInterval = 0.1; %seconds
maxInterval = 120; %seconds 
numIntervals = 60;

%network architecture
inputWidth = 43;    %how wide is input vector?
nHidNodes = 10;
outputWidth = 10;   %how wide is output vector

%Analytic Gaussian params
memoryWidthUnit = 5;
memoryTimeUnit = 45;
memoryAmplitude = 10;

%Fading Gaussian params 
% spread_factor = 0.0045;
% leakage_factor = 0.0105;
% self_excitation = 0.001;

spread_factor = 0.1;
leakage_factor = 0.7;
self_excitation = 0.001;



if networknoise
    networknoiserate = 0.06;
else
    networknoiserate = 0;
end

if memorynoise
    %two types
    %fixed amounts of noise added to all input nodes
    memorynoise_fixed_mean = 0.05;            
    memorynoise_fixed_sd = 0.02;             
    
    %relative noise, sd is proportional to activation
    memorynoise_proportional_sd = 0.03;       %added to all input nodes
end



%%%%%%%%%%%%%%%%%%% INPUTS %%%%%%%%%%%%%%%%%%%%%%%%
% what type of input (& test) distribution do we have? 
%
% we claim that memory is normal distribution that decays analogously to Fitt's law.
% so if width of stdev after K seconds is W, after 2K seconds it will be 2W
% therefore we need to specify a scale for both
% 
% percept = setPercepts(inputType, minInterval,maxInterval,numIntervals, ...
%                                 inputWidth,outputWidth,fixedLocation,...
%                                 memoryWidthUnit,memoryTimeUnit,memoryAmplitude,...
%                                 spread_factor,leakage_factor,self_excitation, ...
%                                 lognormalIntervals,useBODYMapRepresentation,useBODYBinaryOut)


modality{1} = setPercepts(inputType,minInterval,maxInterval,numIntervals, ...
                          inputWidth, outputWidth,fixedLocation, ...
                          memoryWidthUnit,memoryTimeUnit,memoryAmplitude, ...
                          spread_factor,leakage_factor,self_excitation, ...
                          false, outputType, false);
modality{1} = populateInputsOutputs(modality{1});

%for the moment the second modality is very similar to first
modality{2} = setPercepts(inputType,minInterval,maxInterval,numIntervals, ...
                          inputWidth, outputWidth,fixedLocation, ...
                           memoryWidthUnit,memoryTimeUnit,memoryAmplitude, ...
                          spread_factor,leakage_factor,self_excitation, ...
                          false, outputType, false);
modality{2} = populateInputsOutputs(modality{2});

%%%%%%%%%%%%% EFFECT OF ATTENTION %%%%%%%%%%%%%%%%%%%%%%%%%%%
%another version of the same inputs and outputs but modulated by attention
% do this by applying multiplier to self-excitation
attentionMultiplier = 0.6;

attention{1} = setPercepts(inputType,minInterval,maxInterval,numIntervals, ...
                          inputWidth, outputWidth,fixedLocation, ...
                          memoryWidthUnit/ attentionMultiplier,memoryTimeUnit,memoryAmplitude, ...
                          spread_factor,leakage_factor,self_excitation * attentionMultiplier , ...
                          false, outputType, false);
attention{1} = populateInputsOutputs(attention{1});

attention{2} = setPercepts(inputType,minInterval,maxInterval,numIntervals, ...
                          inputWidth, outputWidth,fixedLocation, ...
                          memoryWidthUnit/attentionMultiplier,memoryTimeUnit,memoryAmplitude, ...
                          spread_factor,leakage_factor,self_excitation * attentionMultiplier, ...
                          false, outputType, false);
attention{2} = populateInputsOutputs(attention{1});




%%%%%%%%% SIMULATE N Babies %%%%%%%%%%%%%%%%%%%%%%
% so we can average performance
Baby = cell(nBabies,1);
for babycounter = 1:nBabies
  
    for mod = 1:modalitycount
        % sample random intervals in the approriate range (0.1 to 90s).
        % perhaps these ought to have a poisson distribution but don't at the moment
        % can just randomly sample from the rows of allPossibleIntervals
        Baby{babycounter}.Modality{mod}.rows = randi([modality{mod}.numIntervals],NTrainingItems,1);
        Baby{babycounter}.Modality{mod}.MemoryInputs = modality{mod}.MemoryCurves(Baby{babycounter}.Modality{mod}.rows, :);
        Baby{babycounter}.Modality{mod}.ATOMOutputs = modality{mod}.ATOMOutputs(Baby{babycounter}.Modality{mod}.rows,:);
        Baby{babycounter}.Modality{mod}.BODYOutputs = modality{mod}.BODYOutputs(Baby{babycounter}.Modality{mod}.rows,:);

        if memorynoise
            [R,C] = size(Baby{babycounter}.Modality{mod}.MemoryInputs);
            Baby{babycounter}.Modality{mod}.NoisyInputs = Baby{babycounter}.Modality{mod}.MemoryInputs + ...
                                  memorynoise_proportional_sd * Baby{babycounter}.Modality{mod}.MemoryInputs .* randn(R,C);
            Baby{babycounter}.Modality{mod}.NoisyInputs = Baby{babycounter}.Modality{mod}.NoisyInputs + ... 
                                  memorynoise_fixed_mean + memorynoise_fixed_sd * rand(R,C);
        else
            Baby{babycounter}.Modality{mod}.NoisyInputs = Baby{babycounter}.Modality{mod}.MemoryInputs;
        end

        %%%%%%%%%%% the actual network training stage %%%%%%%%%%%%%%%
        %%%%%%%%%%% using back prop.
        if modality{1}.UseBODYMapRepresentation   
           [Baby{babycounter}.Modality{mod}.wt1 Baby{babycounter}.Modality{mod}.wt2] = backprop(Baby{babycounter}.Modality{mod}.NoisyInputs,Baby{babycounter}.Modality{mod}.BODYOutputs,nHidNodes,LearningRate,NEpochs,networknoiserate, momentum, 1,trackdevelopment);

        else
           [Baby{babycounter}.Modality{mod}.wt1 Baby{babycounter}.Modality{mod}.wt2] = backprop(Baby{babycounter}.Modality{mod}.NoisyInputs,Baby{babycounter}.Modality{mod}.ATOMOutputs,nHidNodes,LearningRate,NEpochs,networknoiserate, momentum, 1,trackdevelopment);
        end

        % %record the final weights
        % wt1 = Baby{babycounter}.Modality{mod}.wt1{NEpochs};
        % wt2 = Baby{babycounter}.Modality{mod}.wt2{NEpochs};
        % save('trainedweights1.mat', 'wt1', 'wt2');


        for devstage = 1:NEpochs
            % now get set of representative outputs from our our trained network
            % present each of the possible curves and see network prediction 
            % do this multiple times to get the prediction error (i.e. scalar property)   
            [R,C] = size(modality{mod}.MemoryCurves);
            for k = 1:OutputLoopSize
                if memorynoise
                    %add noise to memory decay curves
                    modality{mod}.NoisyInputs = modality{mod}.MemoryCurves + ...
                                          memorynoise_proportional_sd * modality{mod}.MemoryCurves .* randn(R,C);

                    modality{mod}.NoisyInputs = modality{mod}.NoisyInputs + ... 
                                          memorynoise_fixed_mean + memorynoise_fixed_sd * rand(R,C);
                    
                    %same for attention curves
                    attention{mod}.NoisyInputs = attention{mod}.MemoryCurves + ...
                                          memorynoise_proportional_sd * attention{mod}.MemoryCurves .* randn(R,C);

                    attention{mod}.NoisyInputs = attention{mod}.NoisyInputs + ... 
                                          memorynoise_fixed_mean + memorynoise_fixed_sd * rand(R,C);                  
                else
                    modality{mod}.NoisyInputs = modality{mod}.MemoryCurves;        
                    attention{mod}.NoisyInputs = attention{mod}.MemoryCurves;   
                end
                %record the network outputs
                Baby{babycounter}.Modality{mod}.TrainedOutputs{devstage}{k} = backprop_out(modality{mod}.NoisyInputs,Baby{babycounter}.Modality{mod}.wt1{devstage},Baby{babycounter}.Modality{mod}.wt2{devstage},networknoiserate);
                Baby{babycounter}.Modality{mod}.AttentionOutputs{devstage}{k} = backprop_out(attention{mod}.NoisyInputs,Baby{babycounter}.Modality{mod}.wt1{devstage},Baby{babycounter}.Modality{mod}.wt2{devstage},networknoiserate);
                %convert network output representation into a time value
                if modality{mod}.UseBODYMapRepresentation
                    Baby{babycounter}.Modality{mod}.TrainedOutTimes{devstage}(k,:) = BODYMapRepresentation(Baby{babycounter}.Modality{mod}.TrainedOutputs{devstage}{k},outputWidth,minInterval, maxInterval,true,modality{mod}.useBODYBinaryOut );
                    Baby{babycounter}.Modality{mod}.AttentionOutTimes{devstage}(k,:) = BODYMapRepresentation(Baby{babycounter}.Modality{mod}.AttentionOutputs{devstage}{k},outputWidth,minInterval, maxInterval,true,modality{mod}.useBODYBinaryOut );
                else
                    Baby{babycounter}.Modality{mod}.TrainedOutTimes{devstage}(k,:) = ATOMrepresentation(Baby{babycounter}.Modality{mod}.TrainedOutputs{devstage}{k},outputWidth,minInterval, maxInterval,true);    
                    Baby{babycounter}.Modality{mod}.AttentionOutTimes{devstage}(k,:) = ATOMrepresentation(Baby{babycounter}.Modality{mod}.AttentionOutputs{devstage}{k},outputWidth,minInterval, maxInterval,true);    
                end
            end
            %calculate mean and stdev for outputs
            Baby{babycounter}.Modality{mod}.MeanOutput{devstage} = mean(Baby{babycounter}.Modality{mod}.TrainedOutTimes{devstage}, 1);
            Baby{babycounter}.Modality{mod}.StdDevOutput{devstage} = std(Baby{babycounter}.Modality{mod}.TrainedOutTimes{devstage}, 1);
            Baby{babycounter}.Modality{mod}.RelScalarErrors{devstage} = Baby{babycounter}.Modality{mod}.StdDevOutput{devstage} ./ Baby{babycounter}.Modality{mod}.MeanOutput{devstage};
            Baby{babycounter}.Modality{mod}.AbsScalarErrors{devstage} = Baby{babycounter}.Modality{mod}.StdDevOutput{devstage} ./ modality{mod}.Intervals;
            
            Baby{babycounter}.Modality{mod}.AttentionMeanOutput{devstage} = mean(Baby{babycounter}.Modality{mod}.AttentionOutTimes{devstage}, 1);
            Baby{babycounter}.Modality{mod}.AttentionStdDevOutput{devstage} = std(Baby{babycounter}.Modality{mod}.AttentionOutTimes{devstage}, 1);
            Baby{babycounter}.Modality{mod}.AttentionRelScalarErrors{devstage} = Baby{babycounter}.Modality{mod}.AttentionStdDevOutput{devstage} ./ Baby{babycounter}.Modality{mod}.AttentionMeanOutput{devstage};
            Baby{babycounter}.Modality{mod}.AttentionAbsScalarErrors{devstage} = Baby{babycounter}.Modality{mod}.AttentionStdDevOutput{devstage} ./ modality{mod}.Intervals;

                
            if showProspectiveAttentionEffects
                for k = 1:OutputLoopSize
                    if memorynoise
                        %add noise to memory decay curves
                        modality{mod}.NoisyInputs = modality{mod}.MemoryCurves + ...
                                              memorynoise_proportional_sd * modality{mod}.MemoryCurves .* randn(R,C)+ ... 
                                              memorynoise_fixed_mean + memorynoise_fixed_sd * rand(R,C);


                        %same for attention curves
                        attention{mod}.NoisyInputs = attention{mod}.MemoryCurves + ...
                                              memorynoise_proportional_sd * attention{mod}.MemoryCurves .* randn(R,C) + ... 
                                              memorynoise_fixed_mean + memorynoise_fixed_sd * rand(R,C);                  
                    else
                        modality{mod}.NoisyInputs = modality{mod}.MemoryCurves;        
                        attention{mod}.NoisyInputs = attention{mod}.MemoryCurves;   
                    end


                    %To get the prospective time estimate outputs we let
                    %network cycle through memory curves until it's output
                    %reaches the target value then we see what input curve
                    %this actually represents. 

                    tempOutputs = backprop_out(modality{mod}.NoisyInputs,Baby{babycounter}.Modality{mod}.wt1{devstage},Baby{babycounter}.Modality{mod}.wt2{devstage},networknoiserate);
                    tempAttentionOutputs = backprop_out(attention{mod}.NoisyInputs,Baby{babycounter}.Modality{mod}.wt1{devstage},Baby{babycounter}.Modality{mod}.wt2{devstage},networknoiserate);
                    %convert network outputs representation into time
                    %values
                    if modality{mod}.UseBODYMapRepresentation
                        tempEstimates = BODYMapRepresentation(tempOutputs,outputWidth,minInterval, maxInterval,true,modality{mod}.useBODYBinaryOut );
                        tempAttentionEstimates = BODYMapRepresentation(tempAttentionOutputs,outputWidth,minInterval, maxInterval,true,modality{mod}.useBODYBinaryOut );
                    else
                        tempEstimates = ATOMrepresentation(tempOutputs,outputWidth,minInterval, maxInterval,true);    
                        tempAttentionEstimates = ATOMrepresentation(tempAttentionOutputs,outputWidth,minInterval, maxInterval,true);    
                    end
                    for thisInterval = 1:modality{1}.numIntervals
                        targetTime = modality{1}.Intervals(thisInterval);
                        %first assign a maximum in case we don't reach it.
                        Baby{babycounter}.Modality{mod}.ProspectiveOutputs{devstage}(k,thisInterval) = modality{1}.Intervals(modality{1}.numIntervals);
                        for j=1:modality{1}.numIntervals
                            if tempEstimates(j) >= targetTime
                                Baby{babycounter}.Modality{mod}.ProspectiveOutputs{devstage}(k,thisInterval) = modality{1}.Intervals(j);
                                break;
                            end
                        end
                    end
                    %now do same again for the attention estimates
                    for thisInterval = 1:modality{1}.numIntervals
                        targetTime = modality{1}.Intervals(thisInterval);
                        %first assign a maximum in case we don't reach it.
                        Baby{babycounter}.Modality{mod}.ProspectiveAttentionOutputs{devstage}(k,thisInterval) = modality{1}.Intervals(modality{1}.numIntervals);
                        for j=1:modality{1}.numIntervals
                            if tempAttentionEstimates(j) >= targetTime
                                Baby{babycounter}.Modality{mod}.ProspectiveAttentionOutputs{devstage}(k,thisInterval) = modality{1}.Intervals(j);
                                break;
                            end
                        end
                    end
                    
                end
                 %calculate mean and stdev for outputs
            Baby{babycounter}.Modality{mod}.ProspectiveMeanOutput{devstage} = mean(Baby{babycounter}.Modality{mod}.ProspectiveOutputs{devstage}, 1);
            Baby{babycounter}.Modality{mod}.ProspectiveStdDevOutput{devstage} = std(Baby{babycounter}.Modality{mod}.ProspectiveOutputs{devstage}, 1);
            Baby{babycounter}.Modality{mod}.ProspectiveRelScalarErrors{devstage} = Baby{babycounter}.Modality{mod}.ProspectiveStdDevOutput{devstage} ./ Baby{babycounter}.Modality{mod}.ProspectiveMeanOutput{devstage};
            Baby{babycounter}.Modality{mod}.ProspectiveAbsScalarErrors{devstage} = Baby{babycounter}.Modality{mod}.ProspectiveStdDevOutput{devstage} ./ modality{mod}.Intervals;
            
            Baby{babycounter}.Modality{mod}.ProspectiveAttentionMeanOutput{devstage} = mean(Baby{babycounter}.Modality{mod}.ProspectiveAttentionOutputs{devstage}, 1);
            Baby{babycounter}.Modality{mod}.ProspectiveAttentionStdDevOutput{devstage} = std(Baby{babycounter}.Modality{mod}.ProspectiveAttentionOutputs{devstage}  - ones(OutputLoopSize,1) * modality{mod}.Intervals, 1);
            Baby{babycounter}.Modality{mod}.ProspectiveAttentionRelScalarErrors{devstage} = Baby{babycounter}.Modality{mod}.ProspectiveAttentionStdDevOutput{devstage} ./ Baby{babycounter}.Modality{mod}.ProspectiveAttentionMeanOutput{devstage};
            Baby{babycounter}.Modality{mod}.ProspectiveAttentionAbsScalarErrors{devstage} = Baby{babycounter}.Modality{mod}.ProspectiveAttentionStdDevOutput{devstage} ./ modality{mod}.Intervals;

            end
        end
    end
end


%%%%%%%%%% DISPLAY THE RESULTS %%%%%%%%%%%%%%%%%%%%%%%%%
%
% first get the average baby for each time and each stage of development
% there might be a more elegant way of doing this
% but this way i can understand what i am doing!

for babycounter = 1:nBabies
    for ph = 1:modalitycount
        for devstage = 1:NEpochs
            AllOutTimes{ph}{devstage}(babycounter,:) = Baby{babycounter}.Modality{ph}.TrainedOutTimes{devstage}(1,:);
            AllMeanTimes{ph}{devstage}(babycounter,:) = Baby{babycounter}.Modality{ph}.MeanOutput{devstage};
            AllMeanErrors{ph}{devstage}(babycounter,:) = Baby{babycounter}.Modality{ph}.StdDevOutput{devstage};
            AllRelErrors{ph}{devstage}(babycounter,:) = Baby{babycounter}.Modality{ph}.RelScalarErrors{devstage};
            AllAbsErrors{ph}{devstage}(babycounter,:) = Baby{babycounter}.Modality{ph}.AbsScalarErrors{devstage};

            %same for attention modulated values
            AttnOutTimes{ph}{devstage}(babycounter,:) = Baby{babycounter}.Modality{ph}.AttentionOutTimes{devstage}(1,:);
            AttnMeanTimes{ph}{devstage}(babycounter,:) = Baby{babycounter}.Modality{ph}.AttentionMeanOutput{devstage};
            AttnMeanErrors{ph}{devstage}(babycounter,:) = Baby{babycounter}.Modality{ph}.AttentionStdDevOutput{devstage};
            AttnRelErrors{ph}{devstage}(babycounter,:) = Baby{babycounter}.Modality{ph}.AttentionRelScalarErrors{devstage};
            AttnAbsErrors{ph}{devstage}(babycounter,:) = Baby{babycounter}.Modality{ph}.AttentionAbsScalarErrors{devstage};
        end
    end
end

for devstage = 1:NEpochs   
    GlobalOutTimes{devstage} = mean(AllOutTimes{1}{devstage},1);
    GlobalMeanTimes{devstage} = mean(AllMeanTimes{1}{devstage},1);
    GlobalMeanErrors{devstage} = mean(AllMeanErrors{1}{devstage},1);
    GlobalRelErrors{devstage} = mean(AllRelErrors{1}{devstage},1);
    GlobalAbsErrors{devstage} = mean(AllAbsErrors{1}{devstage},1);
end


if showcolumnsgraph 
   %graph showing the inputs and outputs for representative set of time
   %intervals
  
   fig = figure(1);
   %Set up figure dimensions for generating the animation 
    subplot(2,1,2);
    axis([0 modality{1}.inputWidth + 1 0 1.1]);
    bar(1:modality{1}.inputWidth, modality{1}.MemoryCurves(1,:));
    xlim([0 modality{1}.inputWidth + 1]);
    ylim([0 2.2]);
    xlabel('Input Columns');
    ylabel('Activation');
    title(['Input modality {' num2str(1) '}' ]);

        %The output representation from the network
    subplot(2,1,1)
    axis([0 outputWidth + 1 0 1.1]);
    if modality{2}.UseBODYMapRepresentation
        bar(1:outputWidth, modality{1}.BODYOutputs(1,:));
    else
        bar(1:outputWidth, modality{1}.ATOMOutputs(1,:));
    end
    xlim([0 outputWidth + 1]);
    ylim([0  1.1]);
    xlabel('Output Columns');
    ylabel('Activation');
    title('Expected out');
% 
% 
%     %The output representation from the network
%     subplot(3,1,3)
%     axis([0 outputWidth + 1 0 1.1]);
%     bar(1:outputWidth, Baby{babycounter}.Modality{1}.TrainedOutputs{NEpochs}{1}(1,:));
%     xlim([0 outputWidth + 1]);
%     ylim([0  1.1]);
%     xlabel('Output Columns');
%     ylabel('Activation');
%     title('Network out');
    
    %set background to transparent
    set(gca,'color','none')
    % Get figure size
    pos = get(gcf, 'Position');
    width = pos(3); height = pos(4);
   % Preallocate data (for storing frame data)
   mov = zeros(height, width, 1, modality{ph}.numIntervals, 'uint8');
   babycounter = nBabies; % just show last run
   for ph = 1:modalitycount
       disp(['Modality ' num2str(ph)]); 
       pause;
    %First graph things after learning first modality
    for t = 1:modality{ph}.numIntervals
        
        set(fig, 'Name',  ['Phase' num2str(ph) ' - Input Time  t= ' num2str(t)]);
        
        %The guassian distributions input on this phase
        subplot(2,1,2);
        axis([0 modality{ph}.inputWidth + 1 0 1.1]);
        bar(1:modality{ph}.inputWidth, modality{ph}.MemoryCurves(t,:));
        xlim([0 modality{ph}.inputWidth + 1]);
        ylim([0 1.8]);
        xlabel('Input Columns');
        ylabel('Activation');
        title(['Input modality {' num2str(ph) '}' ]);
        

%         %The output representation from the network
%         subplot(3,1,2)
%         axis([0 outputWidth + 1 0 1.1]);
%         if modality{2}.UseBODYMapRepresentation
%             bar(1:outputWidth, modality{1}.BODYOutputs(t,:));
%         else
%             bar(1:outputWidth, modality{1}.ATOMOutputs(t,:));
%         end
%         xlim([0 outputWidth + 1]);
%         ylim([0  1.1]);
%         xlabel('Output Columns');
%         ylabel('Activation');
%         title('Expected out');
        
        
        %The output representation from the network
        subplot(2,1,1)
        axis([0 outputWidth + 1 0 1.1]);
        bar(1:outputWidth, Baby{babycounter}.Modality{ph}.TrainedOutputs{NEpochs}{1}(t,:));
        xlim([0 outputWidth + 1]);
        ylim([0  1.1]);
        xlabel('Output Columns');
        ylabel('Activation');
        title('Network out');
     
        % Get frame as an image
        f = getframe(gcf);

        % Create a colormap for the first frame. For the rest of the frames,
        % use the same colormap
        if t == 1
            [mov(:,:,1,t), map] = rgb2ind(f.cdata, 256, 'nodither');
        else
            mov(:,:,1,t) = rgb2ind(f.cdata, map, 'nodither');
        end
         pause(0.2);
    end
    % Create animated GIF
    imwrite(mov, map, 'animation2.gif', 'DelayTime', 0.2, 'LoopCount', 1);
   end
end


if showMainGraphs
    %plot final performance with error bars.
    figure(2);
    for ph= 1:modalitycount
        subplot(2,2,(ph-1)*2 +1);
        hold on;
        axis([0 maxInterval 0 maxInterval * 1.2]);
        title(['Modality ' num2str(ph) ' predictions and errors'] );
        xlabel('Time Interval /seconds');
        ylabel('Prediction /seconds');
        xlim([0  maxInterval]);
        ylim([0  maxInterval]);
        plot(modality{ph}.Intervals, modality{ph}.Intervals); 
        errorbar(modality{ph}.Intervals, Baby{babycounter}.Modality{ph}.MeanOutput{NEpochs}, 0.5* Baby{babycounter}.Modality{mod}.StdDevOutput{NEpochs});
        hold off;
        
        subplot(2,2,(ph-1)*2 +2);
        axis([0 maxInterval 0  1.2]);
        xlabel('Time Interval /seconds');
        ylabel('Prediction /seconds');
        xlim([0  maxInterval]);
        ylim([0   1.2]);
        hold on;
        plot(modality{ph}.Intervals, Baby{babycounter}.Modality{ph}.RelScalarErrors{NEpochs}, ':+r');
        plot(modality{ph}.Intervals,  Baby{babycounter}.Modality{ph}.AbsScalarErrors{NEpochs}, ':*g');

        title('Scaled output errors');
        hold off;
    end
   
    %similar to figure 2 but showing performance over development
    if trackdevelopment %check network performance after each Epoch
        figure(3);
        for ph = 1:modalitycount
            subplot(2,2,(ph-1)*2 +1);
            axis([0 maxInterval 0 maxInterval * 1.2]);
            title(['Modality ' num2str(ph)]);
            xlabel('Time Interval /seconds');
            ylabel('Prediction /seconds');
            xlim([0  maxInterval]);
            ylim([0  maxInterval]);
            hold on;
            plot(modality{ph}.Intervals, modality{ph}.Intervals); 
            for devstage = 1:NEpochs
                plot(modality{ph}.Intervals, Baby{babycounter}.Modality{ph}.MeanOutput{devstage});             
            end
            hold off;

            subplot(2,2,(ph-1)*2+2);
            axis([0 maxInterval 0  1.2]);
            xlabel('Time Interval /seconds');
            ylabel('Prediction /seconds');
            xlim([0  maxInterval]);
            ylim([0   1.2]);
            title('Average output Errors');
            hold on;
            for devstage = 1:NEpochs
                plot(modality{ph}.Intervals,  Baby{babycounter}.Modality{ph}.AbsScalarErrors{devstage}, ':+g');
            end
           hold off;
        end
    end

    %results showing subplot 1,1 as a single figure for the paper 
    figure(5); 
    hold on;
    title('Predictions over development');
    axis([0 maxInterval 0 maxInterval * 1.2]);
    xlabel('Time Interval / seconds');
    ylabel('Prediction / seconds');
    xlim([0  maxInterval]);
    ylim([0  maxInterval]);
    
    plot(modality{ph}.Intervals, modality{ph}.Intervals); 
    for devstage = 1:NEpochs
        plot(modality{ph}.Intervals, GlobalMeanTimes{devstage});             
    end
    hold off;
    
    %results for modality as single figure for the paper
    
    figure(6);
    hold on;
    title(['Global mean outputs and errors']);
    axis([0 maxInterval 0 maxInterval * 1.2]);
    xlabel('Time Interval /seconds');
    ylabel('Prediction /seconds');
    xlim([0  maxInterval]);
    ylim([0  maxInterval]);  
    line(modality{ph}.Intervals, modality{ph}.Intervals); 
    errorbar(modality{ph}.Intervals, GlobalMeanTimes{NEpochs}, GlobalMeanErrors{NEpochs});
    %errorbar(modality{ph}.Intervals, Baby{babycounter}.Modality{ph}.MeanOutput{NEpochs}, Baby{babycounter}.Modality{mod}.StdDevOutput{NEpochs});
    ax1 = gca;

    xlimits = get(ax1,'XLim');
    ylimits = get(ax1,'YLim');
    xinc = (xlimits(2)-xlimits(1))/5;
    yinc = (ylimits(2)-ylimits(1))/5;
    set(ax1,'XTick',[xlimits(1):xinc:xlimits(2)],...
        'YTick',[ylimits(1):yinc:ylimits(2)])
    
    ax2 = axes('Position',get(ax1,'Position'), ...
            'XAxisLocation','bottom',...
           'YAxisLocation','right',...
           'Color','none',...
           'XColor','w','YColor','k');
    set(ax2,'XTick',[xlimits(1):xinc:xlimits(2)],...
        'YTick',[0:0.2:1])
     ylabel(ax2, 'Error as proportion of interval');
%     set(get(ax2,'Ylabel'),'String','Fast Decay') 
    xlim(ax2, [0  maxInterval]);
    ylim(ax2, [0 1]);
    line(modality{ph}.Intervals, GlobalRelErrors{NEpochs}, 'Color', 'r', 'Parent', ax2);
%     line(modality{ph}.Intervals, Baby{babycounter}.Modality{ph}.RelScalarErrors{NEpochs}, 'Color', 'r', 'Parent', ax2);
    title('');
    hold off;
end

%%% plotcorrelations 
if showCorrelations
    if modalitycount == 2
        for n=1:NEpochs
            rhomatrix = corrcoef(Baby{babycounter}.Modality{mod}.TrainedOutTimes{n}(1,:)',Baby{babycounter}.Modality{2}.TrainedOutTimes{n}(1,:)');
            rho(n) = rhomatrix(1,2);
        end

        figure(4);
        TrainingSteps = NTrainingItems:NTrainingItems:NEpochs*NTrainingItems;
        plot(TrainingSteps, rho);
        xlabel('Training Items');
        ylabel('Correlation');
        title('Correlation between modalities over development');
    end
end

%%% plot AttentionEffect
if showAttentionEffects
    figure(7);
    for ph= 1:modalitycount
        subplot(modalitycount,1,ph);
        hold on;
        axis([0 maxInterval 0 maxInterval * 1.2]);
        xlabel('Time Interval /seconds');
        ylabel('Prediction /seconds');
        xlim([0  maxInterval]);
        ylim([0  maxInterval]);
        plot(modality{ph}.Intervals, modality{ph}.Intervals); 
        errorbar(modality{ph}.Intervals, Baby{babycounter}.Modality{ph}.MeanOutput{NEpochs}, 0.5* Baby{babycounter}.Modality{mod}.StdDevOutput{NEpochs},'-+b');
        errorbar(modality{ph}.Intervals, Baby{babycounter}.Modality{ph}.AttentionMeanOutput{NEpochs}, 0.5* Baby{babycounter}.Modality{mod}.AttentionStdDevOutput{NEpochs},'-*g');
        
        title('Effect of attention on retrospective time estimates');
        hold off;
    end
end

%%% plot AttentionEffect
if showProspectiveAttentionEffects
    figure(8);
    for ph= 1:modalitycount
        subplot(modalitycount,1,ph);
        hold on;
        axis([0 maxInterval 0 maxInterval * 1.2]);
        xlabel('Time Interval /seconds');
        ylabel('Prediction /seconds');
        xlim([0  maxInterval]);
        ylim([0  maxInterval]);
        plot(modality{ph}.Intervals, modality{ph}.Intervals); 
        errorbar(modality{ph}.Intervals, Baby{babycounter}.Modality{ph}.ProspectiveMeanOutput{NEpochs}, 0.5* Baby{babycounter}.Modality{mod}.ProspectiveStdDevOutput{NEpochs},'-+b');
        errorbar(modality{ph}.Intervals, Baby{babycounter}.Modality{ph}.ProspectiveAttentionMeanOutput{NEpochs}, 0.5* Baby{babycounter}.Modality{mod}.ProspectiveAttentionStdDevOutput{NEpochs},'-*r');
        
        title('Effect of attention on prospective time estimates');
        hold off;
    end
    
end
    
    