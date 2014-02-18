
ANALYTIC_GAUSSIAN = 0;
FADING_GAUSSIAN = 1;

inputType = 0;
minInterval = 0.1; %seconds
maxInterval = 120; %seconds 
numIntervals = 60;



%network architecture
inputWidth = 41;    %how wide is input vector?
nHidNodes = 10;
outputWidth = 10;   %how wide is output vector
fixedLocation = true;


attentionMultiplier = 1.2; 

modality{1} = setPercepts(0,minInterval,maxInterval,numIntervals, ...
                          inputWidth, outputWidth,fixedLocation, ...
                          5, 45, 2, ...
                          0.0045, 0.0105, 0.001, ...
                          false, true, false);
modality{1} = populateInputsOutputs(modality{1});    

%for the moment the second modality is very similar to first
modality{2} = setPercepts(1,minInterval,maxInterval,numIntervals, ...
                          inputWidth, outputWidth,fixedLocation, ...
                          5, 45, 2, ...
                          0.0045, 0.0105 , 0.001  , ...
                          false, true, false);
modality{2} = populateInputsOutputs(modality{2});    


fig = figure(1);

for t = 1:modality{1}.numIntervals
        pause(0.4);
        set(fig, 'Name',  ['Phase' num2str(1) ' - Input Time  t= ' num2str(t)]);
        
        %The guassian distributions input on this phase
        subplot(2,1,1);
        axis([0 modality{1}.inputWidth + 1 0 1.1]);
        bar(1:modality{1}.inputWidth, modality{1}.MemoryCurves(t,:));
        xlim([0 modality{1}.inputWidth + 1]);
        ylim([0 2.2]);
        xlabel('Input Columns');
        ylabel('Activation');
        title(['Input modality {1}' ]);
        
        %The guassian distribution that is input.
        subplot(2,1,2);
        axis([0 modality{2}.inputWidth + 1 0 1.1]);
        bar(1:modality{2}.inputWidth, modality{2}.MemoryCurves(t,:) );
        xlim([0 modality{2}.inputWidth + 1]);
        ylim([0 2.2]);
        xlabel('Input Columns');
        ylabel('Activation');
        title(['Input modality {2}' ]);
end