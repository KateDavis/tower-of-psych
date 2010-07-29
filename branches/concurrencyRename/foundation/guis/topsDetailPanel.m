classdef topsDetailPanel < handle
    % @class topsDetailPanel
    % Superclass to manage each reusable, movable uipanel portion of
    % a topsGUI graphical interface.
    % @details
    % topsDetailPanel relies on its parentGUI, an instance of topsGUI
    % or a subclass, to function.  It's not able to function independently
    % like a regular uipanel.
    % @ingroup foundataion
    
    properties
        % topsGUI that contains this panel
        parentGUI;
        
        % normalized [x y w h] where to locate this panel in parentGUI
        position = [0 0 1 1 ];
        
        % uipanel to hold uicontrols
        panel;
        
        % true or false, whether the GUI allows editing of values
        detailsAreEditable = false;
        
        % length in characters of strings that summarize values displayed
        % in the panel
        stringSummaryLength = 22;
        
        % colormap of colors visible against white
        colors;
        
        % an offwhite color used by all detail panels
        lightColor = [1 1 .98];
    end
    
    methods
        % Constructor takes one or two arguments.
        % @param parentGUI a topsGUI to contains this panel
        % @param position normalized [x y w h] where to locate the new
        % panel in @a parentGUI
        % @details
        % Returns a handle to the new topsDetailPanel.  If @a parentGUI is
        % missing, the panel will be empty.
        function self = topsDetailPanel(parentGUI, position)
            if nargin
                self.parentGUI = parentGUI;
            end
            
            if nargin == 2
                self.position = position;
            end
            
            self.colors = spacedColors(61);
            
            if ~isempty(self.parentGUI) && ishandle(self.parentGUI.figure)
                self.createWidgets;
            end
        end
        
        % Create a new ui panel within the parentGUI's figure.
        function createWidgets(self)
            if ishandle(self.panel)
                delete(self.panel)
            end
            
            f = self.parentGUI.figure;
            self.panel = uipanel( ...
                'Parent', f, ...
                'BorderType', 'line', ...
                'BorderWidth', 1, ...
                'ForegroundColor', get(f, 'Color'), ...
                'HighlightColor', get(f, 'Color'), ...
                'Title', '', ...
                'BackgroundColor', 'none', ...
                'Units', 'normalized', ...
                'Position', self.position, ...
                'Clipping', 'on', ...
                'HandleVisibility', 'on', ...
                'HitTest', 'on', ...
                'SelectionHighlight', 'off', ...
                'Visible', 'on');
        end
        
        % Color in string variables using standard colors.
        % @param string a string that should be colored in
        % @details
        % Computes the "sum" of the string and uses it as an index into the
        % standard color map.  Returns the color from the color map.
        % @details
        % The idea is that strings should pop out visually, and identical
        % strings should pop out together and be memorable from gui to gui.
        function col = getColorForString(self, string)
            hash = 1 + mod(sum(string), size(self.colors,1));
            col = self.colors(hash, :);
        end
        
        % Use a standard look and feel for uicontrol widgets.
        % @param value any value or object to be represented with a
        % uicontrol
        % @details
        % Returns a list of standard "look and feel" arguments for
        % uicontrol controls, some of which may depend on the type and
        % value of @a value.
        function args = getLookAndFeelForValue(self, value)
            if ischar(value)
                col = self.getColorForString(value);
                bg = self.lightColor;
            else
                col = [0 0 0];
                bg = get(self.parentGUI.figure, 'Color');
            end
            string = summarizeValue(value, self.stringSummaryLength);
            args = { ...
                'ForegroundColor', col, ...
                'BackgroundColor', bg, ...
                'String', string};
        end
        
        % Present standard controls to describe values.
        % @param value any value or object to be described with a uicontrol
        % @details
        % Returns a list of standard arguments to represent @a value.
        % The arguments will reflect the type of @a value.  Strings get
        % colored in using getColorForString().  Other values get
        % summarized as black strings.
        function args = getDescriptiveUIControlArgsForValue(self, value)
            static = topsText.staticText;
            lookFeel = self.getLookAndFeelForValue(value);
            args = cat(2, static, lookFeel);
        end
        
        % Present standard controls to interact with values.
        % @param value any value or object to be interacted with, with a
        % uicontrol
        % @details
        % Returns a list of standard arguments to represent and interact
        % with @a value.  Strings and function handles match files on
        % Matlab's path become clickable links for opening the file in
        % Matlab.  Objects with a gui() method, including topsFoundataion
        % objects, also become bold links for launching object guis.
        % @details
        % If there's no good way to ineract with @a value, returns
        % the same arguments as getDescriptiveUIControlArgsForValue().
        function args = getInteractiveUIControlArgsForValue(self, value)
            callback = [];
            if isscalar(value) && any(strcmp(methods(value), 'gui'))
                % open up one of the topsFoundataion guis
                callback = @(obj,event) value.gui;
                
            elseif isscalar(value) && isa(value, 'function_handle')
                % open a funciton's m-file
                mName = [func2str(value), '.m'];
                if exist(mName, 'file')
                    callback = @(obj,event) open(mName);
                end
                
            elseif ischar(value)
                % open up an m-file
                mName = [value, '.m'];
                if exist(mName, 'file')
                    callback = @(obj,event) open(mName);
                end
                
            end
            
            if isempty(callback)
                % fallback on non-interactive control
                args = self.getDescriptiveUIControlArgsForValue(value);
                
            else
                click = topsText.clickTextWithCallback(callback);
                lookFeel = self.getLookAndFeelForValue(value);
                args = cat(2, click, lookFeel);
            end
        end
        
        % Present standard controls for editing values.
        % @param getter fevalable cell array to invoke that returns the
        % value to be displayed
        % @param setter fevalable cell array to invoke to set a new value
        % from user input (should expect the new value as the first
        % argument).
        % @details
        % Returns a list of standard arguments to show and allow editing of
        % a value.  The value displayed will reflect the return value of
        % the @a getter fevalable.
        % @details
        % The user may click inside the control to type a new string, which
        % will be passed to Matlab's built-in eval() function.  The
        % eval() result wil be passed to the @a setter function to update
        % the value.
        % @details
        % The control will not attempt to validate user inputs.  It will
        % attempt to catch errors and display them, and only invoke the @a
        % setter upon success.
        function args = getEditableUIControlArgsWithGetterAndSetter(self, getter, setter)
            editable = topsText.editTextWithGetterAndSetter(getter, setter);
            lookFeel = self.getLookAndFeelForValue(feval(getter{:}));
            args = cat(2, editable, lookFeel);
        end
        
        % Create a topsText control that editable, if detailsAreEditable.
        function args = getModalControlArgs(self, object, refPath)
            if self.detailsAreEditable && ~isempty(refPath)
                subs = substruct(refPath{:});
                getter = {@topsDetailPanel.getValue, object, subs};
                setter = {@topsDetailPanel.setValue, object, subs};
                args = self.getEditableUIControlArgsWithGetterAndSetter(...
                    getter, setter);
                
            else
                args = self.getInteractiveUIControlArgsForValue(object);
            end
        end
    end
    
    methods (Static)
        % Set a value using subsasgn.
        function setValue(value, object, subs)
            if ~isempty(subs)
                subsasgn(object, subs, value);
            end
        end
        
        % Get a value usung subsref.
        function value = getValue(object, subs)
            if isempty(subs)
                value = [];
            else
                value = subsref(object, subs);
            end
        end
    end
end