classdef topsClassification < topsFoundation
    % @class topsClassification
    % Represents data as points in space, for classification.
    % @details
    % topsClassification takes in data samples from multiple sources and
    % outputs arbitrary values.  It maps samples to outputs by way of
    % a spatial model: each data source maps to a spatial dimension,
    % each sample mapts to a value along one dimension, and a set of
    % samples maps to a point in space.  Regions in the space map to
    % arbitrary outputs, so the region in which a point falls determines
    % the output for a sample set.
    % @details
    % The spatial model is backed up by a high-dimensional matrix.  Picking
    % a point in space boils down to indexing into the matrix.  The key is
    % to convert arbitrary data samples into matrix indices.
    %
    % @ingroup foundation
    
    properties (SetAccess = protected)
        % struct array of data sources and descriptions
        sources = struct( ...
            'name', {}, ...
            'dimension', {}, ...
            'sampleFunction', {}, ...
            'sample', {});
        
        % struct array of spatial regions and outputs
        outputs = struct( ...
            'name', {}, ...
            'region', {}, ...
            'value', {});
        
        % topsSpace with spatial modeling utilities
        space;
        
        % high-dimensional matrix backing up the spatial model
        spaceTable;
    end
    
    methods
        % Add a data source.
        
        % Remove a data source by name.
        
        % Add a classification output.
        
        % Remove a classification output by name.
        
        % Get the latest classification output.
    end
    
    methods (Access = protected)
        % Rebuild the data space and spaceTable.
        function buildSpace(self)
            
        end
    end
end