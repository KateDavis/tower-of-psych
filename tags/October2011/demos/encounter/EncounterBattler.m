classdef EncounterBattler < handle
    % Class to represent character or monster in the "encounter" demo game.
    
    properties (SetObservable)
        % the name to display for this battler
        name = 'nameless';
        
        % the hit points left for this battler
        hp = 1;
        
        % the hit points of this battler when new
        maxHp = 1;
    end
    
    properties (Hidden)
        % true or false, whether this battler is a monser
        isMonster = false;
        
        % true or false, whether this battler is already dead
        isDead = false;
        
        % interval between attacks for this battler
        attackInterval = 5;
        
        % average damage dealt by this battler
        attackMean = 1;
        
        % [rgb] in [0 1] display color for this battler
        color;
        
        % [rgb] in [0 1] display outline color for this battler
        lineColor;
        
        % [rgb] in [0 1] display selection color for this battler
        highlightColor;
        
        % vector of x-points for the polygon to display for this battler
        xPoints;
        
        % vector of y-points for the polygon to display for this battler
        yPoints;
        
        % handle graphics handle for displaying this batler
        bodyHandle;
        
        % handle graphics handle for displaying this batler's name
        nameHandle;
        
        % handle graphics handle for displaying damage dealt to this
        % battler
        damageHandle;
    end
    
    methods
        % Make a new battler object.
        function self = EncounterBattler(isMonster)
            if nargin
                self.isMonster = isMonster;
            end
            
            if self.isMonster
                % will create funky shape for monsters
                n = 7;
                self.xPoints = rand(1,n);
                self.yPoints = rand(1,n);
                self.color = [rand rand 0];
                self.lineColor = [1 1 0]-self.color;
                self.highlightColor = [0 1 0];
            else
                % will create rounded rectangle for characters
                self.color = [rand, 0, rand];
                self.lineColor = [1 0 1]-self.color;
                self.highlightColor = [0 0 1];
            end
        end
        
        % Refresh this battler as though new.
        function restoreHp(self)
            self.isDead = false;
            self.hp = self.maxHp;
        end
        
        % Create handle graphics objects for displaying this battler.
        function makeGraphicsForAxesAtPositionWithCallback ...
                (self, ax, position, callback)
            
            xIn = 0.15*position(3);
            yIn = 0.15*position(4);
            inpos = position + [xIn, yIn, -2*xIn, -2*yIn];
            
            if self.isMonster
                % create funky shape for monsters
                self.bodyHandle = patch( ...
                    'Parent', ax, ...
                    'XData', inpos(1) + self.xPoints*inpos(3), ...
                    'YData', inpos(2) + self.yPoints*inpos(4), ...
                    'DisplayName', self.name, ...
                    'FaceColor', self.color, ...
                    'EdgeColor', self.lineColor, ...
                    'LineStyle', ':', ...
                    'LineWidth', 1, ...
                    'ButtonDownFcn', callback, ...
                    'Selected', 'off', ...
                    'SelectionHighlight', 'off', ...
                    'UserData', self, ...
                    'Visible', 'on');
                
            else
                % create rounded rectangle for characters
                self.bodyHandle = rectangle( ...
                    'Parent', ax, ...
                    'Curvature', [.5 .9], ...
                    'DisplayName', self.name, ...
                    'FaceColor', self.color, ...
                    'EdgeColor', self.lineColor, ...
                    'LineStyle', '-', ...
                    'LineWidth', 3, ...
                    'Position', inpos, ...
                    'ButtonDownFcn', callback, ...
                    'Selected', 'off', ...
                    'SelectionHighlight', 'off', ...
                    'UserData', self, ...
                    'Visible', 'on');
            end
            
            self.nameHandle = text( ...
                'Parent', ax, ...
                'BackgroundColor', self.color, ...
                'Color', self.lineColor, ...
                'Position', [inpos(1:2), 0], ...
                'String', self.name, ...
                'HitTest', 'off', ...
                'SelectionHighlight', 'off', ...
                'UserData', self, ...
                'Visible', 'on');
            
            self.damageHandle = text( ...
                'Parent', ax, ...
                'BackgroundColor', [0 0 0], ...
                'Color', [1 1 0], ...
                'Position', [inpos(1), inpos(2)+inpos(4)/2, 0], ...
                'String', '0', ...
                'HitTest', 'off', ...
                'SelectionHighlight', 'off', ...
                'UserData', self, ...
                'Visible', 'off');
        end
        
        % Display a selection highlight for this battler.
        function showHighlight(self)
            if ~self.isDead
                set (self.bodyHandle, ...
                    'FaceColor', self.highlightColor, ...
                    'EdgeColor', self.highlightColor);
            end
        end
        
        % Un-display a selection highlight for this battler.
        function hideHighlight(self)
            if ~self.isDead
                set (self.bodyHandle, ...
                    'FaceColor', self.color, ...
                    'EdgeColor', self.lineColor);
            end
        end
        
        % Deal random damage to another battler.
        function attackOpponent(self, opponent)
            if ~self.isDead
                % do clipped-normal damage
                damage = max(0, normrnd(self.attackMean, self.attackMean/2));
                opponent.takeDamageAndShow(damage);
            end
        end
        
        % Take damage from another battler and display it.
        function takeDamageAndShow(self, damage)
            self.hp = self.hp - damage;
            if self.hp <=0
                self.dieAndShow;
            end
            set(self.damageHandle, ...
                'String', sprintf('%.1f', damage), ...
                'Visible', 'on');
        end
        
        % Un-display damage taken.
        function hideDamage(self)
            set(self.damageHandle, ...
                'String', '0', ...
                'Visible', 'off');
        end
        
        % Let this battler be isDead and display it.
        function dieAndShow(self)
            self.isDead = true;
            
            color = [0 0 0];
            lineColor = [1 1 1];
            set(self.bodyHandle, ...
                'FaceColor', color, ...
                'EdgeColor', lineColor, ...
                'ButtonDownFcn', [], ...
                'Selected', 'off', ...
                'SelectionHighlight', 'off', ...
                'Visible', 'on');
            set(self.nameHandle, ...
                'BackgroundColor', color, ...
                'Color', lineColor, ...
                'Visible', 'on');
            set(self.damageHandle, ...
                'BackgroundColor', color, ...
                'Color', lineColor, ...
                'Visible', 'on');
        end
        
        % Delete the handle graphics for displaying this battler.
        function deleteGraphics(self)
            if ishandle(self.bodyHandle)
                delete(self.bodyHandle);
            end
            if ishandle(self.nameHandle)
                delete(self.nameHandle);
            end
            if ishandle(self.damageHandle)
                delete(self.damageHandle);
            end
        end
        
        % Make a new battler with the same properties as this battler.
        function newCopy = copy(self)
            % copy all fields into a new object
            %   I think "value classes" are dumb
            %   Perhaps copy() should belong to a "copyable" superclass
            newCopy = EncounterBattler;
            meta = metaclass(newCopy);
            props = meta.Properties;
            for ii =1:length(props)
                p = props{ii}.Name;
                v = self.(p);
                if ishandle(v)
                    newCopy.(p) = copyobj(v, get(v, 'Parent'));
                else
                    newCopy.(p) = v;
                end
            end
        end
    end
end