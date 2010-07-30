classdef topsValuePanel < topsDetailPanel
    % @class topsValuePanel
    % Generic topsDetailPanel suitable for showing the class and size of
    % any value.  For complex values like cell arrays, structs, and
    % objects, also shows a summary for each element, field, or property,
    % organized with a ScrollingControlGrid.
    % @ingroup foundation
    
    properties
        % any value to represent in the panel
        value;
        
        % ScrollingControlGrid of details for value
        detailsGrid;
        
        % Arbitrary number of columns in detailsGrid
        width = 10;
    end
    
    methods
        % Constructor takes one or two arguments.
        % @param parentGUI a topsGUI to contains this panel
        % @param position normalized [x y w h] where to locate the new
        % panel in @a parentGUI
        function self = topsValuePanel(varargin)
            self = self@topsDetailPanel(varargin{:});
        end
        
        % Let the controls grid enable/disable scrolling.
        function repondToResize(self, figure, event)
            self.detailsGrid.repositionControls;
        end
        
        % Populate this panel with details about a value.
        % @param value any value to represent in the panel
        % @details
        % Fills in the panel with details about @a value.  If this panel's
        % detailsAreEditable is true, the controls will allow editing of
        % the value's elements, fields, or properties.
        function populateWithValueDetails(self, value)
            self.value = value;
            self.repopulateDetailsGrid;
        end
        
        % Build new controls when detailsAreEditable changes.
        function setEditable(self, isEditable)
            self.setEditable@topsDetailPanel(isEditable);
            self.repopulateDetailsGrid;
        end
        
        % Create a new uipanel and add a ScrollingControlGrid.
        function createWidgets(self)
            self.createWidgets@topsDetailPanel;
            
            if isobject(self.detailsGrid)
                self.detailsGrid.deleteAllControls;
            else
                self.detailsGrid = ScrollingControlGrid(self.panel);
                self.parentGUI.addScrollableChild( ...
                    self.detailsGrid.panel, ...
                    {@ScrollingControlGrid.respondToSliderOrScroll, ...
                    self.detailsGrid});
                self.detailsGrid.rowHeight = 1.5;
            end
        end
        
        % Show class, size, elements, fields, properties, for value.
        function repopulateDetailsGrid(self)
            value = self.value;
            self.detailsGrid.deleteAllControls;
            
            % a shallow summary of all items
            refPath = {};
            args = self.getModalControlArgs(value, refPath);
            self.detailsGrid.newControlAtRowAndColumn( ...
                1, [1 self.width], args{:});
            
            % a deeper look at fields and elements of deep items
            if isstruct(value) || isobject(value)
                if isstruct(value)
                    fn = fieldnames(value);
                else
                    fn = properties(value);
                end
                
                row = 1;
                n = numel(value);
                for ii = 1:n
                    % delimiter for each array element
                    row = row+1;
                    refPath(1:2) = {'()',{ii}};
                    delimiter = sprintf('(%d of %d)', ii, n);
                    
                    args = self.getDescriptiveUIControlArgsForValue( ...
                        delimiter);
                    self.detailsGrid.newControlAtRowAndColumn( ...
                        row, [1 4], args{:});
                    
                    for jj = 1:length(fn)
                        % field name and value
                        row = row+1;
                        refPath(3:4) = {'.',fn{jj}};
                        args = self.getDescriptiveUIControlArgsForValue( ...
                            fn{jj});
                        rightSide = {'HorizontalAlignment', 'right'};
                        self.detailsGrid.newControlAtRowAndColumn( ...
                            row, [2 self.width], args{:}, rightSide{:});
                        
                        row = row+1;
                        args = self.getModalControlArgs(value, refPath);
                        self.detailsGrid.newControlAtRowAndColumn( ...
                            row, [2 self.width], args{:});
                    end
                end
                
            elseif iscell(value)
                for ii = 1:numel(value)
                    row = ii + 1;
                    refPath(1:2) = {'{}',{ii}};
                    args = self.getModalControlArgs(value, refPath);
                    self.detailsGrid.newControlAtRowAndColumn( ...
                        row, [2 self.width], args{:});
                end
            end
            self.detailsGrid.repositionControls;
        end
    end
end