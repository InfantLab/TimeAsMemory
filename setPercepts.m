function percept = setPercepts(inputType, minInterval,maxInterval,numIntervals, ...
                                inputWidth,outputWidth,fixedLocation,...
                                memoryWidthUnit,memoryTimeUnit,memoryAmplitude,...
                                spread_factor,leakage_factor,self_excitation, ...
                                lognormalIntervals,useBODYMapRepresentation,useBODYBinaryOut)
%
%helper function that sets up the features of the perceptual field that
%experiences the events and where they decay. 
%
% we claim that memory is normal distribution that decays analogously to Fitt's law.
% so if width of stdev after K seconds is W, after 2K seconds it will be 2W
% therefore we need to specify a scale for both

% do we use simulated fading gaussians or just use an equation for each gaussian?
if nargin < 1,  percept.inputType = 0;          else percept.inputType = inputType; end
if nargin < 2,  percept.minInterval = 0.1;      else percept.minInterval = minInterval; end 
if nargin < 3,  percept.maxInterval = 90;       else percept.maxInterval = maxInterval; end
if nargin < 4,  percept.numIntervals = 40;      else percept.numIntervals = numIntervals; end
if nargin < 5,  percept.inputWidth = 41;        else percept.inputWidth = inputWidth;  end
if nargin < 6,  percept.outputWidth = 10;       else percept.outputWidth = outputWidth; end
if nargin < 7,  percept.fixedLocation = true;   else percept.fixedLocation = fixedLocation; end
if nargin < 8,  percept.memoryWidthUnit = 5;    else percept.memoryWidthUnit = memoryWidthUnit; end  % W
if nargin < 9,  percept.memoryTimeUnit = 20;    else percept.memoryTimeUnit  =memoryTimeUnit; end % K  
if nargin < 10, percept.memoryAmplitude = 10;   else percept.memoryAmplitude = memoryAmplitude; end 
if nargin < 11, percept.spread_factor = 0.0045; else percept.spread_factor =  spread_factor; end
if nargin < 12, percept.leakage_factor = 0.0105;else percept.leakage_factor = leakage_factor; end
if nargin < 13, percept.self_excitation = 0.1;  else percept.self_excitation = self_excitation; end
%are experienced intervals evenly distributed or lognormally distributed?
if nargin < 14, percept.lognormalIntervals = 0; else percept.lognormalIntervals = lognormalIntervals;   end
if nargin < 15, percept.UseBODYMapRepresentation =true;      else percept.UseBODYMapRepresentation = useBODYMapRepresentation; end
if nargin < 16, percept.useBODYBinaryOut = false; else percept.useBODYBinaryOut = useBODYBinaryOut; end

