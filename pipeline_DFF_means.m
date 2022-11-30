% pipeline_DFF_means.m
% Sarah West
% 11/29/22


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
parameters.mice_all = parameters.mice_all;

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
parameters.sampling_freq=20; 

% Number of channels data was collected with. (2=had a blue and violet
% channel, 1= had only blue and need to find blood vessel masks for
% hemodynamic correction. 
parameters.channelNumber=2;

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
parameters.correction_method ='regression';

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
    parameters.rep_stacki=1; 

    % The nth frame in the chosen stack that you want to use for the
    % representative image (after the skipped frames). 
    parameters.rep_framei=1;

% Across-day registration parameters

    % Set up transformation type (rigid, similar, or affine)
    parameters.transformation='affine';

    % Determine configuration for intensity-based image registration using
    % imregconfig...(keep monomodal because images are similar intensity/contrast)
    parameters.configuration='monomodal';

    % Set optimizer maximum step-length and iterations for performing registration
    parameters.max_step_length=3e-3;
    parameters.max_iterations=500;

% Do you want to mask your data? Yes--> mask_flag=true, No-->
% mask_flag=false.
parameters.mask_flag=true; 

% Do you want to temporally filter your data? Yes--> filter_flag=true, No-->
% filter_flag=false.
parameters.filter_flag=true; 

% Temporal filtering parameters. (These aren't used if filter_flag=false,
% because no filtering is performed.) 
    % Order of Butterworth filter you want to use.
    parameters.order=5; 

    % Low cut off frequency
    %fc1=0.01; 
    
    % High cutoff frequency
    parameters.fc2=7; 

    % Find Niquist freq for filter; sampling divided by 2
    parameters.fn=parameters.sampling_freq/2; 

    % Find parameters of Butterworth filter. 
    [parameters.b, parameters.a]=butter(parameters.order, parameters.fc2/parameters.fn,'low');

% Set a minimum number of frames each channel of the stack needs to have to
% consider it a valid stack for full processing. (If less than this, code 
% will assume something very bad happened and won't continue processing the
% stack, will jump to the next stack.) 
parameters.minimum_frames=5980; 

% Give list of individual frames to save from intermediate steps of
% preprocessing from each stack to use for spot checking.
parameters.frames_for_spotchecking=[1 500 1200 2400 3000]; 

% Set "upsampling factor" for dftregistration function (for within stack & 
% within day registration); determines the sub-pixel resolution of the registration; 
parameters.usfac=10;   


% Re-run processing of random stack subset?
rerun = true;

%% Random selection of stacks

% Only run once
if ~isfile([parameters.dir_exper 'preprocessing\stack means\mice_all_random.mat'])
    create_RandomSubset_mice_all_RunAnalysis
end

%% Re-run preprocessing of stacks to re-find means before hemodynamic correction

parameters.dir_dataset_name={'Y:\Sarah\Data\' parameters.experiment_name, '\', 'day', '\m', 'mouse number', '\stacks\0', 'stack number', '\'};
parameters.dir_dataset_base = ['Y:\Sarah\Data\' parameters.experiment_name, '\'];
%parameters.input_data_name={'.tif'};
parameters.input_data_name={'0', 'stack number', '_MMStack_Pos0.ome.tif' }; 

if rerun

    % Output
    parameters.dir_out_base = [parameters.dir_exper 'fully preprocessed stacks\'];


end

%% Take average of stacks within mice




%% Find mean for each IC per mouse

%RunAnalysis({@MeanPerSource}, parameters); 

% Inputs
% Source masks
parameters.loop_list.things_to_load.sources.dir = {[parameters.dir_exper 'spatial segmentation\500 SVD components\manual assignments\'], 'mouse', '\'};
parameters.loop_list.things_to_load.sources.filename= {'sources_reordered_masked.mat'};
parameters.loop_list.things_to_load.sources.variable= {'sources_masked'};
parameters.loop_list.things_to_load.sources.level = 'mouse';

% Mean images


% Ouputs
% mean fluorescence per IC per mouse