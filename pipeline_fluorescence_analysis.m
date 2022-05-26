% pipeline_fluorescence_analysis.m

%% Initial Setup  
% Put all needed paramters in a structure called "parameters", which you
% can then easily feed into your functions. 
clear all; 

% Create the experiment name.
parameters.experiment_name='Random Motorized Treadmill';

% Location and filenames of ROI masks (cell array formatting) and
% variable name (string).
parameters.ROI_dir_in_base = {['Y:\Sarah\Analysis\Experiments\' parameters.experiment_name '\quick ROIs\']};
parameters.ROI_input_filename = {'brainOnly_masks_m', 'mouse number', '.mat'}; 
parameters.ROI_input_variable = 'masks';

% Location and filenames of input data matrices to extract from (cell
% array) and variable name (string).
parameters.data_dir_in_base = {['Y:\Sarah\Analysis\Experiments\' parameters.experiment_name '\fully preprocessed stacks\'], 'mouse number', '\', 'day', '\'};
parameters.input_data_name = {'data', 'stack number', '.mat'}; 
parameters.data_input_variable = 'data';

% Output directory name bases
parameters.dir_base='Y:\Sarah\Analysis\Experiments\';
parameters.dir_exper=[parameters.dir_base parameters.experiment_name '\quick ROI analysis\']; 

% Load list of behavior conditions, pass it into parameters structure
load([parameters.dir_base parameters.experiment_name '\Behavior_Conditions.mat']);
parameters.Conditions = Conditions; 

% Load mice_all, pass into parameters structure
load([parameters.dir_base parameters.experiment_name '\mice_all.mat']);
parameters.mice_all = mice_all;

% ****Change here if there are specific mice, days, and/or stacks you want to work with**** 
parameters.mice_all = parameters.mice_all(2:3);
%parameters.mice_all(1).days = parameters.mice_all(1).days(1, 5, 6); 

% Other parameters
parameters.digitNumber = 2;
parameters.pixels = [256 256];


%% Run fluorescence extraction. 
extract_fluorescence_timeseries(parameters);
