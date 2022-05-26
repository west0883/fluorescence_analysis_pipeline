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
%parameters.mice_all(1).days = parameters.mice_all(1).days(10:end);

% Include stacks from a "spontaneous" field of mice_all?
parameters.use_spontaneous_also = true;

% Other parameters
parameters.digitNumber = 2;
parameters.yDim = 256;
parameters.xDim = 256;
number_of_sources = 32; 

% Make a conditions structure
conditions= {'motorized'; 'spontaneous'};
conditions_stack_locations = {'stacks'; 'spontaneous'};

% Load names of motorized periods
load([parameters.dir_exper 'periods_nametable.mat']);

periods_spontaneous = {'rest';'walk';'startwalk';'prewalk';'stopwalk';'postwalk';'full_onset';'full_offset'};

% Create a shared motorized & spontaneous list.
periods_bothConditions = [periods.condition; periods_spontaneous]; 

% Make list of transformation types for iterating later.
transformations = {'not transformed'; 'Fisher transformed'};

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

% Brain masks to apply to sources, if necessary. (Source formats need to
% match the fluorescence data videos formats)
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

%% SPONTANEOUS-- Segment fluorescence by behavior period

% Always clear loop list first. 
if isfield(parameters, 'loop_list')
parameters = rmfield(parameters,'loop_list');
end

% Iterators
parameters.loop_list.iterators = {'mouse', {'loop_variables.mice_all(:).name'}, 'mouse_iterator'; 
               'day', {'loop_variables.mice_all(', 'mouse_iterator', ').days(:).name'}, 'day_iterator';
                   'stack', {'loop_variables.mice_all(',  'mouse_iterator', ').days(', 'day_iterator', ').spontaneous'}, 'stack_iterator';
                   'period', {'loop_variables.periods_spontaneous{:}'}, 'period_iterator'};

parameters.loop_variables.mice_all = parameters.mice_all;
parameters.loop_variables.periods_spontaneous = periods_spontaneous; 

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
parameters.loop_list.things_to_load.time_ranges.dir = {[parameters.dir_exper 'behavior\spontaneous\segmented behavior periods\'], 'mouse', '\', 'day', '\'};
parameters.loop_list.things_to_load.time_ranges.filename= {'behavior_periods_', 'stack', '.mat'};
parameters.loop_list.things_to_load.time_ranges.variable= {'behavior_periods.', 'period'}; 
parameters.loop_list.things_to_load.time_ranges.level = 'stack';

% Output Values
% (Convert to cell format to be compatible with motorized in below code)
parameters.loop_list.things_to_save.segmented_timeseries.dir = {[parameters.dir_exper 'fluorescence analysis\segmented timeseries\spontaneous\'], 'mouse', '\', 'day', '\'};
parameters.loop_list.things_to_save.segmented_timeseries.filename= {'segmented_timeseries_', 'stack', '.mat'};
parameters.loop_list.things_to_save.segmented_timeseries.variable= {'segmented_timeseries{', 'period_iterator',',1}'}; 
parameters.loop_list.things_to_save.segmented_timeseries.level = 'stack';

RunAnalysis({@SegmentTimeseriesData}, parameters);

%% Concatenate fluorescence by behavior per mouse 

% Always clear loop list first. 
if isfield(parameters, 'loop_list')
parameters = rmfield(parameters,'loop_list');
end

% Iterators
parameters.loop_list.iterators = {
               'condition', {'loop_variables.conditions'}, 'condition_iterator';
               'mouse', {'loop_variables.mice_all(:).name'}, 'mouse_iterator'; 
               'day', {'loop_variables.mice_all(', 'mouse_iterator', ').days(:).name'}, 'day_iterator';
               'stack', {'getfield(loop_variables, {1}, "mice_all", {',  'mouse_iterator', '}, "days", {', 'day_iterator', '}, ', 'loop_variables.conditions_stack_locations{', 'condition_iterator', '})'}, 'stack_iterator'; 
               };

parameters.loop_variables.mice_all = parameters.mice_all;
parameters.loop_variables.conditions = conditions;
parameters.loop_variables.conditions_stack_locations = conditions_stack_locations;

% Dimension to concatenate the timeseries across.
parameters.concatDim = 3; 
parameters.concatenate_across_cells = false; 

% Clear any reshaping instructions 
if isfield(parameters, 'reshapeDims')
    parameters = rmfield(parameters,'reshapeDims');
end

% Input Values
parameters.loop_list.things_to_load.data.dir = {[parameters.dir_exper 'fluorescence analysis\segmented timeseries\'],'condition', '\' 'mouse', '\', 'day', '\'};
parameters.loop_list.things_to_load.data.filename= {'segmented_timeseries_', 'stack', '.mat'};
parameters.loop_list.things_to_load.data.variable= {'segmented_timeseries'}; 
parameters.loop_list.things_to_load.data.level = 'stack';

% Output values
parameters.loop_list.things_to_save.concatenated_data.dir = {[parameters.dir_exper 'fluorescence analysis\concatenated timeseries\'], 'condition', '\', 'mouse', '\'};
parameters.loop_list.things_to_save.concatenated_data.filename= {'concatenated_timeseries_all_periods.mat'};
parameters.loop_list.things_to_save.concatenated_data.variable= {'timeseries'}; 
parameters.loop_list.things_to_save.concatenated_data.level = 'mouse';

RunAnalysis({@ConcatenateData}, parameters);

%% Concatenate motorized & spontaneous together. 

% Is so you can use a single loop for calculations. Will be useful later if
% you want to run lists of behavior comparisons and don't want to make different
% calls when you have different combinations of motorized & spontaneous. 
% Iterators

% [Make sure there aren't any issues with concatenating cells with empty
% entries.]

parameters.loop_list.iterators = {'mouse', {'loop_variables.mice_all(:).name'}, 'mouse_iterator'; 
               'condition', 'loop_variables.conditions', 'condition_iterator';
                };

parameters.loop_vairables.conditions = conditions;
% Tell it to concatenate across cells, not within cells. 
parameters.concatenate_across_cells = true; 
parameters.concatDim = 1;

% Input Values (use a trick to concatenate just the 2 conditions)
parameters.loop_list.things_to_load.data.dir = {[parameters.dir_exper 'fluorescence analysis\concatenated timeseries\'], 'condition', '\', 'mouse', '\'};
parameters.loop_list.things_to_load.data.filename= {'concatenated_timeseries_all_periods.mat'};
parameters.loop_list.things_to_load.data.variable= {'timeseries'}; 
parameters.loop_list.things_to_load.data.level = 'condition';

% Output values
parameters.loop_list.things_to_save.concatenated_data.dir = {[parameters.dir_exper 'fluorescence analysis\concatenated timeseries both conditions\'], 'mouse', '\'};
parameters.loop_list.things_to_save.concatenated_data.filename= {'concatenated_timeseries_all_periods.mat'};
parameters.loop_list.things_to_save.concatenated_data.variable= {'timeseries_all'}; 
parameters.loop_list.things_to_save.concatenated_data.level = 'mouse';

RunAnalysis({@ConcatenateData}, parameters);


%% [FROM HERE DOWN YOU CAN COMBINE MOTORIZED & SPONTANOUS SECTIONS]
% Because they're concatenated.

%% Take average of fluorescence by behavior 

% Always clear loop list first. 
if isfield(parameters, 'loop_list')
parameters = rmfield(parameters,'loop_list');
end

% Iterators
parameters.loop_list.iterators = {
                'mouse', {'loop_variables.mice_all(:).name'}, 'mouse_iterator'; 
                'period', {'loop_variables.periods'}, 'period_iterator';              
               };

parameters.loop_variables.periods = periods_bothConditions; 
parameters.loop_variables.mice_all = parameters.mice_all;

% Dimension to average across
parameters.averageDim = 3; 

% Input 
parameters.loop_list.things_to_load.data.dir = {[parameters.dir_exper 'fluorescence analysis\concatenated timeseries both conditions\'], 'mouse', '\'};
parameters.loop_list.things_to_load.data.filename= {'concatenated_timeseries_all_periods.mat'};
parameters.loop_list.things_to_load.data.variable= {'timeseries_all{', 'period_iterator', '}'}; 
parameters.loop_list.things_to_load.data.level = 'mouse';

% Output
parameters.loop_list.things_to_save.average.dir = {[parameters.dir_exper 'fluorescence analysis\concatenated timeseries both conditions\'], 'mouse', '\'};
parameters.loop_list.things_to_save.average.filename= {'average_timeseries_all_periods_mean.mat'};
parameters.loop_list.things_to_save.average.variable= {'average{', 'period_iterator', ',1}'}; 
parameters.loop_list.things_to_save.average.level = 'mouse';

parameters.loop_list.things_to_save.std_dev.dir = {[parameters.dir_exper 'fluorescence analysis\concatenated timeseries both conditions\'], 'mouse', '\'};
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
               'period', {'loop_variables.periods'}, 'period_iterator';            
               };

parameters.loop_variables.periods = periods_bothConditions; 
parameters.loop_variables.mice_all = parameters.mice_all;

% Dimension to roll across (time dimension). Will automatically add new
% data to the last + 1 dimension. 
parameters.rollDim = 1; 

% Window and step sizes (in frames)
parameters.windowSize = 20;
parameters.stepSize = 5; 

% Input 
parameters.loop_list.things_to_load.data.dir = {[parameters.dir_exper 'fluorescence analysis\concatenated timeseries both conditions\'], 'mouse', '\'};
parameters.loop_list.things_to_load.data.filename= {'concatenated_timeseries_all_periods.mat'};
parameters.loop_list.things_to_load.data.variable= {'timeseries_all{', 'period_iterator', '}'}; 
parameters.loop_list.things_to_load.data.level = 'mouse';

% Output
parameters.loop_list.things_to_save.data_rolled.dir = {[parameters.dir_exper 'fluorescence analysis\rolled timeseries\'], 'mouse', '\'};
parameters.loop_list.things_to_save.data_rolled.filename= {'timeseries_rolled.mat'};
parameters.loop_list.things_to_save.data_rolled.variable= {'timeseries_rolled{', 'period_iterator', ',1}'}; 
parameters.loop_list.things_to_save.data_rolled.level = 'mouse';

parameters.loop_list.things_to_save.roll_number.dir = {[parameters.dir_exper 'fluorescence analysis\rolled timeseries\'], 'mouse', '\'};
parameters.loop_list.things_to_save.roll_number.filename= {'roll_number.mat'};
parameters.loop_list.things_to_save.roll_number.variable= {'roll_number{', 'period_iterator', ', 1}'}; 
parameters.loop_list.things_to_save.roll_number.level = 'mouse';

RunAnalysis({@RollData}, parameters);

%% Correlate data
% Separating these into smaller files because correlating takes a long time
% & I want the progress to be saved periodically.

% Always clear loop list first. 
if isfield(parameters, 'loop_list')
parameters = rmfield(parameters,'loop_list');
end

% Iterators
parameters.loop_list.iterators = {'mouse', {'loop_variables.mice_all(:).name'}, 'mouse_iterator'; 
               'period', {'loop_variables.periods'}, 'period_iterator';            
               };

parameters.loop_variables.periods = periods_bothConditions; 
parameters.loop_variables.mice_all = parameters.mice_all;

% Dimension to correlate across (dimensions where different sources are). 
parameters.sourceDim = 2; 

% Time dimension (the dimension of the timeseries that will be correlated)
parameters.timeDim = 1; 

% Input 
parameters.loop_list.things_to_load.data.dir = {[parameters.dir_exper 'fluorescence analysis\rolled timeseries\'], 'mouse', '\'};
parameters.loop_list.things_to_load.data.filename= {'timeseries_rolled.mat'};
parameters.loop_list.things_to_load.data.variable= {'timeseries_rolled{', 'period_iterator', ',1}'}; 
parameters.loop_list.things_to_load.data.level = 'mouse';

% Output
parameters.loop_list.things_to_save.correlation.dir = {[parameters.dir_exper 'fluorescence analysis\correlations\not transformed\'], 'mouse', '\instances\'};
parameters.loop_list.things_to_save.correlation.filename= {'correlations_', 'period', '_', 'period_iterator', '.mat'};
parameters.loop_list.things_to_save.correlation.variable= {'correlations'}; 
parameters.loop_list.things_to_save.correlation.level = 'period';

RunAnalysis({@CorrelateTimeseriesData}, parameters);

%% Run Fisher z - transformation 
% Save as separate files so you match the structure of the correlation
% matrices for looping in the next steps. 

% Always clear loop list first. 
if isfield(parameters, 'loop_list')
parameters = rmfield(parameters,'loop_list');
end

% Iterators
parameters.loop_list.iterators = {'mouse', {'loop_variables.mice_all(:).name'}, 'mouse_iterator'; 
               'period', {'loop_variables.periods'}, 'period_iterator';            
               };

parameters.loop_variables.periods = periods_bothConditions; 
parameters.loop_variables.mice_all = parameters.mice_all;

% Input
parameters.loop_list.things_to_load.data.dir = {[parameters.dir_exper 'fluorescence analysis\correlations\not transformed\'], 'mouse', '\instances\'};
parameters.loop_list.things_to_load.data.filename= {'correlations_', 'period', '_', 'period_iterator', '.mat'};
parameters.loop_list.things_to_load.data.variable= {'correlations'}; 
parameters.loop_list.things_to_load.data.level = 'period';

% Output 
parameters.loop_list.things_to_save.data_transformed.dir = {[parameters.dir_exper 'fluorescence analysis\correlations\Fisher transformed\'], 'mouse', '\instances\'};
parameters.loop_list.things_to_save.data_transformed.filename= {'correlations_', 'period', '_', 'period_iterator', '.mat'};
parameters.loop_list.things_to_save.data_transformed.variable= {'correlations'}; 
parameters.loop_list.things_to_save.data_transformed.level = 'period';

RunAnalysis({@FisherTransform}, parameters);

%% 
% From here on, can run everything with a "transform" iterator -- "not
% transformed" or "Fisher transformed". (Because I want to see how the
% analyses look with & without transformation.)

%% Average rolled correlations

% Always clear loop list first. 
if isfield(parameters, 'loop_list')
parameters = rmfield(parameters,'loop_list');
end

% Iterators
parameters.loop_list.iterators = {
               'transformation', {'loop_variables.transformations'}, 'transformation_iterator';
               'mouse', {'loop_variables.mice_all(:).name'}, 'mouse_iterator'; 
               'period', {'loop_variables.periods'}, 'period_iterator';            
               };

parameters.loop_variables.periods = periods_bothConditions; 
parameters.loop_variables.mice_all = parameters.mice_all;
parameters.loop_variables.transformations = transformations;

% Dimension to average across
parameters.averageDim = 3; 

parameters.loop_variables.mice_all = parameters.mice_all;
% Input 
parameters.loop_list.things_to_load.data.dir = {[parameters.dir_exper 'fluorescence analysis\correlations\'], 'transformation', '\', 'mouse', '\instances\'};
parameters.loop_list.things_to_load.data.filename= {'correlations_', 'period', '_', 'period_iterator', '.mat'};
parameters.loop_list.things_to_load.data.variable= {'correlations'}; 
parameters.loop_list.things_to_load.data.level = 'period';

% Output
parameters.loop_list.things_to_save.average.dir = {[parameters.dir_exper 'fluorescence analysis\correlations\'], 'transformation', '\', 'mouse', '\average rolled\'};
parameters.loop_list.things_to_save.average.filename= {'correlations_rolled_average.mat'};
parameters.loop_list.things_to_save.average.variable= {'average{', 'period_iterator', ',1}'}; 
parameters.loop_list.things_to_save.average.level = 'mouse';

parameters.loop_list.things_to_save.std_dev.dir = {[parameters.dir_exper 'fluorescence analysis\correlations\'], 'transformation', '\', 'mouse', '\average rolled\'};
parameters.loop_list.things_to_save.std_dev.filename= {'correlations_rolled_std.mat'};
parameters.loop_list.things_to_save.std_dev.variable= {'std_dev{', 'period_iterator', ',1}'}; 
parameters.loop_list.things_to_save.std_dev.level = 'mouse';

RunAnalysis({@AverageData}, parameters);

%% Save reshaped data (2D + roll dim)
% You end up using this more than once, so might as well save it.
% Always clear loop list first. 
if isfield(parameters, 'loop_list')
parameters = rmfield(parameters,'loop_list');
end

% Iterators
parameters.loop_list.iterators = {
                'transformation', {'loop_variables.transformations'}, 'transformation_iterator';
               'mouse', {'loop_variables.mice_all(:).name'}, 'mouse_iterator'; 
               'period', {'loop_variables.periods'}, 'period_iterator';            
               };

parameters.loop_variables.periods = periods_bothConditions; 
parameters.loop_variables.mice_all = parameters.mice_all;

% Variable/data you want to reshape. 
parameters.toReshape = {'parameters.data'}; 

% Dimensions for reshaping, before removing data & before cnocatenation.
% Turning it into 2 dims + roll dim. 
parameters.reshapeDims = {'{size(parameters.data, 1) * size(parameters.data,2), size(parameters.data,3), size(parameters.data, 4) }'};

% Concatenation dimension (post reshaping & removal)
parameters.concatDim = 2; 

% Input 
parameters.loop_list.things_to_load.data.dir = {[parameters.dir_exper 'fluorescence analysis\correlations\'], 'transformation', '\', 'mouse', '\instances\'};
parameters.loop_list.things_to_load.data.filename= {'correlations_', 'period', '_', 'period_iterator', '.mat'};
parameters.loop_list.things_to_load.data.variable= {'correlations'}; 
parameters.loop_list.things_to_load.data.level = 'period';

% Output
parameters.loop_list.things_to_save.data_reshaped.dir = {[parameters.dir_exper 'fluorescence analysis\correlations\'], 'transformation', '\', 'mouse', '\instances reshaped\'};
parameters.loop_list.things_to_save.data_reshaped.filename= {'correlations_', 'period', '_', 'period_iterator', '.mat'};
parameters.loop_list.things_to_save.data_reshaped.variable= {'correlations_reshaped'}; 
parameters.loop_list.things_to_save.data_reshaped.level = 'period';

RunAnalysis({@ReshapeData}, parameters); 

%% Put all correlation matrices into same concatenation (for PCA and other metrics)
% Always clear loop list first. 
if isfield(parameters, 'loop_list')
parameters = rmfield(parameters,'loop_list');
end

% Iterators
parameters.loop_list.iterators = {
               'transformation', {'loop_variables.transformations'}, 'transformation_iterator';
               'mouse', {'loop_variables.mice_all(:).name'}, 'mouse_iterator'; 
               'period', {'loop_variables.periods'}, 'period_iterator';            
               };

parameters.loop_variables.periods = periods_bothConditions; 
parameters.loop_variables.mice_all = parameters.mice_all;

% Dimensions for reshaping, before removing data & before cnocatenation.
% Turning it into 2 dims. 
parameters.reshapeDims = {'{size(parameters.data, 1) * size(parameters.data,2), []}'};

% Removal instructions. Getting all sources in first instance that are NaN,
% remove across all instances. 
%parameters.removalInstructions = {'data(isnan(data(:,1)), :)'};

% Concatenation dimension (post reshaping & removal)
parameters.concatDim = 2; 
parameters.concatenate_across_cells = false; 

% Input 
parameters.loop_list.things_to_load.data.dir = {[parameters.dir_exper 'fluorescence analysis\correlations\'], 'transformation', '\', 'mouse', '\instances\'};
parameters.loop_list.things_to_load.data.filename= {'correlations_', 'period', '_', 'period_iterator', '.mat'};
parameters.loop_list.things_to_load.data.variable= {'correlations'}; 
parameters.loop_list.things_to_load.data.level = 'period';

% Output
parameters.loop_list.things_to_save.concatenated_data.dir = {[parameters.dir_exper 'fluorescence analysis\correlations\'],'transformation', '\', 'mouse', '\all concatenated\'};
parameters.loop_list.things_to_save.concatenated_data.filename= {'correlations_all_concatenated.mat'};
parameters.loop_list.things_to_save.concatenated_data.variable= {'correlations_concatenated'}; 
parameters.loop_list.things_to_save.concatenated_data.level = 'mouse';

% Things to rename/reassign between the two functions (frist column renamed to
% second column. Pairs for each level. Each row is a level.
parameters.loop_list.things_to_rename = { %{'data_removed', 'data'}; 
                                         {'data_reshaped', 'data'}};

% Things to hold example (didn't use here). Each row is a level.
% parameters.loop_list.things_to_hold = {{'data'}}; 

RunAnalysis({@ReshapeData, @ConcatenateData}, parameters); 

%% Visualize difference in mean continued rest & walk for motorized & spontaneous
mouse ='1087';
cmap_corrs = parula(256); 
cmap_diffs = flipud(cbrewer('div', 'RdBu', 256, 'nearest'));
c_range_diffs = [-0.3 0.3];
figure; 

% Spontaneous

% rest
filename = 'correlations_average_rest.mat';
spon_rest = load([parameters.dir_exper 'fluorescence analysis\correlations\' mouse '\average rolled\' filename]);
subplot(2,5,1); imagesc(spon_rest.average);  colorbar; colormap(gca,cmap_corrs); caxis([0 1]);
title('spon rest');

% cont walk
filename = 'correlations_average_walk.mat';
spon_walk = load([parameters.dir_exper 'fluorescence analysis\correlations\' mouse '\average rolled\' filename]);
spon_walk_diff = spon_walk.average - spon_rest.average;
subplot(2,5,2); imagesc(spon_walk_diff);  colorbar; colormap(gca, cmap_diffs); caxis(c_range_diffs);
title('diff spon walk');

% Motorized

% rest
filename = 'correlations_rolled_average.mat';
motor = load([parameters.dir_exper 'fluorescence analysis\correlations\' mouse '\average rolled\' filename]);
subplot(2,5,6); imagesc(motor.average{180});  colorbar; colormap(gca,cmap_corrs); caxis([0 1]);
title('motor rest');

% walk 1600
motor_walk_diff = motor.average{176} - motor.average{180};
subplot(2,5,7); imagesc(motor_walk_diff); colorbar; colormap(gca, cmap_diffs); caxis(c_range_diffs);
title('diff motor walk 1600');

% walk 2000
motor_walk_diff = motor.average{177} - motor.average{180};
subplot(2,5,8); imagesc(motor_walk_diff);  colorbar; colormap(gca, cmap_diffs); caxis(c_range_diffs);
title('diff motor walk 2000');

% walk 2400
motor_walk_diff = motor.average{178} - motor.average{180};
subplot(2,5,9); imagesc(motor_walk_diff);  colorbar; colormap(gca, cmap_diffs); caxis(c_range_diffs);
title('diff motor walk 2400');

% walk 2800
motor_walk_diff = motor.average{179} - motor.average{180};
subplot(2,5,10); imagesc(motor_walk_diff); colorbar; colormap(gca, cmap_diffs); caxis(c_range_diffs);
title('diff motor walk 2800');

motor_rest_diff = motor.average{180} - spon_rest.average;
subplot(2,5,5); imagesc(motor_rest_diff);  colorbar; colormap(gca, cmap_diffs); caxis(c_range_diffs);
title('diff motor rest - spon rest');

sgtitle(['mouse ' mouse]);


%% (just across 1 mouse for now) Run PCA with RunAnalysis -- both motorized & spontaneus
% DOES remove mean before PCA, as defualt of pca.m function.
% Use "reshape" as a trick to get only the indices you want, first. 

% Always clear loop list first. 
if isfield(parameters, 'loop_list')
parameters = rmfield(parameters,'loop_list');
end

% Iterators
parameters.loop_list.iterators = {
    'transformation', {'loop_variables.transformations'}, 'transformation_iterator';
    'mouse', {'loop_variables.mice_all(:).name'}, 'mouse_iterator'};

parameters.loop_variables.mice_all = parameters.mice_all;
parameters.loop_variables.transformations = transformations;

% Reshape parameters.
parameters.indices = find(tril(ones(number_of_sources), -1));
parameters.toReshape = {'parameters.data(parameters.indices, :)'};
parameters.reshapeDims = {'{numel(parameters.indices),size(parameters.data,2)}'};

% PCA parameters.
parameters.observationDim = 2;
parameters.numComponents = 100;

% Input
parameters.loop_list.things_to_load.data.dir = {[parameters.dir_exper 'fluorescence analysis\correlations\'],'transformation', '\', 'mouse', '\all concatenated\'};
parameters.loop_list.things_to_load.data.filename= {'correlations_all_concatenated.mat'};
parameters.loop_list.things_to_load.data.variable= {'correlations_concatenated'}; 
parameters.loop_list.things_to_load.data.level = 'mouse';

% Output
parameters.loop_list.things_to_save.results.dir = {[parameters.dir_exper 'fluorescence analysis\correlations\'],'transformation', '\', 'mouse', '\PCA individual mouse\'};
parameters.loop_list.things_to_save.results.filename= {'PCA_results.mat'};
parameters.loop_list.things_to_save.results.variable= {'PCA_results'}; 
parameters.loop_list.things_to_save.results.level = 'mouse';

parameters.loop_list.things_to_rename = {{'data_reshaped', 'data'}}; 

RunAnalysis({@ReshapeData, @PCA_forRunAnalysis}, parameters);

%%  quickly plot some PCs
mouse = '1087';
components_to_plot = 20; 
number_of_sources = 32;
indices = find(tril(ones(number_of_sources), -1));
for i = 1:numel(transformations)
    transformation = transformations{i};
    
    load(['Y:\Sarah\Analysis\Experiments\Random Motorized Treadmill\fluorescence analysis\correlations\' transformation '\' mouse '\PCA individual mouse\PCA_results.mat']);
   
    figure;
    for componenti = 1:components_to_plot
        holder = NaN(number_of_sources, number_of_sources);
        holder(indices) = PCA_results.components(:,componenti);
        subplot(4,5,componenti); imagesc(holder); caxis([-0.1  0.1])
        xticks([]); yticks([]);

    end
    sgtitle([mouse ', ' transformation]);

    figure; imagesc(PCA_results.scores(:, 1:10)'); colorbar; caxis([-10 10]);
    xticks([]); yticks([]);
    sgtitle([mouse ', ' transformation]);
end 
%% Concatenate ACROSS MICE, motorized & spontaneous (for PCA)

%% Run PCA across mice 

%% Split PCA weights back to orginal mouse/behavior/roll/instance ID

