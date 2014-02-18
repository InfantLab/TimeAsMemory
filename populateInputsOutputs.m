function percept = populateInputsOutputs(percept)
%

%have set up the basic parameters now generate a set of gaussian curves.
[percept.Intervals, percept.MemoryCurves] = getFadingGaussians(percept);
%and the corresponding expected outputs
percept.ATOMOutputs =    ATOMrepresentation(percept.Intervals',percept.outputWidth,percept.minInterval, percept.maxInterval);
percept.BODYOutputs = BODYMapRepresentation(percept.Intervals',percept.outputWidth,percept.minInterval, percept.maxInterval,false,percept.useBODYBinaryOut);

