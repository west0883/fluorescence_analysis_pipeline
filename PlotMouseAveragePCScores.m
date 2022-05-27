% PlotMouseAveragePCScores.m
% Sarah West
% 5/27/22

function [parameters] = PlotMouseAveragePCScores(parameters)

    parameters.fig = figure;
    imagesc(parameters.data(:, 1:20)); 
    colorbar; 
    title(strjoin(parameters.values(1:(end/2)), ', '));
    xlabel('PC number'); 
    yticklabels({parameters.mice_all(:).name});

end 
