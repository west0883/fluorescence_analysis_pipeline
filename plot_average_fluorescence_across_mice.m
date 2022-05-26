% plot_average_fluorescence_across_mice.m
% Sarah West
% 12/10/21

function [] = plot_average_fluorescence_across_mice(parameters)

    % Give time dimension.
    parameters.timeDim = 1; 
    
    % Give IC/ROI dimension
    parameters.ROIdim = 2;
    
    % Give instance diminsion (for reporting total numbers)
    parameters.instanceDim = 3;
  
    % Establish base input directory
    parameters.dir_input_base=[parameters.dir_exper 'average fluorescence across mice\'];

    % Input variable name
    parameters.input_variable_name = ['average_fluorescence_across_mice.mean']; 
    
    % Output directory name 
    parameters.dir_out_base = [parameters.dir_exper 'average fluorescence across mice\mean plots\'];
    
    % For now, skip continued rest and walkings
    parameters.periods_all(parameters.variable_duration) = [];
    
    % Tell user where data is being saved
    disp(['Data saved in ' parameters.dir_out_base]); 
    
    mkdir(parameters.dir_out_base);
        
    % For each period
    for periodi = 1:size(parameters.periods_all, 1) 
        period = parameters.periods_all{periodi};

        % load corresponding data.
        load([parameters.dir_input_base 'average_' period '.mat']);

        % Make a figure,
        figure; hold on;

        % For each ROI
        for ROIi = 1:size(average_fluorescence_across_mice.mean, parameters.ROIdim)

            % Plot the ROI
            plot(average_fluorescence_across_mice.mean(:,ROIi)); 

        end 

        ylim(parameters.ylim);

        % Add legend based on if there are ROI regions
        if isfield(parameters, 'ROI_names')
            legend(parameters.ROI_names);
        else 
            legend;
        end

        % Add title with mouse, period, and number of instances
        total_instances = average_fluorescence_across_mice.instances_total; 

        title(['all mice ' period ', n=' num2str(total_instances) ' (' num2str(average_fluorescence_across_mice.instances_per_mouse) ')']);

        % Save
        savefig([parameters.dir_out_base 'mean_' period '.fig']);
        close all; 
    end
end 