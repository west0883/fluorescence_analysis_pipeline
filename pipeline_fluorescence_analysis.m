% pipeline_fluorescence_analysis.m

%% Initial Setup  
% Put all needed paramters in a structure called "parameters", which you
% can then easily feed into your functions. 
clear all; 

% Create the experiment name.
parameters.experiment_name='Random Motorized Treadmill';

% Output directory name bases
parameters.dir_base='Y:\Sarah\Analysis\Experiments\';
parameters.dir_exper=[parameters.dir_base parameters.experiment_name '\']; 

% Load mice_all, pass into parameters structure
load([parameters.dir_exper '\mice_all.mat']);
parameters.mice_all = mice_all;

% ****Change here if there are specific mice, days, and/or stacks you want to work with**** 
parameters.mice_all = parameters.mice_all(1);


% Include stacks from a "spontaneous" field of mice_all?
parameters.use_spontaneous_also = true;

% Other parameters
parameters.digitNumber = 2;
parameters.pixels = [256 256];


%% Run fluorescence extraction. 

% Iterators
parameters.loop_list.iterators = {'mouse', {'loop_variables.mice_all(:).name'}, 'mouse_iterator'; 
               'day', {'loop_variables.mice_all(', 'mouse_iterator', ').days(:).name'}, 'day_iterator';
               'stack', {'[loop_variables.mice_all(',  'mouse_iterator', ').days(', 'day_iterator', ').stacks; loop_variables.mice_all(',  'mouse_iterator', ').days(', 'day_iterator', ').spontaneous]'}, 'stack_iterator'};

parameters.loop_variables.mice_all = parameters.mice_all;

% Dimension different sources are in
parameters.sourcesDim = 3; 

% If the mean timeseries should be weighted by the weights of pixels in the sources (default is uniform mask)
parameters.weightedMean = true; 

% Input values

% Source masks
parameters.loop_list.things_to_load.sources.dir = {[parameters.dir_exper 'spatial segmentation\500 SVD components\manual assignments\'], 'mouse', '\'};
parameters.loop_list.things_to_load.sources.filename= {'sources_reordered.mat'};
parameters.loop_list.things_to_load.sources.variable= {'sources'};
parameters.loop_list.things_to_load.sources.level = 'mouse';

% Preprocessed fluorescence data videos
parameters.loop_list.things_to_load.data.dir = {[parameters.dir_exper 'preprocessing\fully preprocessed stacks\'], 'mouse', '\', 'day', '\'};
parameters.loop_list.things_to_load.data.filename= {'data', 'stack', '.mat'};
parameters.loop_list.things_to_load.data.variable= {'data'}; 
parameters.loop_list.things_to_load.data.level = 'stack';

% Brain masks to apply to sources, if necessary
parameters.loop_list.things_to_load.indices_of_mask.dir = {[parameters.dir_exper 'preprocessing\masks\']};
parameters.loop_list.things_to_load.indices_of_mask.filename= {'masks_m', 'mouse', '.mat'};
parameters.loop_list.things_to_load.indices_of_mask.variable= {'indices_of_mask'}; 
parameters.loop_list.things_to_load.indices_of_mask.level = 'mouse';

% Output values. 
parameters.loop_list.things_to_save.timeseries.dir = {[parameters.dir_exper 'fluorescence analysis\timeseries\'], 'mouse', '\', 'day', '\'};
parameters.loop_list.things_to_save.timeseries.filename= {'timeseries', 'stack', '.mat'};
parameters.loop_list.things_to_save.timeseries.variable= {'timeseries'}; 
parameters.loop_list.things_to_save.timeseries.level = 'stack';

% Run 
RunAnalysis({@ExtractFluorescenceTimeseries}, parameters);

%% Motorized: Segment fluorescence by behavior period

% We don't care about the specifics of the behavior yet, 

% Always clear loop list first. 
if isfield(parameters, 'loop_list')
parameters = rmfield(parameters,'loop_list');
end
% Load names of periods
load([parameters.dir_exper 'periods_nametable.mat']);

% Iterators
parameters.loop_list.iterators = {'mouse', {'loop_variables.mice_all(:).name'}, 'mouse_iterator'; 
               'day', {'loop_variables.mice_all(', 'mouse_iterator', ').days(:).name'}, 'day_iterator';
                   'stack', {'loop_variables.mice_all(',  'mouse_iterator', ').days(', 'day_iterator', ').stacks'}, 'stack_iterator'};

parameters.loop_variables.mice_all = parameters.mice_all;
parameters.loop_variables.periods_nametable = periods; 

% Skip any files that don't exist (spontaneous or problem files)
parameters.load_abort_flag = true; 

% Dimension of different time range pairs.
parameters.rangePairs = 1; 

% 
parameters.segmentDim = 1;
parameters.concatDim = 3;

% Input values. 
% Extracted timeseries.
parameters.loop_list.things_to_load.timeseries.dir = {[parameters.dir_exper 'fluorescence analysis\timeseries\'], 'mouse', '\', 'day', '\'};
parameters.loop_list.things_to_load.timeseries.filename= {'timeseries', 'stack', '.mat'};
parameters.loop_list.things_to_load.timeseries.variable= {'timeseries'}; 
parameters.loop_list.things_to_load.timeseries.level = 'stack';

% Time ranges
parameters.loop_list.things_to_load.time_ranges.dir = {[parameters.dir_exper 'behavior\motorized\period instances table format\'], 'mouse', '\', 'day', '\'};
parameters.loop_list.things_to_load.time_ranges.filename= {'all_periods_', 'stack', '.mat'};
parameters.loop_list.things_to_load.time_ranges.variable= {'all_periods.time_ranges'}; 
parameters.loop_list.things_to_load.time_ranges.level = 'stack';

% Output Values
parameters.loop_list.things_to_save.segmented_timeseries.dir = {[parameters.dir_exper 'fluorescence analysis\segmented timeseries\motorized\'], 'mouse', '\', 'day', '\'};
parameters.loop_list.things_to_save.segmented_timeseries.filename= {'segmented_timeseries_', 'stack', '.mat'};
parameters.loop_list.things_to_save.segmented_timeseries.variable= {'segmented_timeseries'}; 
parameters.loop_list.things_to_save.segmented_timeseries.level = 'stack';

RunAnalysis({@SegmentTimeseriesData}, parameters);


%% Concatenate fluorescence by behavior per mouse 
% Always clear loop list first. 
if isfield(parameters, 'loop_list')
parameters = rmfield(parameters,'loop_list');
end

% Iterators
parameters.loop_list.iterators = {'mouse', {'loop_variables.mice_all(:).name'}, 'mouse_iterator'; 
               'day', {'loop_variables.mice_all(', 'mouse_iterator', ').days(:).name'}, 'day_iterator';
               'stack', {'loop_variables.mice_all(',  'mouse_iterator', ').days(', 'day_iterator', ').stacks'}, 'stack_iterator'             
               };

parameters.loop_variables.mice_all = parameters.mice_all;

% Load motorized behavior periods list, put into loop_variables &
% parameters.
% load([dir_exper 'periods.mat']);
% parameters.loop_variables.periods = periods; 
% parameters.periods = periods;

% Dimension to concatenate the timeseries across.
parameters.concatDim = 3; 

% Clear any reshaping instructions 
if isfield(parameters, 'reshapeDims')
    parameters = rmfield(parameters,'reshapeDims');
end

% Input Values
parameters.loop_list.things_to_load.data.dir = {[parameters.dir_exper 'fluorescence analysis\segmented timeseries\motorized\'], 'mouse', '\', 'day', '\'};
parameters.loop_list.things_to_load.data.filename= {'segmented_timeseries_', 'stack', '.mat'};
parameters.loop_list.things_to_load.data.variable= {'segmented_timeseries'}; 
parameters.loop_list.things_to_load.data.level = 'stack';

% Output values
parameters.loop_list.things_to_save.concatenated_data.dir = {[parameters.dir_exper 'fluorescence analysis\concatenated timeseries\motorized\'], 'mouse', '\'};
parameters.loop_list.things_to_save.concatenated_data.filename= {'concatenated_timeseries_all_periods.mat'};
parameters.loop_list.things_to_save.concatenated_data.variable= {'timeseries'}; 
parameters.loop_list.things_to_save.concatenated_data.level = 'mouse';

RunAnalysis({@ConcatenateData}, parameters);

%% Take average of fluorescence by behavior 

% Always clear loop list first. 
if isfield(parameters, 'loop_list')
parameters = rmfield(parameters,'loop_list');
end

% Iterators
parameters.loop_list.iterators = {'mouse', {'loop_variables.mice_all(:).name'}, 'mouse_iterator'; 
               'period', {'loop_variables.periods.condition'}, 'period_iterator';
                           
               };

% Load motorized behavior periods list, put into loop_variables 
load([parameters.dir_exper 'periods_nametable.mat']);
parameters.loop_variables.periods = periods; 

parameters.loop_variables.mice_all = parameters.mice_all;

% Dimension to average across
parameters.averageDim = 3; 

% Input 
parameters.loop_list.things_to_load.data.dir = {[parameters.dir_exper 'fluorescence analysis\concatenated timeseries\motorized\'], 'mouse', '\'};
parameters.loop_list.things_to_load.data.filename= {'concatenated_timeseries_all_periods.mat'};
parameters.loop_list.things_to_load.data.variable= {'timeseries{', 'period_iterator', '}'}; 
parameters.loop_list.things_to_load.data.level = 'mouse';

% Output
parameters.loop_list.things_to_save.average.dir = {[parameters.dir_exper 'fluorescence analysis\concatenated timeseries\motorized\'], 'mouse', '\'};
parameters.loop_list.things_to_save.average.filename= {'average_timeseries_all_periods_mean.mat'};
parameters.loop_list.things_to_save.average.variable= {'average{', 'period_iterator', ',1}'}; 
parameters.loop_list.things_to_save.average.level = 'mouse';

parameters.loop_list.things_to_save.std_dev.dir = {[parameters.dir_exper 'fluorescence analysis\concatenated timeseries\motorized\'], 'mouse', '\'};
parameters.loop_list.things_to_save.std_dev.filename= {'average_timeseries_all_periods_std.mat'};
parameters.loop_list.things_to_save.std_dev.variable= {'std_dev{', 'period_iterator', ',1}'}; 
parameters.loop_list.things_to_save.std_dev.level = 'mouse';

RunAnalysis({@AverageData}, parameters);

%% Roll data 

% Always clear loop list first. 
if isfield(parameters, 'loop_list')
parameters = rmfield(parameters,'loop_list');
end

% Iterators
parameters.loop_list.iterators = {'mouse', {'loop_variables.mice_all(:).name'}, 'mouse_iterator'; 
               'period', {'loop_variables.periods.condition'}, 'period_iterator';            
               };

% Load motorized behavior periods list, put into loop_variables 
load([parameters.dir_exper 'periods_nametable.mat']);
parameters.loop_variables.periods = periods; 

parameters.loop_variables.mice_all = parameters.mice_all;

% Dimension to roll across (time dimension). Will automatically add new
% data to the last + 1 dimension. 
parameters.rollDim = 1; 

% Window and step sizes (in frames)
parameters.windowSize = 20;
parameters.stepSize = 5; 

% Input 
parameters.loop_list.things_to_load.data.dir = {[parameters.dir_exper 'fluorescence analysis\concatenated timeseries\motorized\'], 'mouse', '\'};
parameters.loop_list.things_to_load.data.filename= {'concatenated_timeseries_all_periods.mat'};
parameters.loop_list.things_to_load.data.variable= {'timeseries{', 'period_iterator', '}'}; 
parameters.loop_list.things_to_load.data.level = 'mouse';

% Output
parameters.loop_list.things_to_save.data_rolled.dir = {[parameters.dir_exper 'fluorescence analysis\concatenated timeseries\motorized\'], 'mouse', '\'};
parameters.loop_list.things_to_save.data_rolled.filename= {'timeseries_rolled.mat'};
parameters.loop_list.things_to_save.data_rolled.variable= {'timeseries_rolled{', 'period_iterator', ',1}'}; 
parameters.loop_list.things_to_save.data_rolled.level = 'mouse';

parameters.loop_list.things_to_save.roll_number.dir = {[parameters.dir_exper 'fluorescence analysis\concatenated timeseries\motorized\'], 'mouse', '\'};
parameters.loop_list.things_to_save.roll_number.filename= {'roll_number.mat'};
parameters.loop_list.things_to_save.roll_number.variable= {'roll_number{', 'period_iterator', ', 1}'}; 
parameters.loop_list.things_to_save.roll_number.level = 'mouse';

RunAnalysis({@RollData}, parameters);

%% Correlate data

% Always clear loop list first. 
if isfield(parameters, 'loop_list')
parameters = rmfield(parameters,'loop_list');
end

% Iterators
parameters.loop_list.iterators = {'mouse', {'loop_variables.mice_all(:).name'}, 'mouse_iterator'; 
               'period', {'loop_variables.periods.condition'}, 'period_iterator';            
               };

% Load motorized behavior periods list, put into loop_variables 
load([parameters.dir_exper 'periods_nametable.mat']);
parameters.loop_variables.periods = periods; 

parameters.loop_variables.mice_all = parameters.mice_all;

% Dimension to correlate across (dimensions where different sources are). 
parameters.sourceDim = 2; 

% Time dimension (the dimension of the timeseries that will be correlated)
parameters.timeDim = 1; 

% Input 
parameters.loop_list.things_to_load.data.dir = {[parameters.dir_exper 'fluorescence analysis\concatenated timeseries\motorized\'], 'mouse', '\'};
parameters.loop_list.things_to_load.data.filename= {'timeseries_rolled.mat'};
parameters.loop_list.things_to_load.data.variable= {'timeseries_rolled{', 'period_iterator', ',1}'}; 
parameters.loop_list.things_to_load.data.level = 'mouse';

% Output
parameters.loop_list.things_to_save.correlation.dir = {[parameters.dir_exper 'fluorescence analysis\correlations\motorized\'], 'mouse', '\instances\'};
parameters.loop_list.things_to_save.correlation.filename= {'correlations_', 'period', '_', 'period_iterator', '.mat'};
parameters.loop_list.things_to_save.correlation.variable= {'correlations'}; 
parameters.loop_list.things_to_save.correlation.level = 'period';

RunAnalysis({@CorrelateTimeseriesData}, parameters);

%% Average rolled correlations

% Always clear loop list first. 
if isfield(parameters, 'loop_list')
parameters = rmfield(parameters,'loop_list');
end

% Iterators
parameters.loop_list.iterators = {'mouse', {'loop_variables.mice_all(:).name'}, 'mouse_iterator'; 
               'period', {'loop_variables.periods.condition'}, 'period_iterator';            
               };

% Load motorized behavior periods list, put into loop_variables 
load([parameters.dir_exper 'periods_nametable.mat']);
parameters.loop_variables.periods = periods; 

% Dimension to average across
parameters.averageDim = 3; 

parameters.loop_variables.mice_all = parameters.mice_all;
% Input 
parameters.loop_list.things_to_load.data.dir = {[parameters.dir_exper 'fluorescence analysis\correlations\motorized\'], 'mouse', '\instances\'};
parameters.loop_list.things_to_load.data.filename= {'correlations_', 'period', '_', 'period_iterator', '.mat'};
parameters.loop_list.things_to_load.data.variable= {'correlations'}; 
parameters.loop_list.things_to_load.data.level = 'period';

% Output
parameters.loop_list.things_to_save.average.dir = {[parameters.dir_exper 'fluorescence analysis\correlations\motorized\'], 'mouse', '\average rolled\'};
parameters.loop_list.things_to_save.average.filename= {'correlations_rolled_average.mat'};
parameters.loop_list.things_to_save.average.variable= {'average{', 'period_iterator', ',1}'}; 
parameters.loop_list.things_to_save.average.level = 'mouse';

parameters.loop_list.things_to_save.std_dev.dir = {[parameters.dir_exper 'fluorescence analysis\correlations\motorized\'], 'mouse', '\average rolled\'};
parameters.loop_list.things_to_save.std_dev.filename= {'correlations_rolled_std.mat'};
parameters.loop_list.things_to_save.std_dev.variable= {'std_dev{', 'period_iterator', ',1}'}; 
parameters.loop_list.things_to_save.std_dev.level = 'mouse';

RunAnalysis({@AverageData}, parameters);

%% Put all correlation matrices into same concatenation (for PCA and other metrics)

% Always clear loop list first. 
if isfield(parameters, 'loop_list')
parameters = rmfield(parameters,'loop_list');
end

% Iterators
parameters.loop_list.iterators = {'mouse', {'loop_variables.mice_all(:).name'}, 'mouse_iterator'; 
               'period', {'loop_variables.periods.condition'}, 'period_iterator';            
               };

% Load motorized behavior periods list, put into loop_variables 
load([parameters.dir_exper 'periods_nametable.mat']);
parameters.loop_variables.periods = periods; 

parameters.loop_variables.mice_all = parameters.mice_all;

% Dimensions for reshaping before cnocatenation
parameters.reshapeDims = {'{size(parameters.data, 1), size(parameters.data,2), []}'};

% Concatenation dimension (post reshaping)
parameters.concatDim = 3; 

% Input 
parameters.loop_list.things_to_load.data.dir = {[parameters.dir_exper 'fluorescence analysis\correlations\motorized\'], 'mouse', '\instances\'};
parameters.loop_list.things_to_load.data.filename= {'correlations_', 'period', '_', 'period_iterator', '.mat'};
parameters.loop_list.things_to_load.data.variable= {'correlations'}; 
parameters.loop_list.things_to_load.data.level = 'period';

% Output
parameters.loop_list.things_to_save.concatenated_data.dir = {[parameters.dir_exper 'fluorescence analysis\correlations\motorized\'], 'mouse', '\all concatenated\'};
parameters.loop_list.things_to_save.concatenated_data.filename= {'correlations_all_concatenated.mat'};
parameters.loop_list.things_to_save.concatenated_data.variable= {'correlations_concatenated'}; 
parameters.loop_list.things_to_save.concatenated_data.level = 'mouse';

% Things to rename/reassign between the two functions (frist column renamed to
% second column. Pairs for each level. Each row is a level.
parameters.loop_list.things_to_rename = {{'data_reshaped', 'data'}};

% Things to hold example (didn't use here). Each row is a level.
% parameters.loop_list.things_to_hold = {{'data'}}; 

RunAnalysis({@ReshapeData, @ConcatenateData}, parameters); 

%% 


