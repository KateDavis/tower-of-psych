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
                };
        end
        
        function args = clickText
            basic = topsText.interactiveText;
            specific = { ...
                'ButtonDownFcn', @topsText.clickFcn, ...
                'TooltipString', 'click me'};
            args = cat(2, basic, specific);
        end
        
        function args = toggleText
            basic = topsText.interactiveText;
            specific = {'ButtonDownFcn', @topsText.toggleFcn, ...
                'TooltipString', 'toggle me'};
            args = cat(2, basic, specific);
        end
        
        function args = editText
            basic = topsText.interactiveText;
            specific = {'ButtonDownFcn', @topsText.editBeginFcn, ...
                'TooltipString', 'edit me'};
            args = cat(2, basic, specific);
        end
        
        function clickFcn(text, event)
            topsText.toggleOn(text)
            pause(.025);
            
            cb = get(text, 'Callback');
            if ~isempty(cb)
                feval(cb, text, event);
            end
            
            topsText.toggleOff(text)
            drawnow;
        end
        
        function toggleFcn(text, event)
            if get(text, 'Value')
                topsText.toggleOff(text)
            else
                topsText.toggleOn(text)
            end
            
            cb = get(text, 'Callback');
            if ~isempty(cb)
                feval(cb, text, event);
            end
            drawnow;
        end
        
        function toggleOff(text)
            v = get(text, {'Value'});
            topsText.swapColors(text(logical([v{:}])));
            set(text, 'Value', false, 'Selected', 'off');
        end

        function toggleOn(text)
            v = get(text, {'Value'});
            topsText.swapColors(text(~logical([v{:}])));
            set(text, 'Value', true, 'Selected', 'on');
        end
        
        function swapColors(text)
            cols = get(text, {'BackgroundColor', 'ForegroundColor'});
            set(text, {'ForegroundColor', 'BackgroundColor'}, cols);
        end
        
        function editBeginFcn(text, event)
            set(text, 'Value', true, ...
                'Selected', 'on', ...
                'Style', 'edit', ...
                'Enable', 'on', ...
                'ButtonDownFcn', get(text, 'Callback'), ...
                'Callback', @topsText.editEndFcn);
            drawnow;
        end
        
        function editEndFcn(text, event)
            cb = get(text, 'ButtonDownFcn');
            set(text, 'Value', false, ...
                'Selected', 'off', ...
                'Style', 'text', ...
                'Enable', 'inactive', ...
                'ButtonDownFcn', @topsText.editBeginFcn, ...
                'Callback', cb);
            if ~isempty(cb)
                feval(cb, text, event);
            end
            drawnow;
        end
    end
end
