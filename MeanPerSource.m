% MeanPerSource.m
% Sarah West
% 11/29/22

% Function that finds the mean flourescence value of each region source
% (ie. IC) from source masks and a mean value image. 

% Runs with RunAnalysis

function [parameters] = MeanPerSource(parameters)

    parameters.source_mean = parameters.sources .* parameters.mean_image;

end 