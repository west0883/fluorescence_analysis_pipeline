% PlotPCs.m
% Sarah West 
% 5/23/22

% Plot a number of principal components. Run by RunAnalysis.

function [parameters] = PlotPCs(parameters)

    [subplot_rows, subplot_columns] = OptimizeSubplotNumbers(numel(parameters.components_to_plot),4/5);

    indices = logical(tril(ones(parameters.number_of_sources), -1));

    fig = figure;
    fig.WindowState = 'maximized';
    for componenti = parameters.components_to_plot
        holder = NaN(parameters.number_of_sources, parameters.number_of_sources);
        holder(indices) = parameters.components(:,componenti);
        subplot(subplot_rows, subplot_columns, componenti); imagesc(holder); caxis(parameters.color_range)
        title(['PC ' num2str(componenti)]); axis square;
    end
    sgtitle(strjoin(parameters.values(1:numel(parameters.values)/2), ', '))

    % Put into output structure.
    parameters.fig = fig;
end 
