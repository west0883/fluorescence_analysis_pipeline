function [] = average_fluorescence_across_mice(parameters)
    
    % Specify dimension to concatenate and average across
    parameters.concatDim = 3;
    
    % Establish base input directory
    parameters.dir_input_base=[parameters.dir_exper 'all fluorescence timeseries per mouse\'];
    
    % Input file name. 
    parameters.input_file_name = {'all_timeseries_', 'period name', '.mat'}; 
    
    % Input variable name
    parameters.input_variable_name = {'all_timeseries'}; 
  
    % Establish base output directory
    parameters.dir_out_base=[parameters.dir_exper '\average fluorescence across mice\'];
    
     % Output file name. 
    parameters.output_file_name = {'average_', 'period name', '.mat'}; 
    
    % Output variable name
    parameters.output_variable_name = {'average_fluorescence_across_mice'}; 
    
    % Tell user where data is being saved
    disp(['Data saved in ' parameters.dir_out_base]); 

    % Run averaging
    ConcatenateDataAcrossMice(parameters.periods_all, parameters);
    
end