classdef topsText
    % @class topsText
    % Standard uicontrol args for text with static, clickable, toggle, and
    % edit, and get/set binding behaviors.
    
    methods (Static)
        % Get uicontrol args for topsText static text.
        function args = staticText
            args = { ...
                'Style', 'text', ...
                'Enable', 'on', ...
                'SelectionHighlight', 'off', ...
                'Value', false, ...
                'Selected', 'off', ...
                'HitTest', 'off', ...
                'TooltipString', '', ...
                'HorizontalAlignment', 'left', ...
                'FontWeight', 'normal', ...
                'FontSize', 10, ...
                };
        end
        
        % Get uicontrol args for all topsText interavtive texts.
        function args = interactiveText
            args = { ...
                'Style', 'text', ...
                'Enable', 'inactive', ...
                'SelectionHighlight', 'on', ...
                'Value', false, ...
                'Selected', 'off', ...
                'HitTest', 'on', ...
                'HorizontalAlignment', 'left', ...
                'FontWeight', 'bold', ...
                'FontSize', 10, ...
                };
        end
        
        % Get uicontrol args for topsText clickable text.
        function args = clickText
            basic = topsText.interactiveText;
            specific = { ...
                'ButtonDownFcn', @topsText.clickFcn, ...
                'TooltipString', 'click me'};
            args = cat(2, basic, specific);
        end
        
        % Get uicontrol args for topsText clickable text which invokes a
        % callback.
        function args = clickTextWithCallback(callback)
            basic = topsText.clickText;
            specific = {'Callback', callback};
            args = cat(2, basic, specific);
        end
        
        % Get uicontrol args for topsText togglable text.
        function args = toggleText
            basic = topsText.interactiveText;
            specific = {'ButtonDownFcn', @topsText.toggleFcn, ...
                'TooltipString', 'toggle me'};
            args = cat(2, basic, specific);
        end
        
        % Get uicontrol args for topsText togglable text which invokes a
        % callback.
        function args = toggleTextWithCallback(callback)
            basic = topsText.toggleText;
            specific = {'Callback', callback};
            args = cat(2, basic, specific);
        end

        % Get uicontrol args for topsText editable text.
        function args = editText
            basic = topsText.interactiveText;
            specific = { ...
                'ButtonDownFcn', @topsText.editBeginFcn, ...
                'TooltipString', 'edit me'};
            args = cat(2, basic, specific);
        end
        
        % Get uicontrol args for topsText editable which invokes get and
        % set callbacks.
        % @param getter function handle to return a value to display in the
        % text widget
        % @param setter function handle to apply a user input value
        % elsewhere
        function args = editTextWithGetterAndSetter(getter, setter)
            basic = topsText.editText;
            data.getter = getter;
            data.setter = setter;
            string = topsText.displayStringFromGetter([], getter);
            specific = {'UserData', data, 'String', string};
            args = cat(2, basic, specific);
        end
        
        % topsText callback used for clicking behavior.
        function clickFcn(obj, event)
            topsText.toggleOn(obj)
            drawnow;
            
            cb = get(obj, 'Callback');
            if ~isempty(cb)
                feval(cb, obj, event);
            end
            
            topsText.toggleOff(obj)
            drawnow;
        end
        
        % topsText callback used for toggling behavior.
        function toggleFcn(obj, event)
            if get(obj, 'Value')
                topsText.toggleOff(obj)
            else
                topsText.toggleOn(obj)
            end
            
            cb = get(obj, 'Callback');
            if ~isempty(cb)
                feval(cb, obj, event);
            end
            drawnow;
        end
        
        % topsText callback used for toggling off.
        function toggleOff(obj)
            v = get(obj, {'Value'});
            topsText.swapColors(obj(logical([v{:}])));
            set(obj, 'Value', false, 'Selected', 'off');
        end
        
        % topsText callback used for toggling on.
        function toggleOn(obj)
            v = get(obj, {'Value'});
            topsText.swapColors(obj(~logical([v{:}])));
            set(obj, 'Value', true, 'Selected', 'on');
        end
        
        % topsText callback used for selection highlighting behavior.
        function swapColors(obj)
            cols = get(obj, {'BackgroundColor', 'ForegroundColor'});
            set(obj, {'ForegroundColor', 'BackgroundColor'}, cols);
        end
        
        % topsText callback used for accepting edit inputs.
        function editBeginFcn(obj, event)
            % attempt to wrap strings in automatically ''
            data = get(obj, 'UserData');
            if ~isempty(data)
                try
                    getter = data.getter;
                    value = feval(getter{:});
                    if ischar(value)
                        format = '''%s''';
                    else
                        format = '%s';
                    end
                    
                catch err
                    format = '%s';
                end
                set(obj, 'String', sprintf(format, get(obj, 'String')));
            end
            
            set(obj, 'Value', true, ...
                'Selected', 'on', ...
                'Style', 'edit', ...
                'HorizontalAlignment', 'center', ...
                'Enable', 'on', ...
                'ButtonDownFcn', get(obj, 'Callback'), ...
                'Callback', @topsText.editEndFcn);
            drawnow;
        end
        
        % topsText callback used for finishing edit inputs.
        function editEndFcn(obj, event)
            cb = get(obj, 'ButtonDownFcn');
            set(obj, 'Value', false, ...
                'Selected', 'off', ...
                'Style', 'text', ...
                'HorizontalAlignment', 'left', ...
                'Enable', 'inactive', ...
                'ButtonDownFcn', @topsText.editBeginFcn, ...
                'Callback', cb);
            
            data = get(obj, 'UserData');
            if ~isempty(data)
                try
                    string = get(obj, 'String');
                    newValue = eval(string);
                    setter = data.setter;
                    feval(setter{1}, newValue, setter{2:end});
                    
                catch err
                    disp(sprintf('%s edit failed:', mfilename))
                    disp(err)
                end
                
                getter = data.getter;
                newString = topsText.displayStringFromGetter(obj, getter);
                
                if ishandle(obj)
                    set(obj, 'String', newString);
                end
            end
            
            if ~isempty(cb)
                if ishandle(obj)
                    feval(cb, obj, event);
                else
                    feval(cb, [], event);
                end
            end
            
            drawnow;
        end
        
        % topsText callback used to display text edit results.
        function string = displayStringFromGetter(obj, getter)
            if ~isempty(obj) && ishandle(obj)
                oldUnits = get(obj, 'Units');
                set(obj, 'Units', 'characters');
                pos = get(obj, 'Position');
                set(obj, 'Units', oldUnits);
                string = summarizeValue(feval(getter{:}), pos(3));
            else
                string = summarizeValue(feval(getter{:}));
            end
        end
    end
end
