% Colormap with bold Earth tones.
%
%   colors = puebloColors(n)
%
%   @param n the length of colormap to build
%
%   @details
%   Returns an nX3 colormap whose rows are RGB colors in the range 0-1.
%
%   The "Pueblo" colors were inspired by the art work in Gerald McDermott's
%   book Arrow to the Sun (http://en.wikipedia.org/wiki/Arrow_to_the_Sun).
%
%   Here's a demo:
%   n = 19;
%   colormap([puebloColors(n); 0 0 0]);
%   thingy = n+1*ones(1, 2*n+1);
%   thingy(2:2:2*n) = 1:n;
%   image(thingy);
%
%   See also colormap colorcube
%   @ingroup utilities
function colors = puebloColors(n)

if nargin < 1
    n = size(get(gcf,'colormap'),1);
end

% various colors identified in Arrow the the Sun
baseColors = [ ...
    206 1 1; ... % arrowmaker red
    146 165 33; ... % cactus green
    44 192 242; ... % morning blue
    236 76 150; ... % frosting pink
    49 214 85; ... % scrub green
    154 50 31; ... % rust brown
    238 86 25; ... % sunset orange
    254 255 36; ... % sun yellow
    251 178 64; ... % sand bronze
    ];

nBaseColors = size(baseColors, 1);
rows = 1 + mod(0:(n-1), nBaseColors);
colors = baseColors(rows,:) ./ 255;