% PCA_forRunAnalysis.m
% Sarah West
% 4/25/22
% A wrapper function for built-in Matlab PCA function.   

function [parameters] = PCA_forRunAnalysis(parameters)
    
    % If there's a "values" field from RunAnalysis, print updating message
    % for user. 
    MessageToUser('PCA on')

    % Pull out data matrix for easier manipulation
    data = parameters.data; 
    
    % If the observations are in different columns, flip the matrix so
    % they're in different rows.
    if parameters.observationDim ~= 1 
        data = data'; 
    end 

    % Run pca.
    [results.components, results.scores, results.latents, results.tsquared, results.explained] = pca(data, 'NumComponents', parameters.numComponents);

    % Put results into output matrix.
    parameters.results = results;

end 


