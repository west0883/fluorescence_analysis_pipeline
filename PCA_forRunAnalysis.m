% PCA_forRunAnalysis.m
% Sarah West
% 4/25/22
% A wrapper function for built-in Matlab PCA function.   

function [parameters] = PCA_forRunAnalysis(parameters)
    
    % If there's a "values" field from RunAnalysis, print updating message
    % for user.  
    MessageToUser('PCA on', parameters)

    % Pull out data matrix (because you'll be potentially flipping it
    % around)
    data = parameters.data; 
    
    % If the observations are in different columns, flip the matrix so
    % they're in different rows.
    if parameters.observationDim ~= 1 
        data = data'; 
    end 

    % Create name-value input pairs based on user input byt concatenating
    % possible pairs together into a cell array, then doing NameValues{:}
    % as an input to the pca function.
    NameValues = {};

    % If user gave an entry for number of components.
    if isfield(parameters, 'numComponents')
         NameValues = [NameValues, {'NumComponents'}, {parameters.numComponents}];
    end

    % If user gave an entry for the algorithm to use.
    if isfield(parameters, 'algorithm')
         NameValues = [NameValues, {'Algorithm'}, {parameters.algorithm}];
    end

    % If user wants to use weighted PCA (per observation)
    if isfield(parameters, 'observation_weighted_flag') && parameters.observation_weighted_flag

        if isempty(parameters.observation_weights)
           error('Observation-weighted PCA was selected but no observation weights were provided.')
        end 

        NameValues = [NameValues, {'Weights'}, {parameters.observation_weights}];
    
    end

    % If user wants to use pairwise PCA.
    if isfield(parameters, 'pairwise_flag') && parameters.pairwise_flag
        NameValues = [NameValues, {'Rows'}, {'pairwise'}];
    end 

    % If user wants to use variable weights (might use if you do pairwise
    % PCA & want to adjust variable influence based on how much data from
    % it is missing -- like a whole node from a given mouse).
    if isfield(parameters, 'variable_weighted_flag') && parameters.variable_weighted_flag

        if isempty(parameters.variable_weights)
           error('Variable-weighted PCA was selected but no variable weights were provided.')
        end

        NameValues = [NameValues, {'VariableWeights'}, {parameters.variable_weights}];
    end
   
    % Run pca 
    [results.components, results.scores, results.latents, results.tsquared, results.explained] = pca(data, NameValues{:});

    % Put results into output matrix.
    parameters.results = results;

end 


