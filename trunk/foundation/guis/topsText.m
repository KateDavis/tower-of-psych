classdef topsText
    % @class topsText
    % Standard uicontrol args for text with static, clickable, toggle, and
    % edit behaviors
    
    methods (Static)
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
        
        function args = clickText
            basic = topsText.interactiveText;
            specific = { ...
                'ButtonDownFcn', @topsText.clickFcn, ...
                'TooltipString', 'click me'};
            args = cat(2, basic, specific);
        end
        
        function args = clickTextWithCallback(callback)
            basic = topsText.clickText;
            specific = {'Callback', callback};
            args = cat(2, basic, specific);
        end
        
        function args = toggleText
            basic = topsText.interactiveText;
            specific = {'ButtonDownFcn', @topsText.toggleFcn, ...
                'TooltipString', 'toggle me'};
            args = cat(2, basic, specific);
        end
        
        function args = toggleTextWithCallback(callback)
            basic = topsText.toggleText;
            specific = {'Callback', callback};
            args = cat(2, basic, specific);
        end
        
        function args = editText
            basic = topsText.interactiveText;
            specific = { ...
                'ButtonDownFcn', @topsText.editBeginFcn, ...
                'TooltipString', 'edit me'};
            args = cat(2, basic, specific);
        end
        
        function args = editTextWithGetterAndSetter(getter, setter)
            basic = topsText.editText;
            data.getter = getter;
            data.setter = setter;
            string = topsText.displayStringFromGetter([], getter);
            specific = {'UserData', data, 'String', string};
            args = cat(2, basic, specific);
        end
        
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
        
        function toggleOff(obj)
            v = get(obj, {'Value'});
            topsText.swapColors(obj(logical([v{:}])));
            set(obj, 'Value', false, 'Selected', 'off');
        end
        
        function toggleOn(obj)
            v = get(obj, {'Value'});
            topsText.swapColors(obj(~logical([v{:}])));
            set(obj, 'Value', true, 'Selected', 'on');
        end
        
        function swapColors(obj)
            cols = get(obj, {'BackgroundColor', 'ForegroundColor'});
            set(obj, {'ForegroundColor', 'BackgroundColor'}, cols);
        end
        
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
