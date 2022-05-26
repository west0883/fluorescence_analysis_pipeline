% extract_fluorescence_timeseries.m
% Sarah West
% 12/8/21

function [] = extract_fluorescence_timeseries(parameters)

    % For each mouse 
    for mousei=1:size(parameters.mice_all,2)
        mouse=parameters.mice_all(mousei).name;
      
        % Find and load the ROI masks
        ROI_combined_input_name = [parameters.ROI_dir_in_base parameters.ROI_input_filename];
        ROI_file_string = CreateFileStrings(ROI_combined_input_name, mouse, [], [], [], false); 
        load(ROI_file_string, parameters.ROI_input_variable); 
        
        % Convert the ROI mask variable to a generic variable name.
        eval(['masks = ' parameters.ROI_input_variable ';']);
        
        % For each day
        for dayi=1:size(parameters.mice_all(mousei).days, 2)
            
            % Get the day name.
            day=parameters.mice_all(mousei).days(dayi).name; 
            
            % Create data input directory and cleaner output directory. 
            parameters.dir_in = CreateFileStrings(parameters.data_dir_in_base, mouse, day, [], [], false);
            dir_out=[parameters.dir_exper 'extracted fluorescence timeseries\' mouse '\' day '\']; 
            mkdir(dir_out); 
            
            % Get the data stack list
            [stackList]=GetStackList(mousei, dayi, parameters);
            
            % For each stack, 
            for stacki= 1:size(stackList.filenames,1)
                
                % Get the stack number and filename for the stack.
                stack_number = stackList.numberList(stacki, :);
                filename = stackList.filenames(stacki, :);
                
                % Tell user where you are.
                disp(['mouse ' mouse ', day ' day ', stack ' stack_number]);
        
                % Load the timeseries stack. 
                disp('Loading');
                load([parameters.dir_in filename], parameters.data_input_variable);
                                
                % Convert stack variable name to something generic.
                eval(['data = ' parameters.data_input_variable ';']);
                
                % Extract mean timeseries.
                disp('Extracting');
                timeseries = data'*masks ./sum(masks,1);
                
%                 % Detrend mean timeseries 
%                 disp('Detrending');
%                 timeseries = detrend(timeseries); 
                
                % Save timeseries. 
                save([dir_out 'timeseries' stack_number '.mat'], 'timeseries', '-v7.3'); 
                
            end 
        end
end 