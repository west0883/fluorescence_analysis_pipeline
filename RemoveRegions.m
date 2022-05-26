% RemoveRegions.m
% Sarah West
% 2/4/22

% Removes unwanted regions (or other specific occurances) from data. 

function [] = RemoveRegions(parameters)


    % Say where data is being saved
    disp(['Data saved in '  parameters.dir_out_base{1}]); 
   
    % Load list of region names (for labeling). Convert variable to
    % something generic.
    filename = CreateFileStrings([parameters.dir_in_areanames_base  parameters.input_areanames_filename], [], [], [], [], false);
    load(filename);
    variable_name = CreateFileStrings(parameters.input_areanames_variable, [], [], [],[], false);
    eval(['areanames = ' variable_name ';']);

    % Add in right regions.
    % Make a cell twice as large to hold everything
    all_regions = cell(2* size(areanames,1), 1); 

    % Put in left regions
    all_regions(1:2:end) = areanames(:,2);

    % Put in right regions region-by-region (because is a cell) 
    for regioni = 1:size(areanames,1)

         % Remove any "1"s from the name.
         areanames{regioni,2} = strrep(areanames{regioni,2},'1', '');

         % Replace underscores with dashes 
         all_regions{regioni *2-1}= strrep(areanames{regioni,2},'_', '-');

         % Names. Remove last "L" and replace with "R"
         all_regions{regioni*2} = [all_regions{regioni*2-1}(1:end-1) 'R'];

    end

    % Remove bad regions from all_regions
    all_regions(parameters.regions_to_remove) = [];

    % Load list of period names, convert to something generic.
    filename = CreateFileStrings([parameters.dir_in_periods_base  parameters.input_periods_filename], [], [], [], [], false);
    load(filename);
    variable_name = CreateFileStrings(parameters.input_periods_variable, [], [], [], [], false);
    eval(['periods = ' variable_name ';']);

    % For each mouse 
    for mousei=1:size(parameters.mice_all,2)
        mouse=parameters.mice_all(mousei).name;
      
        % Save regions list 
        save(['Y:\Sarah\Analysis\Experiments\Random Motorized Treadmill\atlas ROIs preliminary analysis\atlases\' mouse '\regions_in_this_mouse.mat'], 'all_regions');
        % For each period 
        for periodi = 1:size(periods,1)
            period = periods{periodi};

            if isempty(period)
                continue
            end             

            % Get names of data, load in, convert to generic name
            filename = CreateFileStrings([parameters.dir_in_base parameters.input_filename], mouse, [], [], period, false);
            
            if ~isfile(filename)
                continue
            end
            
            load(filename);
            variable_name = CreateFileStrings(parameters.input_variable, mouse, [], [], period, false); 
            eval(['Data = ' variable_name ';']);

            if isempty(Data)
                continue
            end

            % For each dimension for removal, 
            for removalDimi = 1:numel(parameters.removalDim)

                % Make a clean cell array of "alls" the size of the data.
                C = repmat({':'},1, ndims(Data));

                % Put in removal occurances to this dimension
                C(parameters.removalDim(removalDimi)) = {parameters.regions_to_remove};

                % Remove
                Data(C{:}) = []; 
            end 
        
            % Get the right names for saving per period.
            dir_out = CreateFileStrings([parameters.dir_out_base], mouse , [], [], period, false);
            if ~isdir(dir_out)
                mkdir(dir_out)
            end
            saving_filename = CreateFileStrings([parameters.dir_out_base parameters.output_filename], mouse , [], [], period, false);
            output_variable_name = CreateFileStrings(parameters.output_variable, mouse, [], [], period, false);
            eval([output_variable_name ' = Data;']);

            % Save
            save([saving_filename], output_variable_name, '-v7.3'); 

            % Close any previous figures
            close all; 

            % Plot the correlation matrices.
            figure; imagesc(Data); 

            % Add colorbar with all ticks correctly labeled
            caxis(parameters.color_range);
            title([mouse ' all ' period]); axis square;

            if isfield(parameters, 'RedBlue') && parameters.RedBlue 
                mymap = flipud(cbrewer('div', 'RdBu', 256, 'linear'));
                colormap(mymap);
            end 
           
            % Put colorbar ticks in right place. 
            ctics = [parameters.color_range(1): 0.1:parameters.color_range(2)];
            clabels = cell(numel(ctics),1);
            for i = 1:numel(ctics)
                clabels{i} = num2str(ctics(i));
            end 
            colorbar('XTickLabel', clabels, 'XTick', ctics); 

            % Make label positions.
            xticks([(1:numel(all_regions))]);
            yticks([(1:numel(all_regions))]);

            % Add labels
            %xticklabels(all_regions);
            %yticklabels(all_regions);
             grid on;
            yticks([(1:28)-0.5]);
            xticks([(1:28)-0.5]);
            set(gca,'XTickLabel',all_regions,'fontsize',8,'FontWeight','bold');
            set(gca,'YTickLabel',all_regions,'fontsize',8,'FontWeight','bold');

            % Make a figure filename
            figure_saving_filename = saving_filename;
            if all(figure_saving_filename([end-3:end]) == '.mat')
               figure_saving_filename([end-3:end]) = [];
            end

            % Save figure;
            savefig([figure_saving_filename]); 
            saveas(gcf,[figure_saving_filename], 'svg');

        end
    end 

end 