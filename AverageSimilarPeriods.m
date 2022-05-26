% AverageSimilarPeriods.m
% Sarah West
% 2/3/22

% (accels, decels, maintaining at walking, stops)
function [] = AverageSimilarPeriods(parameters)

    % Load list of period groupings
    filename = CreateFileStrings([parameters.dir_in_grouping_base parameters.input_grouping_filename], [], [], [], [], false);
    load(filename);

    % Convert variable for period groupings to something generic.
    variable = CreateFileStrings([parameters.input_grouping_variable], [], [], [], [], false);
    eval(['PeriodGroupings = ' variable ';']);

    % Repeat for list of all peiriods.
    filename = CreateFileStrings([parameters.dir_in_periods_base parameters.input_periods_filename], [], [], [], [], false);
    load(filename);
    variable = CreateFileStrings([parameters.input_periods_variable], [], [], [], [], false);
    eval(['AllPeriods = ' variable ';']);

    % Say where data is being saved
    disp(['Data saved in '  parameters.dir_out_base{1}]); 
   
    % For each mouse 
    for mousei=1:size(parameters.mice_all,2)
        mouse=parameters.mice_all(mousei).name;
      
        % For each period group
        for groupi = 1:numel(PeriodGroupings)

            % Get the current grouping name
            group = PeriodGroupings{groupi};
            
            % Make a holding variable for this group. 
            group_holder = []; 

            count_holder = []; 
            
            % If the group is empty, skip to next loop iteration 
            if isempty(group)
                continue
            end

            % Search periods list for that group
            indices = find(contains(AllPeriods, group));

            % For each occurance of that group in the periods list,
            for periodi = 1:numel(indices)
                 
                % Get the name of the subgroup to be grouped in.
                period = AllPeriods{indices(periodi)};

                % Load data for that period, convert variable name to
                % something generic.
                filename = CreateFileStrings([parameters.dir_in_base parameters.input_filename], mouse, [], [], period, false);
                
                % If that file doesn't exist, skip to next loop iteration
                if ~isfile(filename)
                    continue
                end
                load(filename);
                variable = CreateFileStrings([parameters.input_variable], mouse, [], [], period, false);
                eval(['PeriodData = ' variable ';']);

                % Concatenate according to groupDim
                group_holder = cat(parameters.groupDim, group_holder, PeriodData);
                
                % Get count of instances info.
                variable = CreateFileStrings([parameters.input_counting_variable], mouse, [], [], period, false);
                eval(['CountData = ' variable ';']);
                count_holder = [ count_holder; size(CountData, parameters.groupDim)];
                
            end

            % Take mean and standard deviation per group. 
            group_mean = nanmean(group_holder, parameters.groupDim);
            group_std = std(group_holder, [], parameters.groupDim, 'omitnan');

            % Get total number of instances in this group.
            count_holder_total= nansum(count_holder); 
        
            % Get the output variable name
            output_variable_name = CreateFileStrings(parameters.output_variable, mouse, [], [], group, false);
           
            % Convert correlation data to the desired variable name
            eval([output_variable_name '.all_instances = group_holder;']);
            eval([output_variable_name '.mean = group_mean;']);
            eval([output_variable_name '.std = group_std;']); 
            eval([output_variable_name '.all_counts = count_holder;']); 
            eval([output_variable_name '.total_counts = count_holder_total;']);
        
            % Make ouput directory name, make if doesn't already exist.
            dir_out = CreateFileStrings(parameters.dir_out_base, mouse, [], [], group, false);
            if ~isfolder(dir_out)
                mkdir(dir_out);
            end

            % Get the right names for saving per period.
            saving_filename = CreateFileStrings(parameters.output_filename, mouse , [], [], group, false);
            
            % Save per period. 
            save([dir_out saving_filename], output_variable_name);

            % Close any previous figures.
            close all;

            % Plot mean per period.
            figure; imagesc(group_mean); colorbar; 
            title(['grouped mean m' mouse ' all ' group]);
            
            % Make a figure filename
            figure_saving_filename = saving_filename;
            if all(figure_saving_filename([end-2:end]) == 'mat')
               figure_saving_filename([end-2:end]) = 'fig';
            end

            % Save figure;
            savefig([dir_out figure_saving_filename ]); 
        end
    end
end 