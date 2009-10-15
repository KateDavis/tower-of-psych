function t = topsTimer
%Private instance of tic-toc for use by tops classes
%
%   t = topsTimer
%
%   t returns a "toc" value from a private instance of Matlab's tic-toc
%   stopwatch.
%
%   See also, tic, toc, now, cputime

% 2009 benjamin.heasly@gmail.com

% I'd like to just use the builtin @now as my timer, but this returns very
% large values, in units of days.  The days are not necessarily a problem
% since tops is supposed to handle any timer function.  But the very large
% values cause Matlab to to idiotic plotting.  In some cases it will ignore
% 'YLim' axes values that I set and instead squish my plots.  What a POS.

persistent topsTic
if isempty(topsTic)
    topsTic = tic;
end
t = toc(topsTic);