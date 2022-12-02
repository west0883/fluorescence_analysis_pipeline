% pipeline_DFF_means.m
% Sarah West
% 11/29/22


%% Initial Setup  
% Put all needed paramters in a structure called "parameters", which you
% can then easily feed into your functions. 
clear all; 

% Create the experiment name.
parameters.experiment_name = 'Random Motorized Treadmill';

% Input directory name base
parameters.dir_dataset_base = ['Y:\Sarah\Data\' parameters.experiment_name, '\'];

% Output directory name bases
parameters.dir_base='Y:\Sarah\Analysis\Experiments\';
parameters.dir_exper=[parameters.dir_base parameters.experiment_name '\']; 

% Load mice_all_random, pass into parameters structure
if isfile([parameters.dir_exper 'preprocessing\stack means\mice_all_random.mat'])
    load([parameters.dir_exper '\preprocessing\stack means\mice_all_random.mat']);
    parameters.mice_all = mice_all;
end
% ****Change here if there are specific mice, days, and/or stacks you want to work with**** 
parameters.mice_all = parameters.mice_all(2:end);
parameters.mice_all(1).days = parameters.mice_all(1).days(6:end);

% Include stacks from a "spontaneous" field of mice_all?
parameters.use_spontaneous_also = true;

% Other parameters
parameters.digitNumber = 2;
parameters.yDim = 256;
parameters.xDim = 256;
number_of_sources = 32; 
parameters.number_of_sources = number_of_sources;

% Lower triangle only 
parameters.indices = find(tril(ones(number_of_sources), -1));

% Loop variables
parameters.loop_variables.mice_all = parameters.mice_all;
parameters.loop_variables.transformations = {'not transformed'; 'Fisher transformed'};
parameters.loop_variables.conditions = {'motorized'; 'spontaneous'};
parameters.loop_variables.conditions_stack_locations = {'stacks'; 'spontaneous'};

% Preprocessing parameters.
% Sampling frequency of collected data (per channel), in Hz or frames per
% second.
parameters.sampling_freq = 20; 

% Number of channels data was collected with. (2=had a blue and violet
% channel, 1= had only blue and need to find blood vessel masks for
% hemodynamic correction. 
parameters.channelNumber = 2;

% Number of pixels in the recorded image. Used to check that the 472 rig
% did, indeed, record at the correct number of pixels (sometimes records at
% 257 x 257 instead of 256 x 256).
parameters.pixels = [256, 256];

% If the blue channel is brighter than the violet. Blue should almost always be brighter 
% than violet, but rarely there's a problem with the LED settings and it's 
% dimmer than the violet. Used in registration_SaveRepresentativeImages.m and
% Preprocessing.m
parameters.blue_brighter = true; 

% Method of hemodynamics correction.
% Options:
% 'regression' -- Runs regression of blue pixels against corresponding
% violet pixels
% 'scaling' -- Has the same ultimate output as 'regression', but also
% calculates everything as DF/F.
% 'vessel regression'-- regresses (blue) pixels against masks drawn from
% blood vessels in the same (blue) channel. 
parameters.correction_method = 'regression';

% Number of initial frames to skip, allows for brightness/image
% stabilization of camera
parameters.skip = 1200; 

% Pixel ranges for checking brightness to determine which channel is which.
% Is a portion of the brain. 
parameters.pixel_rows = 110:160;
parameters.pixel_cols = [50:100 150:200]; 

% Representative images parameters.

    % The nth stack in the collected data that you want to use for the
    % representative image
    parameters.rep_stacki = 1; 

    % The nth frame in the chosen stack that you want to use for the
    % representative image (after the skipped frames). 
    parameters.rep_framei = 1;

% Across-day registration parameters

    % Set up transformation type (rigid, similar, or affine)
    parameters.transformation = 'affine';

    % Determine configuration for intensity-based image registration using
    % imregconfig...(keep monomodal because images are similar intensity/contrast)
    parameters.configuration = 'monomodal';

    % Set optimizer maximum step-length and iterations for performing registration
    parameters.max_step_length = 3e-3;
    parameters.max_iterations = 500;

% Do you want to mask your data? Yes--> mask_flag=true, No-->
% mask_flag=false.
parameters.mask_flag = true; 

% Do you want to temporally filter your data? Yes--> filter_flag=true, No-->
% filter_flag=false.
parameters.filter_flag = true; 

% Temporal filtering parameters. (These aren't used if filter_flag=false,
% because no filtering is performed.) 
    % Order of Butterworth filter you want to use.
    parameters.order = 5; 

    % Low cut off frequency
    %fc1=0.01; 
    
    % High cutoff frequency
    parameters.fc2 = 7; 

    % Find Niquist freq for filter; sampling divided by 2
    parameters.fn = parameters.sampling_freq/2; 

    % Find parameters of Butterworth filter. 
    [parameters.b, parameters.a] = butter(parameters.order, parameters.fc2/parameters.fn,'low');

% Set a minimum number of frames each channel of the stack needs to have to
% consider it a valid stack for full processing. (If less than this, code 
% will assume something very bad happened and won't continue processing the
% stack, will jump to the next stack.) 
parameters.minimum_frames = 5980; 

% Give list of individual frames to save from intermediate steps of
% preprocessing from each stack to use for spot checking.
parameters.frames_for_spotchecking = [1 500 1200 2400 3000]; 

% Set "upsampling factor" for dftregistration function (for within stack & 
% within day registration); determines the sub-pixel resolution of the registration; 
parameters.usfac = 10;   


% Re-run processing of random stack subset?
rerun = true;

%% Random selection of stacks

% Only run once
if ~isfile([parameters.dir_exper 'preprocessing\stack means\mice_all_random.mat'])
    
    create_RandomSubset_mice_all_RunAnalysis

    load('Y:\Sarah\Analysis\Experiments\Random Motorized Treadmill\preprocessing\stack means\mice_all_random.mat');
    parameters.mice_all = mice_all;
    parameters.loop_variables.mice_all = parameters.mice_all;

end

%% Re-run preprocessing of stacks to re-find means before hemodynamic correction
% ** need to repeat with file name MMStack_Default.ome.tif
% ** need to repeat with 'm1099' folder name for mouse 1099
if rerun

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


% Tell Preprocessing to save mean of data
parameters.save_stack_mean = true; 

% Input

% tforms across days
parameters.loop_list.things_to_load.tform.dir = {[parameters.dir_exper 'preprocessing\tforms across days\'], 'mouse', '\', 'day', '\'};
parameters.loop_list.things_to_load.tform.filename = {'tform.mat'};
parameters.loop_list.things_to_load.tform.variable = {'tform'};
parameters.loop_list.things_to_load.tform.level = 'day';

% brain masks
if parameters.mask_flag
parameters.loop_list.things_to_load.indices_of_mask.dir = {[parameters.dir_exper 'preprocessing\masks\']};
parameters.loop_list.things_to_load.indices_of_mask.filename = {'masks_m', 'mouse', '.mat'};
parameters.loop_list.things_to_load.indices_of_mask.variable = {'indices_of_mask'};
parameters.loop_list.things_to_load.indices_of_mask.level = 'mouse';
end 

% reference day per mouse 
parameters.loop_list.things_to_load.reference_image.dir = {[parameters.dir_exper 'preprocessing\representative images\'], 'mouse', '\'};
parameters.loop_list.things_to_load.reference_image.filename = {'reference_image.mat'};
parameters.loop_list.things_to_load.reference_image.variable = {'reference_image'};
parameters.loop_list.things_to_load.reference_image.level = 'mouse';

% representative image for day 
parameters.loop_list.things_to_load.bRep.dir = {[parameters.dir_exper 'preprocessing\representative images\'], 'mouse', '\', 'day', '\'};
parameters.loop_list.things_to_load.bRep.filename = {'bRep.mat'};
parameters.loop_list.things_to_load.bRep.variable = {'bRep'};
parameters.loop_list.things_to_load.bRep.level = 'day';

% stack im_list 
parameters.loop_list.things_to_load.im_list.dir = {[parameters.dir_dataset_base], 'day', '\', 'mouse', '\stacks\0', 'stack', '\'};
parameters.loop_list.things_to_load.im_list.filename = {'MMStack_Default.ome.tif'}; % {'0', 'stack', '_MMStack_Pos0.ome.tif'};
parameters.loop_list.things_to_load.im_list.variable = {'stack_data'};
parameters.loop_list.things_to_load.im_list.level = 'stack';
parameters.loop_list.things_to_load.im_list.load_function = @tiffreadAltered_SCA;
parameters.loop_list.things_to_load.im_list.load_function_additional_inputs = {[], 'ReadUnknownTags', true};      


% blood vessel masks
if strcmp(parameters.correction_method, 'vessel regression')
  % Establish filename of blood vessel mask.
  filename_vessel_mask = [dir_exper 'blood vessel masks\bloodvessel_masks_m' mouse '.mat']; 

    % Load blood vessel masks. 
    load(filename_vessel_mask, 'vessel_masks'); 
end

% Output

% stack means
if isfield(parameters, 'save_stack_mean') && parameters.save_stack_mean
parameters.loop_list.things_to_save.data_mean.dir = {[parameters.dir_exper '\preprocessing\stack means\'], 'mouse', '\', 'day', '\'};
parameters.loop_list.things_to_save.data_mean.filename = {'data_mean', 'stack', '.mat'};
parameters.loop_list.things_to_save.data_mean.variable = {'data_mean'};
parameters.loop_list.things_to_save.data_mean.level = 'stack';  
end 

% Run code.
RunAnalysis({@Preprocessing}, parameters);

end

%% Concatenate mean stacks within mice
% Always clear loop list first. 
if isfield(parameters, 'loop_list')
parameters = rmfield(parameters,'loop_list');
end

% Iterators
parameters.loop_list.iterators = {
               'mouse', {'loop_variables.mice_all(:).name'}, 'mouse_iterator'; 
               'day', {'loop_variables.mice_all(', 'mouse_iterator', ').days(:).name'}, 'day_iterator';
               'stack', {'getfield(loop_variables, {1}, "mice_all", {',  'mouse_iterator', '}, "days", {', 'day_iterator', '}, ', 'loop_variables.conditions_stack_locations{', 'condition_iterator', '})'}, 'stack_iterator'; 
               };

parameters.concatenation_level = 'stack';
parameters.concatDim = 3; 

% Inputs
parameters.loop_list.things_to_load.data.dir = {[parameters.dir_exper '\preprocessing\stack means\'], 'mouse', '\', 'day', '\'};
parameters.loop_list.things_to_load.data.filename = {'data_mean', 'stack', '.mat'};
parameters.loop_list.things_to_load.data.variable = {'data_mean'};
parameters.loop_list.things_to_load.data.level = 'stack';  

% Outputs
parameters.loop_list.things_to_save.concatenated_data.dir = {[parameters.dir_exper '\preprocessing\stack means\'], 'mouse', '\'};
parameters.loop_list.things_to_save.concatenated_data.filename = {'data_allmeans_permouse.mat'};
parameters.loop_list.things_to_save.concatenated_data.variable = {'data_allmeans'};
parameters.loop_list.things_to_save.concatenated_data.level = 'mouse';  

RunAnalysis({@ConcatenateData}, parameters);

%% Average mean stacks within mice

% Always clear loop list first. 
if isfield(parameters, 'loop_list')
parameters = rmfield(parameters,'loop_list');
end

% Iterators
parameters.loop_list.iterators = {
               'mouse', {'loop_variables.mice_all(:).name'}, 'mouse_iterator'; 
               };

parameters.averageDim = 3;

% Inputs
parameters.loop_list.things_to_load.data.dir = {[parameters.dir_exper '\preprocessing\stack means\'], 'mouse', '\'};
parameters.loop_list.things_to_load.data.filename = {'data_allmeans_permouse.mat'};
parameters.loop_list.things_to_load.data.variable = {'data_allmeans'};
parameters.loop_list.things_to_load.data.level = 'mouse';  

% Outputs
parameters.loop_list.things_to_save.average.dir = {[parameters.dir_exper '\preprocessing\stack means\'], 'mouse', '\'};
parameters.loop_list.things_to_save.average.filename = {'data_mean_permouse.mat'};
parameters.loop_list.things_to_save.average.variable = {'data_mean'};
parameters.loop_list.things_to_save.average.level = 'mouse';  

RunAnalysis({@AverageData}, parameters);

%% Find mean for each IC per mouse

% Always clear loop list first. 
if isfield(parameters, 'loop_list')
parameters = rmfield(parameters,'loop_list');
end

% Iterators
parameters.loop_list.iterators = {
               'mouse', {'loop_variables.mice_all(:).name'}, 'mouse_iterator'; 
               };

% Inputs
% Source masks
parameters.loop_list.things_to_load.sources.dir = {[parameters.dir_exper 'spatial segmentation\500 SVD components\manual assignments\'], 'mouse', '\'};
parameters.loop_list.things_to_load.sources.filename= {'sources_reordered_masked.mat'};
parameters.loop_list.things_to_load.sources.variable= {'sources_masked'};
parameters.loop_list.things_to_load.sources.level = 'mouse';

% Mean images
parameters.loop_list.things_to_load.mean_image.dir = {[parameters.dir_exper '\preprocessing\stack means\'], 'mouse', '\'};
parameters.loop_list.things_to_load.mean_image.filename = {'data_mean_permouse.mat'};
parameters.loop_list.things_to_load.mean_image.variable = {'data_mean'};
parameters.loop_list.things_to_load.mean_image.level = 'mouse';  

% Ouputs
% mean fluorescence per IC per mouse
parameters.loop_list.things_to_save.source_mean.dir = {[parameters.dir_exper '\preprocessing\stack means\'], 'mouse', '\'};
parameters.loop_list.things_to_save.source_mean.filename = {'IC_means_permouse.mat'};
parameters.loop_list.things_to_save.source_mean.variable = {'source_mean'};
parameters.loop_list.things_to_save.source_mean.level = 'mouse';  

RunAnalysis({@MeanPerSource}, parameters); 

%% Average across homologous ICs 

% Always clear loop list first. 
if isfield(parameters, 'loop_list')
parameters = rmfield(parameters,'loop_list');
end

% Iterators
parameters.loop_list.iterators = {
               'mouse', {'loop_variables.mice_all(:).name'}, 'mouse_iterator'; 
               };
parameters.evaluation_instructions = {{'data = reshape(parameters.data, 2, parameters.number_of_sources/2);' ...
                                       'data2 = mean(data,1);'...
                                       'data3 = repmat(data2, 1, 2);'
                                       'data_evaluated = reshape(data3, parameters.number_of_sources, 1);'}};

% Inputs
% mean fluorescence per IC per mouse
parameters.loop_list.things_to_load.data.dir = {[parameters.dir_exper '\preprocessing\stack means\'], 'mouse', '\'};
parameters.loop_list.things_to_load.data.filename = {'IC_means_permouse.mat'};
parameters.loop_list.things_to_load.data.variable = {'source_mean'};
parameters.loop_list.things_to_load.data.level = 'mouse';

% Output
% mean fluorescence per IC per mouse, one per homologous IC
parameters.loop_list.things_to_save.data_evaluated.dir = {[parameters.dir_exper '\preprocessing\stack means\'], 'mouse', '\'};
parameters.loop_list.things_to_save.data_evaluated.filename = {'IC_means_permouse_homologousTogether.mat'};
parameters.loop_list.things_to_save.data_evaluated.variable = {'source_mean'};
parameters.loop_list.things_to_save.data_evaluated.level = 'mouse';

RunAnalysis({@EvaluateOnData}, parameters);

%% 
% ** will apply percent changes in figure creation pipeline**