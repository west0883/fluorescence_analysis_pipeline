% WeightsforPCA.m
% Sarah West
% 5/19/22

% A quick function that calculates the weights that should be used for PCA
% across mice.

function [parameters] = WeightsforPCA(parameters)
    
    % Concatenate size of each element you want to use.

    % If it doesn't exist yet, create field correlation_matrices_numbers.
    if ~isfield(parameters, 'correlation_matrices_numbers')
         parameters.correlation_matrices_numbers = [];
    end
   
    filename = CreateStrings(parameters.filename, 'mouse', mouse);
    
    % Get a matlab file object of the file.
    matObj = matfile(filename);
    
    correlation_matrices_numbers(mousei) = size(matObj,2);


    % Take sum of the numbers across mice, find proportion of each mouse to
    % that sum.
    total = sum(correlation_matrices_numbers); 
    parameters.weight_values = correlation_matrices_numbers./total; 

end