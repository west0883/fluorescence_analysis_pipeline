% concatenate_fluorescence.m
% Sarah West
% 12/10/21

% Concatenates fluorescence data within mice, across days and stacks. Keeps
% behavior periods and brain regions separate

function [] = concatenate_fluorescence(parameters)
    
    % Specify dimension to concatenate across.
    parameters.concatDim = 3;
    
    % Establish input directory for fluorescence
    parameters.dir_input_base = [parameters.dir_exper 'fluorescence segmented by behavior\'];
    
    % Input data name for fluorescence
    parameters.input_file_name= {'segmented_fluorescence_', 'stack number', '.mat'}; 
     
    % Get the input variable name ;
    parameters.input_variable_name = {'timeseries_', 'period name'}; 
  
    % Establish base output directory
    parameters.dir_out_base=[parameters.dir_exper 'all fluorescence timeseries per mouse\'];
    
    % Output file name. 
    parameters.output_file_name = {'all_timeseries_', 'period name', '.mat'}; 
    
    % Output variable name
    parameters.output_variable_name = {'all_timeseries'}; 
    
    % Tell user where data is being saved
    disp(['Data saved in ' parameters.dir_out_base]); 
    
    % For now, skip continued rest and walkings
    parameters.periods_all(parameters.variable_duration) = [];
    
    % Put all periods into a single cell array. 
    % If user asked for full onsets/full offsets, add those to the save list, too. 
    if isfield(parameters, 'full_transition_flag')  
        if parameters.full_transition_flag
            parameters.periods_all = [periods_long; parameters.periods_transition; parameters.periods_full_transition];
        else
            parameters.periods_all = [parameters.periods_long; parameters.periods_transition]; 
        end
    end 
    
    ConcatenateDataPerMouse(parameters.periods_all, parameters);
    
end 