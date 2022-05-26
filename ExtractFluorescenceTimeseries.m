% ExtractFlorescenceTimeseries.m
% Sarah West
% 4/5/22

% Extracts mean flourescence timeseries from source masks. 

function [parameters] = ExtractFluorescenceTimeseries(parameters)

     % Announce what extraction you're on.
     MessageToUser('Extracting ', parameters);

     % If no masked sources yet, 
     if ~isfield(parameters, 'sources_masked')

        % If there are masks to apply 
        if isfield(parameters, 'indices_of_mask')

            % Apply mask to sources (for right now assumes different
            % sources in 3rd dimension)
            holder = reshape(parameters.sources, parameters.yDim * parameters.xDim, []);
            parameters.sources_masked = holder(parameters.indices_of_mask, :);
    
        else
            % Assign masked sources just as the inputted sources
            parameters.sources_masked = parameters.sources; 
        end
     end 

     % Make sure data & source dimensions agree.
     if size(parameters.data, 1) ~= size(parameters.sources_masked, 1)
        error('Make sure your data and sources are inputted with pixels in first dimensions.');
     end 

     % Perform extraction

     % Weighted
     if isfield(parameters, 'weightedMean') && parameters.weightedMean
        parameters.timeseries = parameters.data'*parameters.sources_masked ./sum(parameters.sources_masked,1);
     
     % Not weighted.
     else
         parameters.timeseries = parameters.data' * (parameters.sources_masked > 0); 
     end

end