classdef battler < handle
    %Class to represent character or monster in the "encounter" game
    
    properties (SetObservable)
        name = 'nameless';
        hp = 1;
        maxHp = 1;
    end
    
    properties (Hidden)
        isMonster = false;
        isDead = false;
        
        attackInterval = 1;
        attackMean = 1;
        
        color;
        lineColor;
        xPoints;
        yPoints;
        
        bodyHandle;
        nameHandle;
        damageHandle;
    end
    
    methods
        function self = battler(isMonster)
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
            else
                % will create rounded rectangle for characters
                self.color = [rand, 0, rand];
                self.lineColor = [1 0 1]-self.color;
            end
        end
        
        function restoreHp(self)
            self.isDead = false;
            self.hp = self.maxHp;
        end
        
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
                    'SelectionHighlight', 'on', ...
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
                    'SelectionHighlight', 'on', ...
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
                'Position', [inpos(1), inpos(2)+inpos(4), 0], ...
                'String', '0', ...
                'HitTest', 'off', ...
                'SelectionHighlight', 'off', ...
                'UserData', self, ...
                'Visible', 'off');
        end
        
        function attackOpponent(self, opponent)
            % do clipped-normal damage
            damage = max(0, normrnd(self.attackMean, self.attackMean/2));
            opponent.takeDamageAndShow(damage);
        end
        
        function takeDamageAndShow(self, damage)
            self.hp = self.hp - damage;
            if self.hp <=0
                self.dieAndShow;
            end
            set(self.damageHandle, ...
                'String', sprintf('%.1f', damage), ...
                'Visible', 'on');
        end
        
        function hideDamage(self)
            set(self.damageHandle, ...
                'String', '0', ...
                'Visible', 'off');
        end
        
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
        
        function newCopy = copy(self)
            % copy all fields into a new object
            %   I think "value classes" are dumb
            %   Perhaps copy() should belong to a "copyable" superclass
            newCopy = battler;
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