% segment_fluorescence_motorizedTreadmill.m
% Sarah West
% 12/9/21

function [] = segment_fluorescence(parameters)

    % Establish input directory for fluorescence timeseries
    parameters.dir_in_data_base = [parameters.dir_exper 'extracted fluorescence timeseries\'];
    
    % Input data name for fluorescence timeseries
    parameters.input_data_name= {'timeseries', 'stack number', '.mat'}; 
    
    % Input variable name for fluorescence
    parameters.input_data_variable= 'timeseries'; 
  
    % Establish base output directory
    parameters.dir_out_base=[parameters.dir_exper 'fluorescence segmented by behavior\'];
    
    % Output file name. 
    parameters.output_filename = {'segmented_fluorescence_', 'stack number', '.mat'}; 
    
    % Output variable name
    parameters.output_variable = {'timeseries_', 'period name'}; 
  
    % Establish segmentation dimension.
    parameters.segmentDim = 1;
    
    % Establish concatenation dimension.
    parameters.concatDim = 3;    
    
    % For now, skip motor maintaining, m_p_nochange  continued rest and walkings
    parameters.periods_all(parameters.variable_duration) = [];
    
    % Tell user where data is being saved
    disp(['Data saved in '  parameters.dir_out_base]); 
    
    % Call segmentation code
    SegmentTimeseriesData(parameters.periods_all, parameters)
    
end 