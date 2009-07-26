function subpos = subposition(position, r, c, ii, jj)
%Position of sub-region of given [x,y,w,h] rectangle
%
%   subpos = subposition(position, r, c, ii, jj)
%
%   subposition is similar to the builtin subplot, but it operates on
%   position rectangles of the form [x,y,w,h], rather than figures and
%   axes.  subpos is the rectangle found by dividing the given rectangle
%   into r rows and c columns and taking the iith row and jjth column.
%
%   p = [0 0 1 1];
%   isequal([0 0 .1 .1],    subposition(p, 10, 10, 1, 1))
%   isequal([.9 .9 .1 .1],  subposition(p, 10, 10, 10, 10))
%   isequal([0 .9 .1 .1],   subposition(p, 10, 10, 10, 1))
%   isequal([.9 0 .1 .1],   subposition(p, 10, 10, 1, 10))
%
%   See also: subplot

% 2009 benjamin.heasly@gmail.com
%   Seattle, WA
w = position(3)/c;
h = position(4)/r;
subpos = [position(1)+(jj-1)*w, position(2)+(ii-1)*h, w, h];