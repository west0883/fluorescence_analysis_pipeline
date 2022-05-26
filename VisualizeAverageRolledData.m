% VisualizeAverageRolledData.m
% Sarah West
% 5/13/22

% Plots rolled (average, reshaped) data for different variable duration
% period types in one figure. 
% The period type needs to be the lowest iterator.

function [parameters] = VisualizeAverageRolledData(parameters)

    % Tell user what you're doing
    MessageToUser('Visualizing ', parameters);

    % Get this period name. Is the lowest iterator.
    period_name = parameters.values{numel(parameters.values)/2}; 
 
    % Get indices in periods_both conditions 
    indices = find(contains(parameters.periods_bothConditions, period_name));
  
    % Get subplot numbers
    [subplot_rows, subplot_columns] = OptimizeSubplotNumbers(numel(indices));

    % Find if this is a PC score condition.
    if any(contains(parameters.values(1:numel(parameters.values)/2), 'PCA individual mouse')) || any(contains(parameters.values(1:numel(parameters.values)/2), 'PCA across mice'))
        pc_flag = true;
    else
        pc_flag = false;
    end

    if any(contains(parameters.values(1:numel(parameters.values)/2), 'Fisher'))
        fisher_flag = true;
    else
        fisher_flag = false;
    end

    % Color range based on fisher & pc flags.
    if pc_flag 
        c_range = [-2 2];
    elseif ~pc_flag && fisher_flag
        c_range = [ 0.5 1.5];
    else
        c_range = [0.5 1];
    end


    % Make a figure; 
    fig = figure;

    fig.WindowState = 'maximized';

    % For each index 
    for i = 1:numel(indices)
         subplot(subplot_rows, subplot_columns,i);
         
         data = parameters.data{indices(i)};
         
         % Skip this plot if data is empty
         if isempty(data)
             continue
         end
         if pc_flag
           
            imagesc(data(1:30,:));
            
         else
            imagesc(data);
         end
         colorbar; caxis(c_range);
         xlabel('roll number');

         % sub title. 
         % If the index is within periods_nametable
         if indices(i) <= size(parameters.periods_nametable,1)

             % Include other name values.
             holder = [parameters.periods_nametable{indices(i), 2:6}];
             title(strjoin(holder, ', ' ));
         end
         
    end 
    % Make figure title with all iterator values in it.
    sgtitle([strjoin(parameters.values(1:end/2), ', ' ) ]);

    % Put figure into output.
    parameters.visual_fig = fig;
end 