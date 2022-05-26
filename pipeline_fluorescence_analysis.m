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
%parameters.mice_all = parameters.mice_all([4:6]);
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
periods_motorized = periods;

% Load names of spontaneous periods
load([parameters.dir_exper 'periods_nametable_spontaneous.mat']);
periods_spontaneous = periods;
clear periods; 

% Create a shared motorized & spontaneous list.
periods_bothConditions = [periods_motorized; periods_spontaneous]; 

% Make list of transformation types for iterating later.
transformations = {'not transformed'; 'Fisher transformed'};

parameters.loop_variables.data_type = {'correlations', 'PCA scores individual mouse'};
parameters.loop_variables.mice_all = parameters.mice_all;
parameters.loop_variables.transformations = transformations;
parameters.loop_variables.conditions = conditions;
parameters.loop_variables.conditions_stack_locations = conditions_stack_locations;

%% Run fluorescence extraction. 
% Always clear loop list first. 
if isfield(parameters, 'loop_list')
parameters = rmfield(parameters,'loop_list');
end

% Iterators
parameters.loop_list.iterators = {'mouse', {'loop_variables.mice_all(:).name'}, 'mouse_iterator'; 
               'day', {'loop_variables.mice_all(', 'mouse_iterator', ').days(:).name'}, 'day_iterator';
               'stack', {'[loop_variables.mice_all(',  'mouse_iterator', ').days(', 'day_iterator', ').stacks; loop_variables.mice_all(',  'mouse_iterator', ').days(', 'day_iterator', ').spontaneous]'}, 'stack_iterator'};

% Dimension different sources are in
parameters.sourcesDim = 3; 

% If the mean timeseries should be weighted by the weights of pixels in the sources (default is uniform mask)
parameters.weightedMean = true; 

% Input values
% Source masks
parameters.loop_list.things_to_load.sources.dir = {[parameters.dir_exper 'spatial segmentation\500 SVD components\manual assignments\'], 'mouse', '\'};
parameters.loop_list.things_to_load.sources.filename= {'sources_reordered_masked.mat'};
parameters.loop_list.things_to_load.sources.variable= {'sources_masked'};

parameters.loop_list.things_to_load.sources.level = 'mouse';
% Preprocessed fluorescence data videos
parameters.loop_list.things_to_load.data.dir = {[parameters.dir_exper 'preprocessing\fully preprocessed stacks\'], 'mouse', '\', 'day', '\'};
parameters.loop_list.things_to_load.data.filename= {'data', 'stack', '.mat'};
parameters.loop_list.things_to_load.data.variable= {'data'}; 
parameters.loop_list.things_to_load.data.level = 'stack';

% Output values. 
parameters.loop_list.things_to_save.timeseries.dir = {[parameters.dir_exper 'fluorescence analysis\timeseries\'], 'mouse', '\', 'day', '\'};
parameters.loop_list.things_to_save.timeseries.filename= {'timeseries', 'stack', '.mat'};
parameters.loop_list.things_to_save.timeseries.variable= {'timeseries'}; 
parameters.loop_list.things_to_save.timeseries.level = 'stack';

% Run 
RunAnalysis({@ExtractFluorescenceTimeseries}, parameters);

%% Motorized: Segment fluorescence by behavior period
% Always clear loop list first. 
if isfield(parameters, 'loop_list')
parameters = rmfield(parameters,'loop_list');
end

% Iterators
parameters.loop_list.iterators = {'mouse', {'loop_variables.mice_all(:).name'}, 'mouse_iterator'; 
               'day', {'loop_variables.mice_all(', 'mouse_iterator', ').days(:).name'}, 'day_iterator';
                   'stack', {'loop_variables.mice_all(',  'mouse_iterator', ').days(', 'day_iterator', ').stacks'}, 'stack_iterator'};
parameters.loop_variables.periods_nametable = periods_motorized; 

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

parameters.loop_variables.periods_spontaneous = periods_spontaneous.condition; 

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
% Is so you can use a single loop for calculations. 
parameters.loop_list.iterators = {'mouse', {'loop_variables.mice_all(:).name'}, 'mouse_iterator'; 
               'condition', 'loop_variables.conditions', 'condition_iterator';
                };

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

parameters.loop_variables.periods = periods_bothConditions.condition; 
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

parameters.loop_variables.periods = periods_bothConditions.condition; 

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

parameters.loop_variables.periods = periods_bothConditions.condition; 

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
parameters.loop_list.things_to_save.correlation.filename= {'correlations.mat'};
parameters.loop_list.things_to_save.correlation.variable= {'correlations{', 'period_iterator', '}'}; 
parameters.loop_list.things_to_save.correlation.level = 'mouse';

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

parameters.loop_variables.periods = periods_bothConditions.condition; 

% Input
parameters.loop_list.things_to_load.data.dir = {[parameters.dir_exper 'fluorescence analysis\correlations\not transformed\'], 'mouse', '\instances\'};
parameters.loop_list.things_to_load.data.filename= {'correlations.mat'};
parameters.loop_list.things_to_load.data.variable= {'correlations{', 'period_iterator', '}'}; 
parameters.loop_list.things_to_load.data.level = 'mouse';

% Output 
parameters.loop_list.things_to_save.data_transformed.dir = {[parameters.dir_exper 'fluorescence analysis\correlations\Fisher transformed\'], 'mouse', '\instances\'};
parameters.loop_list.things_to_save.data_transformed.filename= {'correlations.mat'};
parameters.loop_list.things_to_save.data_transformed.variable= {'correlations{', 'period_iterator', '}'}; 
parameters.loop_list.things_to_save.data_transformed.level = 'mouse';

RunAnalysis({@FisherTransform}, parameters);

%% 
% From here on, can run everything with a "transform" iterator -- "not
% transformed" or "Fisher transformed". (Because I want to see how the
% analyses look with & without transformation.)

%% Save reshaped data (2D + roll dim)
% You end up using this more than once, so might as well save it.
% Always clear loop list first. 
% Also permute so instances are in the last dimension. 
% Keep only lower triangle of matrix.

if isfield(parameters, 'loop_list')
parameters = rmfield(parameters,'loop_list');
end

% Iterators
parameters.loop_list.iterators = {
                'transformation', {'loop_variables.transformations'}, 'transformation_iterator';
               'mouse', {'loop_variables.mice_all(:).name'}, 'mouse_iterator'; 
               'period', {'loop_variables.periods'}, 'period_iterator';            
               };

parameters.loop_variables.periods = periods_bothConditions.condition; 

% Lower triangle only.
parameters.indices = find(tril(ones(number_of_sources), -1));

% Variable/data you want to reshape. 
parameters.toReshape = {'parameters.data'}; 

% Dimensions for reshaping, before removing data & before cnocatenation.
% Turning it into 2 dims + roll dim. 
parameters.reshapeDims = {'{size(parameters.data, 1) * size(parameters.data,2), size(parameters.data,3), size(parameters.data, 4) }'};

% Permute data instructions/dimensions. Puts instances in last dimension. 
parameters.DimOrder = [1, 3, 2]; 

% Evaluation instructions.
parameters.evaluation_instructions = {{}, {},{'if ~isempty(parameters.data);'...
          'data_evaluated = parameters.data(parameters.indices, :,:);' ...
          'else;'...
          'data_evaluated = [];'...
          'end'
           }};

% Input 
parameters.loop_list.things_to_load.data.dir = {[parameters.dir_exper 'fluorescence analysis\correlations\'], 'transformation', '\', 'mouse', '\instances\'};
parameters.loop_list.things_to_load.data.filename= {'correlations.mat'};
parameters.loop_list.things_to_load.data.variable= {'correlations{', 'period_iterator', '}'}; 
parameters.loop_list.things_to_load.data.level = 'mouse';

% Output
parameters.loop_list.things_to_save.data_evaluated.dir = {[parameters.dir_exper 'fluorescence analysis\correlations\'], 'transformation', '\', 'mouse', '\instances reshaped\'};
parameters.loop_list.things_to_save.data_evaluated.filename= {'values.mat'};
parameters.loop_list.things_to_save.data_evaluated.variable= {'values{', 'period_iterator', ', 1}'}; 
parameters.loop_list.things_to_save.data_evaluated.level = 'mouse';

parameters.loop_list.things_to_rename = {{'data_reshaped', 'data'};
                                         {'data_permuted', 'data'}}; 

RunAnalysis({@ReshapeData, @PermuteData, @EvaluateOnData}, parameters); 

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

parameters.loop_variables.periods = periods_bothConditions.condition; 

% Dimensions for reshaping, before removing data & before cnocatenation.
% Turning it into 2 dims. 
parameters.toReshape = {'parameters.data'};
parameters.reshapeDims = {'{size(parameters.data, 1), []}'};

% Concatenation dimension (post reshaping & removal)
parameters.concatDim = 2; 
parameters.concatenate_across_cells = false; 

% Input 
parameters.loop_list.things_to_load.data.dir = {[parameters.dir_exper 'fluorescence analysis\correlations\'], 'transformation', '\', 'mouse', '\instances reshaped\'};
parameters.loop_list.things_to_load.data.filename= {'values.mat'};
parameters.loop_list.things_to_load.data.variable= {'values{', 'period_iterator', '}'}; 
parameters.loop_list.things_to_load.data.level = 'mouse';

% Output
parameters.loop_list.things_to_save.concatenated_data.dir = {[parameters.dir_exper 'fluorescence analysis\correlations\'],'transformation', '\', 'mouse', '\all concatenated\'};
parameters.loop_list.things_to_save.concatenated_data.filename= {'correlations_all_concatenated.mat'};
parameters.loop_list.things_to_save.concatenated_data.variable= {'correlations_concatenated'}; 
parameters.loop_list.things_to_save.concatenated_data.level = 'mouse';

parameters.loop_list.things_to_save.concatenated_origin.dir = {[parameters.dir_exper 'fluorescence analysis\correlations\'],'transformation', '\', 'mouse', '\all concatenated\'};
parameters.loop_list.things_to_save.concatenated_origin.filename= {'correlations_all_concatenated_origin.mat'};
parameters.loop_list.things_to_save.concatenated_origin.variable= {'concatenation_origin'}; 
parameters.loop_list.things_to_save.concatenated_origin.level = 'mouse';


% Things to rename/reassign between the two functions (frist column renamed to
% second column. Pairs for each level. Each row is a level.
parameters.loop_list.things_to_rename = { %{'data_removed', 'data'}; 
                                         {'data_reshaped', 'data'}};

% Things to hold example (didn't use here). Each row is a level.
% parameters.loop_list.things_to_hold = {{'data'}}; 

RunAnalysis({@ReshapeData, @ConcatenateData}, parameters);  

%% (just across 1 mouse) Run PCA with RunAnalysis -- both motorized & spontaneous
% Would be good to have PCs from individual mice to refer to-- to help
% figure out if ICs seem to be labeled to similar nodes across mice.
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

% PCA parameters.
parameters.observationDim = 2;
parameters.numComponents = (number_of_sources^2 - number_of_sources)/2; % Calculate all possible PCs
parameters.observation_weighted_flag = false;
parameters.pairwise_flag = false; 
parameters.variable_weighted_flag = false;
parameters.algorithem = 'eig';

% Input
parameters.loop_list.things_to_load.data.dir = {[parameters.dir_exper 'fluorescence analysis\correlations\'],'transformation', '\', 'mouse', '\all concatenated\'};
parameters.loop_list.things_to_load.data.filename= {'correlations_all_concatenated.mat'};
parameters.loop_list.things_to_load.data.variable= {'correlations_concatenated'}; 
parameters.loop_list.things_to_load.data.level = 'mouse';

% Output
parameters.loop_list.things_to_save.results.dir = {[parameters.dir_exper 'fluorescence analysis\PCA individual mouse\'],'transformation', '\', 'mouse' '\'};
parameters.loop_list.things_to_save.results.filename= {'PCA_results.mat'};
parameters.loop_list.things_to_save.results.variable= {'PCA_results'}; 
parameters.loop_list.things_to_save.results.level = 'mouse';

RunAnalysis({@PCA_forRunAnalysis}, parameters);

%%  Individual mice -- Plot some PCs
% Always clear loop list first. 
if isfield(parameters, 'loop_list')
parameters = rmfield(parameters,'loop_list');
end

% Iterators
parameters.loop_list.iterators = {
    'transformation', {'loop_variables.transformations'}, 'transformation_iterator';
    'mouse', {'loop_variables.mice_all(:).name'}, 'mouse_iterator'};

parameters.components_to_plot = 1:20; 
parameters.number_of_sources = 32;
parameters.color_range = [-0.1 0.1];

% Input 
parameters.loop_list.things_to_load.components.dir = {[parameters.dir_exper 'fluorescence analysis\PCA individual mouse\'],'transformation', '\', 'mouse' '\'};
parameters.loop_list.things_to_load.components.filename= {'PCA_results.mat'};
parameters.loop_list.things_to_load.components.variable= {'PCA_results.components'}; 
parameters.loop_list.things_to_load.components.level = 'mouse';

% Output
parameters.loop_list.things_to_save.fig.dir = {[parameters.dir_exper 'fluorescence analysis\PCA individual mouse\'],'transformation', '\', 'mouse' '\'};
parameters.loop_list.things_to_save.fig.filename= {['first_' num2str(parameters.components_to_plot(end)) '_PCs.fig']};
parameters.loop_list.things_to_save.fig.variable= {'fig'}; 
parameters.loop_list.things_to_save.fig.level = 'mouse';

RunAnalysis({@PlotPCs}, parameters);

close all;
%% Individual mice-- Divide PC weights into behavior periods. (just within one mouse for now)
% % Always clear loop list first. 
% if isfield(parameters, 'loop_list')
% parameters = rmfield(parameters,'loop_list');
% end
% 
% % Iterators
% parameters.loop_list.iterators = {
%     'transformation', {'loop_variables.transformations'}, 'transformation_iterator';
%     'mouse', {'loop_variables.mice_all(:).name'}, 'mouse_iterator';
%      };
% 
% parameters.loop_variables.periods = periods_bothConditions.condition; 
% 
% parameters.fromConcatenateData = true;
% parameters.divideDim = 1; 
% 
% % Input 
% parameters.loop_list.things_to_load.division_points.dir = {[parameters.dir_exper 'fluorescence analysis\correlations\'],'transformation', '\', 'mouse', '\all concatenated\'};
% parameters.loop_list.things_to_load.division_points.filename= {'correlations_all_concatenated_origin.mat'};
% parameters.loop_list.things_to_load.division_points.variable= {'concatenation_origin'}; 
% parameters.loop_list.things_to_load.division_points.level = 'mouse';
% 
% parameters.loop_list.things_to_load.data.dir = {[parameters.dir_exper 'fluorescence analysis\PCA individual mouse\'],'transformation', '\', 'mouse', '\'};
% parameters.loop_list.things_to_load.data.filename= {'PCA_results.mat'};
% parameters.loop_list.things_to_load.data.variable= {'PCA_results.scores'}; 
% parameters.loop_list.things_to_load.data.level = 'mouse';
% 
% % Output
% parameters.loop_list.things_to_save.data_divided.dir = {[parameters.dir_exper 'fluorescence analysis\PCA individual mouse\'],'transformation', '\', 'mouse', '\'};
% parameters.loop_list.things_to_save.data_divided.filename= {'PCA_scores_dividedbybehavior.mat'};
% parameters.loop_list.things_to_save.data_divided.variable= {'scores'}; 
% parameters.loop_list.things_to_save.data_divided.level = 'mouse';
% 
% RunAnalysis({@DivideData}, parameters);

%% Individual mice-- Add empty behavior spaces back into the divided PCA scores. 

% if isfield(parameters, 'loop_list')
% parameters = rmfield(parameters,'loop_list');
% end
% 
% % Iterators
% parameters.loop_list.iterators = {
%     'transformation', {'loop_variables.transformations'}, 'transformation_iterator';
%     'mouse', {'loop_variables.mice_all(:).name'}, 'mouse_iterator';
%      };
% 
% parameters.evaluation_instructions = {{'indices = find(cellfun(@isempty, parameters.timeseries));' ...
%       'data_evaluated = parameters.data;' ... 
%       'for i = 1:numel(indices);'...
%       'data_evaluated = [data_evaluated(1:indices(i)-1); {[]}; data_evaluated(indices(i):end)];' ... 
%       'end'}};
% 
% % Input 
% parameters.loop_list.things_to_load.timeseries.dir = {[parameters.dir_exper 'fluorescence analysis\rolled timeseries\'], 'mouse', '\'};
% parameters.loop_list.things_to_load.timeseries.filename= {'timeseries_rolled.mat'};
% parameters.loop_list.things_to_load.timeseries.variable= {'timeseries_rolled'}; 
% parameters.loop_list.things_to_load.timeseries.level = 'mouse';
% 
% parameters.loop_list.things_to_load.data.dir = {[parameters.dir_exper 'fluorescence analysis\PCA individual mouse\'],'transformation', '\', 'mouse', '\'};
% parameters.loop_list.things_to_load.data.filename= {'PCA_scores_dividedbybehavior.mat'};
% parameters.loop_list.things_to_load.data.variable= {'scores'}; 
% parameters.loop_list.things_to_load.data.level = 'mouse';
% 
% % Output 
% parameters.loop_list.things_to_save.data_evaluated.dir = {[parameters.dir_exper 'fluorescence analysis\PCA individual mouse\'],'transformation', '\', 'mouse', '\'};
% parameters.loop_list.things_to_save.data_evaluated.filename= {'PCA_scores_dividedbybehavior_withempties.mat'};
% parameters.loop_list.things_to_save.data_evaluated.variable= {'scores'}; 
% parameters.loop_list.things_to_save.data_evaluated.level = 'mouse';
% 
% RunAnalysis({@EvaluateOnData}, parameters);

%% Individual mice-- Divide PC weights into roll windows by behavior periods.
% Also permute to match correlation dimension structure.

% % Always clear loop list first. 
% if isfield(parameters, 'loop_list')
% parameters = rmfield(parameters,'loop_list');
% end
% 
% % Iterators
% parameters.loop_list.iterators = {
%                'transformation', {'loop_variables.transformations'}, 'transformation_iterator';
%                'mouse', {'loop_variables.mice_all(:).name'}, 'mouse_iterator'; 
%                'period', {'loop_variables.periods'}, 'period_iterator';            
%                };
% 
% parameters.loop_variables.periods = periods_bothConditions.condition; 
% 
% parameters.evaluation_instructions = {{'a = size(parameters.data,1);' ...
%       'parameters.instances = a ./ parameters.roll_number;'...
%       'data_evaluated = parameters.data;'
%        }};
% 
% parameters.toReshape = {'parameters.data'};
% parameters.reshapeDims = {'{parameters.roll_number, parameters.instances, []}'};
% 
% % Permute data instructions/dimensions. To scores, rolls, instances. 
% parameters.DimOrder = [3, 1, 2]; 
% 
% % Input 
% parameters.loop_list.things_to_load.data.dir = {[parameters.dir_exper 'fluorescence analysis\PCA individual mouse\'],'transformation', '\', 'mouse', '\'};
% parameters.loop_list.things_to_load.data.filename= {'PCA_scores_dividedbybehavior_withempties.mat'};
% parameters.loop_list.things_to_load.data.variable= {'scores{', 'period_iterator', '}'}; 
% parameters.loop_list.things_to_load.data.level = 'mouse';
% 
% parameters.loop_list.things_to_load.roll_number.dir = {[parameters.dir_exper 'fluorescence analysis\rolled timeseries\'], 'mouse', '\'};
% parameters.loop_list.things_to_load.roll_number.filename= {'roll_number.mat'};
% parameters.loop_list.things_to_load.roll_number.variable= {'roll_number{', 'period_iterator', ', 1}'}; 
% parameters.loop_list.things_to_load.roll_number.level = 'mouse';
% 
% % Output
% parameters.loop_list.things_to_save.data_permuted.dir = {[parameters.dir_exper 'fluorescence analysis\PCA individual mouse\'],'transformation', '\', 'mouse', '\instances reshaped\'};
% parameters.loop_list.things_to_save.data_permuted.filename= {'values.mat'};
% parameters.loop_list.things_to_save.data_permuted.variable= {'values{', 'period_iterator', ', 1}'}; 
% parameters.loop_list.things_to_save.data_permuted.level = 'mouse';
% 
% parameters.loop_list.things_to_rename = {{'data_evaluated', 'data'}
%                                          {'data_reshaped', 'data'}}; 
% 
% RunAnalysis({@EvaluateOnData, @ReshapeData, @PermuteData}, parameters);

%% Across mice -- Count amount of data from each mouse for PCA observation weights.
% Don't need to do for both transformations, don't need to even load in the
% data.
% Always clear loop list first. 
if isfield(parameters, 'loop_list')
parameters = rmfield(parameters,'loop_list');
end

% Iterators
parameters.loop_list.iterators = {
               'mouse', {'loop_variables.mice_all(:).name'}, 'mouse_iterator';           
               };

parameters.concatDim = 1; 

parameters.evaluation_instructions = {
                                      ['data_evaluated = size(parameters.data, "correlations_concatenated",2);'],
                                      [],
                                      ['data_evaluated = mean(parameters.concatenated_data) ./ parameters.concatenated_data; ']
                                       };

% Input
parameters.loop_list.things_to_load.data.dir = {[parameters.dir_exper 'fluorescence analysis\correlations\not transformed\'], 'mouse', '\all concatenated\'};
parameters.loop_list.things_to_load.data.filename= {'correlations_all_concatenated.mat'};
parameters.loop_list.things_to_load.data.variable= {}; 
parameters.loop_list.things_to_load.data.level = 'mouse';
parameters.loop_list.things_to_load.data.load_function = @matfile;

% Output
parameters.loop_list.things_to_save.data_evaluated.dir = {[parameters.dir_exper 'fluorescence analysis\PCA across mice\input weights\']};
parameters.loop_list.things_to_save.data_evaluated.filename= {'number_correlations_bymouse.mat'};
parameters.loop_list.things_to_save.data_evaluated.variable= {'numbers'}; 
parameters.loop_list.things_to_save.data_evaluated.level = 'end';

parameters.loop_list.things_to_rename = {{'data_evaluated', 'data'};
                                          {}};

RunAnalysis({@EvaluateOnData, @ConcatenateData, @EvaluateOnData}, parameters); 

%% Across mice -- replicate PCA weights, concatenated across mice.
% Always clear loop list first. 
if isfield(parameters, 'loop_list')
parameters = rmfield(parameters,'loop_list');
end

% Iterators
parameters.loop_list.iterators = {
               'transformation', {'loop_variables.transformations'}, 'transformation_iterator';
               'mouse', {'loop_variables.mice_all(:).name'}, 'mouse_iterator';           
               };

parameters.concatDim = 1; 

parameters.toReplicate = {'parameters.data'};
parameters.replicateDims = {'[size(parameters.reps, "correlations_concatenated",2), 1]'};

% Input 
parameters.loop_list.things_to_load.data.dir = {[parameters.dir_exper 'fluorescence analysis\PCA across mice\input weights\']};
parameters.loop_list.things_to_load.data.filename= {'number_correlations_bymouse.mat'};
parameters.loop_list.things_to_load.data.variable= {'numbers(', 'mouse_iterator', ')'}; 
parameters.loop_list.things_to_load.data.level = 'transformation';

parameters.loop_list.things_to_load.reps.dir = {[parameters.dir_exper 'fluorescence analysis\correlations\not transformed\'], 'mouse', '\all concatenated\'};
parameters.loop_list.things_to_load.reps.filename= {'correlations_all_concatenated.mat'};
parameters.loop_list.things_to_load.reps.variable= {}; 
parameters.loop_list.things_to_load.reps.level = 'mouse';
parameters.loop_list.things_to_load.reps.load_function = @matfile;

% Output 
parameters.loop_list.things_to_save.concatenated_data.dir = {[parameters.dir_exper 'fluorescence analysis\PCA across mice\input weights\']};
parameters.loop_list.things_to_save.concatenated_data.filename= {'weights.mat'};
parameters.loop_list.things_to_save.concatenated_data.variable= {'weights'}; 
parameters.loop_list.things_to_save.concatenated_data.level = 'transformation';

parameters.loop_list.things_to_rename = {{'data_replicated', 'data'}};

RunAnalysis({@ReplicateData, @ConcatenateData}, parameters); 

%% Aross mice -- Concatenate ACROSS MICE, motorized & spontaneous (for PCA)
% Always clear loop list first. 
if isfield(parameters, 'loop_list')
parameters = rmfield(parameters,'loop_list');
end

% Iterators
parameters.loop_list.iterators = {
               'transformation', {'loop_variables.transformations'}, 'transformation_iterator';
               'mouse', {'loop_variables.mice_all(:).name'}, 'mouse_iterator';           
               };
% Concatenation dimension (post reshaping & removal)
parameters.concatDim = 2; 
parameters.concatenate_across_cells = false; 

% Input
parameters.loop_list.things_to_load.data.dir = {[parameters.dir_exper 'fluorescence analysis\correlations\'],'transformation', '\', 'mouse', '\all concatenated\'};
parameters.loop_list.things_to_load.data.filename= {'correlations_all_concatenated.mat'};
parameters.loop_list.things_to_load.data.variable= {'correlations_concatenated'}; 
parameters.loop_list.things_to_load.data.level = 'mouse';

% Output.
parameters.loop_list.things_to_save.concatenated_data.dir = {[parameters.dir_exper 'fluorescence analysis\correlations\'],'transformation', '\concatenated across mice\'};
parameters.loop_list.things_to_save.concatenated_data.filename= {'correlations_all_concatenated.mat'};
parameters.loop_list.things_to_save.concatenated_data.variable= {'correlations_concatenated_across_mice'}; 
parameters.loop_list.things_to_save.concatenated_data.level = 'transformation';

parameters.loop_list.things_to_save.concatenated_origin.dir = {[parameters.dir_exper 'fluorescence analysis\correlations\'],'transformation', '\concatenated across mice\'};
parameters.loop_list.things_to_save.concatenated_origin.filename= {'correlations_all_concatenated_origin.mat'};
parameters.loop_list.things_to_save.concatenated_origin.variable= {'concatenation_origin'}; 
parameters.loop_list.things_to_save.concatenated_origin.level = 'transformation';

RunAnalysis({@ConcatenateData}, parameters);  

%% Run PCA across mice 
% Include weights so each mouse is contributing roughly equally to overall
% amount of data. 

% Always clear loop list first. 
if isfield(parameters, 'loop_list')
parameters = rmfield(parameters,'loop_list');
end

% Iterators
parameters.loop_list.iterators = {'transformation', {'loop_variables.transformations'}, 'transformation_iterator'};

% PCA parameters.
parameters.observationDim = 2;
parameters.numComponents = (number_of_sources^2 - number_of_sources)/2; % Calculate all PCs. 
parameters.observation_weighted_flag = true; % Use weights by mouse
parameters.pairwise_flag = true;  % Omit NaNs when calculating covariance between two correlation values
parameters.variable_weighted_flag = false; % Weight certain correlation values based on how many are missing/NaNs
parameters.algorithem = 'eig';

% Input
parameters.loop_list.things_to_load.data.dir = {[parameters.dir_exper 'fluorescence analysis\correlations\'],'transformation', '\concatenated across mice\'};
parameters.loop_list.things_to_load.data.filename= {'correlations_all_concatenated.mat'};
parameters.loop_list.things_to_load.data.variable= {'correlations_concatenated_across_mice'}; 
parameters.loop_list.things_to_load.data.level = 'transformation';

parameters.loop_list.things_to_load.observation_weights.dir = {[parameters.dir_exper 'fluorescence analysis\PCA across mice\input weights\']};
parameters.loop_list.things_to_load.observation_weights.filename= {'weights.mat'};
parameters.loop_list.things_to_load.observation_weights.variable= {'weights'}; 
parameters.loop_list.things_to_load.observation_weights.level = 'transformation';

% Output
parameters.loop_list.things_to_save.results.dir = {[parameters.dir_exper 'fluorescence analysis\PCA across mice\'],'transformation', '\'};
parameters.loop_list.things_to_save.results.filename = {'PCA_results.mat'};
parameters.loop_list.things_to_save.results.variable = {'PCA_results'}; 
parameters.loop_list.things_to_save.results.level = 'transformation';

RunAnalysis({@PCA_forRunAnalysis}, parameters);

%% Across mice -- Plot some PCs
% Always clear loop list first. 
if isfield(parameters, 'loop_list')
parameters = rmfield(parameters,'loop_list');
end

% Iterators
parameters.loop_list.iterators = {
    'transformation', {'loop_variables.transformations'}, 'transformation_iterator'};

parameters.components_to_plot = 1:20; 
parameters.number_of_sources = 32;
parameters.color_range = [-0.1 0.1];

% Input 
parameters.loop_list.things_to_load.components.dir = {[parameters.dir_exper 'fluorescence analysis\PCA across mice\'],'transformation', '\' };
parameters.loop_list.things_to_load.components.filename= {'PCA_results.mat'};
parameters.loop_list.things_to_load.components.variable= {'PCA_results.components'}; 
parameters.loop_list.things_to_load.components.level = 'transformation';

% Output
parameters.loop_list.things_to_save.fig.dir = {[parameters.dir_exper 'fluorescence analysis\PCA across mice\'],'transformation', '\'};
parameters.loop_list.things_to_save.fig.filename= {['first_' num2str(parameters.components_to_plot(end)) '_PCs.fig']};
parameters.loop_list.things_to_save.fig.variable= {'fig'}; 
parameters.loop_list.things_to_save.fig.level = 'transformation';

RunAnalysis({@PlotPCs}, parameters);

close all;

%% Split PCA weights back to orginal mouse/behavior/roll/instance

%% Across mice-- Divide PC scores/loadings back to individual mice 
% Always clear loop list first. 
if isfield(parameters, 'loop_list')
parameters = rmfield(parameters,'loop_list');
end

% Iterators
parameters.loop_list.iterators = {
    'transformation', {'loop_variables.transformations'}, 'transformation_iterator';
     };

parameters.loop_variables.periods = periods_bothConditions.condition; 

parameters.fromConcatenateData = true;
parameters.divideDim = 1; 

% Input 
parameters.loop_list.things_to_load.division_points.dir = {[parameters.dir_exper 'fluorescence analysis\correlations\'],'transformation', '\concatenated across mice\'};
parameters.loop_list.things_to_load.division_points.filename= {'correlations_all_concatenated_origin.mat'};
parameters.loop_list.things_to_load.division_points.variable= {'concatenation_origin'}; 
parameters.loop_list.things_to_load.division_points.level = 'transformation';

parameters.loop_list.things_to_load.data.dir = {[parameters.dir_exper 'fluorescence analysis\PCA across mice\'],'transformation', '\'};
parameters.loop_list.things_to_load.data.filename= {'PCA_results.mat'};
parameters.loop_list.things_to_load.data.variable= {'PCA_results.scores'}; 
parameters.loop_list.things_to_load.data.level = 'transformation';

% Output
parameters.loop_list.things_to_save.data_divided.dir = {[parameters.dir_exper 'fluorescence analysis\PCA across mice\'],'transformation', '\'};
parameters.loop_list.things_to_save.data_divided.filename= {'PCA_scores_dividedbymouse.mat'};
parameters.loop_list.things_to_save.data_divided.variable= {'scores'}; 
parameters.loop_list.things_to_save.data_divided.level = 'transformation';

RunAnalysis({@DivideData}, parameters);

%% Across mice -- Take overall average PC weights/scores/loadings within each mouse.
% Always clear loop list first. 
if isfield(parameters, 'loop_list')
parameters = rmfield(parameters,'loop_list');
end

% Iterators
parameters.loop_list.iterators = {
    'transformation', {'loop_variables.transformations'}, 'transformation_iterator';
    'mouse', {'loop_variables.mice_all(:).name'}, 'mouse_iterator';
     };

parameters.averageDim = 1;

% Input 
parameters.loop_list.things_to_load.data.dir = {[parameters.dir_exper 'fluorescence analysis\PCA across mice\'],'transformation', '\'};
parameters.loop_list.things_to_load.data.filename= {'PCA_scores_dividedbymouse.mat'};
parameters.loop_list.things_to_load.data.variable= {'scores{', 'mouse_iterator', '}'}; 
parameters.loop_list.things_to_load.data.level = 'transformation';

% Output
parameters.loop_list.things_to_save.average.dir = {[parameters.dir_exper 'fluorescence analysis\PCA across mice\'],'transformation', '\'};
parameters.loop_list.things_to_save.average.filename= {'PCA_scores_average_bymouse.mat'};
parameters.loop_list.things_to_save.average.variable= {'average{', 'mouse_iterator', '}'}; 
parameters.loop_list.things_to_save.average.level = 'transformation';

parameters.loop_list.things_to_save.std_dev.dir = {[parameters.dir_exper 'fluorescence analysis\PCA across mice\'],'transformation', '\'};
parameters.loop_list.things_to_save.std_dev.filename= {'PCA_scores_std_dev_bymouse.mat'};
parameters.loop_list.things_to_save.std_dev.variable= {'std_dev{', 'mouse_iterator', '}'}; 
parameters.loop_list.things_to_save.std_dev.level = 'transformation';

RunAnalysis({@AverageData}, parameters);

%% Concatenate average scores of mice for plotting
% Always clear loop list first. 
if isfield(parameters, 'loop_list')
parameters = rmfield(parameters,'loop_list');
end

% Iterators
parameters.loop_list.iterators = {
    'transformation', {'loop_variables.transformations'}, 'transformation_iterator';
    'average_type', {'loop_variables.average_type'}, 'average_type_iterator';
    'mouse', {'loop_variables.mice_all(:).name'}, 'mouse_iterator';
     };

parameters.loop_variables.average_type = {'average', 'std_dev'};

parameters.concatDim = 1;

% Input 
parameters.loop_list.things_to_load.data.dir = {[parameters.dir_exper 'fluorescence analysis\PCA across mice\'],'transformation', '\'};
parameters.loop_list.things_to_load.data.filename= {'PCA_scores_', 'average_type', '_bymouse.mat'};
parameters.loop_list.things_to_load.data.variable= {'average_type', '{', 'mouse_iterator', '}'}; 
parameters.loop_list.things_to_load.data.level = 'average_type';

% Output
parameters.loop_list.things_to_save.concatenated_data.dir = {[parameters.dir_exper 'fluorescence analysis\PCA across mice\'],'transformation', '\'};
parameters.loop_list.things_to_save.concatenated_data.filename= {'PCA_scores_', 'average_type', '_bymouse_concatenated.mat'};
parameters.loop_list.things_to_save.concatenated_data.variable= {'average_type', '_concatenated'}; 
parameters.loop_list.things_to_save.concatenated_data.level = 'average_type';

RunAnalysis({@ConcatenateData}, parameters);

%% Plot average scores of mice 


%% Across mice-- Divide PC weights into behavior periods. 
% Always clear loop list first. 
if isfield(parameters, 'loop_list')
parameters = rmfield(parameters,'loop_list');
end

% Iterators
parameters.loop_list.iterators = {
    'transformation', {'loop_variables.transformations'}, 'transformation_iterator';
    'mouse', {'loop_variables.mice_all(:).name'}, 'mouse_iterator';
     };

parameters.loop_variables.periods = periods_bothConditions.condition; 

parameters.fromConcatenateData = true;
parameters.divideDim = 1; 

% Input 
parameters.loop_list.things_to_load.division_points.dir = {[parameters.dir_exper 'fluorescence analysis\correlations\'],'transformation', '\', 'mouse', '\all concatenated\'};
parameters.loop_list.things_to_load.division_points.filename= {'correlations_all_concatenated_origin.mat'};
parameters.loop_list.things_to_load.division_points.variable= {'concatenation_origin'}; 
parameters.loop_list.things_to_load.division_points.level = 'mouse';

parameters.loop_list.things_to_load.data.dir = {[parameters.dir_exper 'fluorescence analysis\PCA across mice\'],'transformation', '\PCA across mice\'};
parameters.loop_list.things_to_load.data.filename= {'PCA_scores_dividedbymouse.mat'};
parameters.loop_list.things_to_load.data.variable= {'scores{', 'mouse_iterator', '}'}; 
parameters.loop_list.things_to_load.data.level = 'transformation';

% Output
parameters.loop_list.things_to_save.data_divided.dir = {[parameters.dir_exper 'fluorescence analysis\PCA across mice\'],'transformation', '\divided scores\',  'mouse', '\'};
parameters.loop_list.things_to_save.data_divided.filename= {'PCA_scores_dividedbybehavior.mat'};
parameters.loop_list.things_to_save.data_divided.variable= {'scores_bybehavior'}; 
parameters.loop_list.things_to_save.data_divided.level = 'mouse';

RunAnalysis({@DivideData}, parameters);

%% Across mice-- Add empty behavior spaces back into the divided PCA scores. 

if isfield(parameters, 'loop_list')
parameters = rmfield(parameters,'loop_list');
end

% Iterators
parameters.loop_list.iterators = {
    'transformation', {'loop_variables.transformations'}, 'transformation_iterator';
    'mouse', {'loop_variables.mice_all(:).name'}, 'mouse_iterator';
     };

parameters.evaluation_instructions = {['indices = find(cellfun(@isempty, parameters.timeseries));' ...
      'data_evaluated = parameters.data;' ... 
      'for i = 1:numel(indices);'...
      'data_evaluated = [data_evaluated(1:indices(i)-1); {[]}; data_evaluated(indices(i):end)];' ... 
      'end']};

% Input 
parameters.loop_list.things_to_load.timeseries.dir = {[parameters.dir_exper 'fluorescence analysis\rolled timeseries\'], 'mouse', '\'};
parameters.loop_list.things_to_load.timeseries.filename= {'timeseries_rolled.mat'};
parameters.loop_list.things_to_load.timeseries.variable= {'timeseries_rolled'}; 
parameters.loop_list.things_to_load.timeseries.level = 'mouse';

parameters.loop_list.things_to_load.data.dir = {[parameters.dir_exper 'fluorescence analysis\PCA across mice\'],'transformation', '\divided scores\', 'mouse', '\'};
parameters.loop_list.things_to_load.data.filename= {'PCA_scores_dividedbybehavior.mat'};
parameters.loop_list.things_to_load.data.variable= {'scores_bybehavior'}; 
parameters.loop_list.things_to_load.data.level = 'mouse';

% Output 
parameters.loop_list.things_to_save.data_evaluated.dir = {[parameters.dir_exper 'fluorescence analysis\PCA across mice\'],'transformation', '\divided scores\', 'mouse', '\'};
parameters.loop_list.things_to_save.data_evaluated.filename= {'PCA_scores_dividedbybehavior_withempties.mat'};
parameters.loop_list.things_to_save.data_evaluated.variable= {'scores'}; 
parameters.loop_list.things_to_save.data_evaluated.level = 'mouse';

RunAnalysis({@EvaluateOnData}, parameters);

%% Across mice-- Divide PC weights into roll windows by behavior periods.
% Also permute to match correlation dimension structure.

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

parameters.loop_variables.periods = periods_bothConditions.condition; 

parameters.evaluation_instructions = {['a = size(parameters.data,1);' ...
      'parameters.instances = a ./ parameters.roll_number;'...
      'data_evaluated = parameters.data;'
       ]};

parameters.toReshape = {'parameters.data'};
parameters.reshapeDims = {'{parameters.roll_number, parameters.instances, []}'};

% Permute data instructions/dimensions. To scores, rolls, instances. 
parameters.DimOrder = [3, 1, 2]; 

% Input 
parameters.loop_list.things_to_load.data.dir = {[parameters.dir_exper 'fluorescence analysis\PCA across mice\'],'transformation', '\divided scores\', 'mouse', '\' };
parameters.loop_list.things_to_load.data.filename= {'PCA_scores_dividedbybehavior_withempties.mat'};
parameters.loop_list.things_to_load.data.variable= {'scores{', 'period_iterator', '}'}; 
parameters.loop_list.things_to_load.data.level = 'mouse';

parameters.loop_list.things_to_load.roll_number.dir = {[parameters.dir_exper 'fluorescence analysis\rolled timeseries\'], 'mouse', '\'};
parameters.loop_list.things_to_load.roll_number.filename= {'roll_number.mat'};
parameters.loop_list.things_to_load.roll_number.variable= {'roll_number{', 'period_iterator', ', 1}'}; 
parameters.loop_list.things_to_load.roll_number.level = 'mouse';

% Output
parameters.loop_list.things_to_save.data_permuted.dir = {[parameters.dir_exper 'fluorescence analysis\PCA across mice\'],'transformation', '\', 'mouse', '\instances reshaped\'};
parameters.loop_list.things_to_save.data_permuted.filename= {'values.mat'};
parameters.loop_list.things_to_save.data_permuted.variable= {'values{', 'period_iterator', ', 1}'}; 
parameters.loop_list.things_to_save.data_permuted.level = 'mouse';

parameters.loop_list.things_to_rename = {{'data_evaluated', 'data'}
                                         {'data_reshaped', 'data'}}; 

RunAnalysis({@EvaluateOnData, @ReshapeData, @PermuteData}, parameters);
