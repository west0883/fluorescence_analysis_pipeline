% plot_average_fluorescence_permouse.m
% Sarah West
% 12/10/21

function [] = plot_average_fluorescence_permouse(parameters)

    % Give time dimension.
    parameters.timeDim = 1; 
    
    % Give IC/ROI dimension
    parameters.ROIdim = 2;
    
    % Give instance diminsion (for reporting total numbers)
    parameters.instanceDim = 3;
  
    % Establish base input directory
    parameters.dir_input_base=[parameters.dir_exper 'all fluorescence timeseries per mouse\'];

    % Input variable name
    parameters.input_variable_name = ['all_timeseries.mean']; 
    
    % Output file name. 
   % parameters.output_file_name = {'all_timeseries_', 'period name', '.fig'}; 
   
    % Output directory name 
    parameters.dir_out_base = [parameters.dir_exper 'all fluorescence timeseries per mouse\mean plots\'];
    
    % For now, skip continued rest and walkings
    parameters.periods_all(parameters.variable_duration) = [];
    
    % Tell user where data is being saved
    disp(['Data saved in ' parameters.dir_out_base]); 
    
    % For each mouse 
    for mousei=1:size(parameters.mice_all,2)
        mouse= parameters.mice_all(mousei).name;
        
        dir_in = [parameters.dir_input_base mouse '\'];
        dir_out = [parameters.dir_out_base mouse '\'];
        
        mkdir([dir_out]);
        
        % For each period
        for periodi = 1:size(parameters.periods_all, 1) 
            period = parameters.periods_all{periodi};
            
            % load corresponding data.
            load([dir_in 'all_timeseries_' period '.mat']);
            
            % Make a figure,
            figure; hold on;
            
            % For each ROI
            for instancei = 1:size(all_timeseries.mean, parameters.ROIdim)
               
                % Plot the ROI
                plot(all_timeseries.mean(:,instancei)); 
                
            end 
            
            ylim(parameters.ylim);
            
            % Add legend based on if there are ROI regions
            if isfield(parameters, 'ROI_names')
                legend(parameters.ROI_names);
            else 
                legend;
            end
            
            % Add title with mouse, period, and number of instances
            total_instances = size(all_timeseries.all_instances, 3);
            title(['m' mouse ', ' period ', n = ' num2str(total_instances)]);
           
            % Save
            savefig([dir_out 'mean_' period '.fig']);
            close all; 
        end
    end
end 