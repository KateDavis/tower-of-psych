classdef topsFile
    % @class topsFile
    % Utility to organize incremental reading and writing of data.
    % @details
    % topsFile facilitates writing data to a single file, incrementally,
    % over time.  It keeps track of data increments themeselves as well as
    % metadata related to which increments have already been written.  It
    % also facilitates reading incremental data and keeps track of which
    % increments have already been read out.
    % @details
    % topsFile is suitable for sharing data (such as topsDataLog data)
    % between separate instance of Matlab running on the same machine.
    % Each Matlab instance should be able to write data increments and read
    % in increments that were written by the other.  topsFile attempts to
    % prevent data corruption due to poorly timed access by saving data and
    % metadata separately, and using metadata to coordinate file access.
    % @deatils
    % Note that topsFile objects are not handle objects, and topsFile
    % objects themselves are not returned directly.  Instead, the
    % newTopsFileHeader() methods returns a struct with fields that match
    % the properties of the topsFile class, and other topsFile methods
    % expect to work with these "header" structs.  This pattern
    % faciliitates writing and reading of header meta data to file.  It
    % also makes explicit the idea that topsFile objects represent data on
    % the hard disk, and should not themselves contain much data or
    % maintain much internal state.
    % @ingroup utilities
    
    properties
        % string name of the file to read from and write to
        fileName = 'topsFileData.mat';
        
        % string path to the file to read from and write to
        filePath = '';
        
        % string prefix to use for identifying data increments
        incrementPrefix = 'topsFileIncrement';
        
        % function handle for getting the current date-and-time as a number
        dateTimeFunction = @now;
        
        % format string to use with Matlab's builtin datestr()
        datestrFormat = 'yyyymmddTHHMMSSPFFF';
        
        % array of date-and-time numbers for previously written data
        % increments
        writtenIncrements = [];
        
        % array of date-and-time numbers for previously read data
        % increments
        readIncrements = [];
        
        % any external data to be stored with the header metadata
        userData = [];
    end
    
    methods (Access = private)
        function fObj = topsFile
        end
        
        % Convert a topsFile object to an equivalent struct.
        function fHeader = toStruct(fObj)
            warning('off', 'MATLAB:structOnObject');
            fHeader = struct(fObj);
        end
    end
    
    methods (Static)
        % Create a header struct with fields that match the properties of
        % the topsFile class.
        % @param varargin optional property-value pairs to assign to the
        % new header.
        % @details
        % Use this method instead of the topsFile constructor.
        % @details
        % Returns a header struct with fields and default values that match
        % those of the topsFile class.  @a varargin may contain pairs of
        % property names and values to be assigned to the new struct.
        function fHeader = newTopsFileHeader(varargin)
            fObj = topsFile;
            for ii = 1:2:length(varargin)
                fObj.(varargin{ii}) = varargin{ii+1};
            end
            fHeader = fObj.toStruct;
        end
        
        % Read any new data increments from a topsFile.
        % @param fHeader a topsFile header struct as returned from
        % newTopsFileHeader().
        % @param increments optional array of date-and-time numbers
        % identifying data increments to read or re-read from the topsFile
        % @details
        % Uses @a fHeader to locate a topsFile on disk.  If the file
        % exists and contains topsFile header metadata, loads the
        % metadata from disk and updates @a fHeader to match.  Returns the
        % updated @a fHeader
        % @details
        % Also returns a cell array containing any data increments that
        % have not yet been read from disk.  These increments correspond to
        % values in @a fHeader.writtenIncrements that are not yet present
        % in @a fHeader.readIncrements.
        % @details
        % If @a increments is provided, attempts to read or re-read the
        % specified data increments from the topsFile.  Returns a cell
        % array with the same size as @a increments.  Where the specified
        % @a increments are not present in the topsFile, the returned cell
        % array will be empty.  Using read() in this way will not affect @a
        % fHeader.readIncrements, or subsequent calls to read().
        function [fHeader, incrementCell] = read(fHeader, increments)
            fileWithPath = fullfile(fHeader.filePath, fHeader.fileName);
            incrementCell = {};
            if exist(fileWithPath)
                contents = who('-file', fileWithPath);
                if any(strcmp(contents, 'fHeader'))
                    s = load(fileWithPath, 'fHeader');
                    % match most of the metadata from the disk
                    fHeader.incrementPrefix = s.fHeader.incrementPrefix;
                    fHeader.dateTimeFunction = s.fHeader.dateTimeFunction;
                    fHeader.datestrFormat = s.fHeader.datestrFormat;
                    fHeader.writtenIncrements = s.fHeader.writtenIncrements;
                    fHeader.userData = s.fHeader.userData;
                    
                    if nargin < 2
                        % choose increments that were written
                        %   but not yet read
                        increments = setdiff( ...
                            fHeader.writtenIncrements, ...
                            fHeader.readIncrements);
                        
                        % now all increments will have been read
                        fHeader.readIncrements = ...
                            fHeader.writtenIncrements;
                    end
                    
                    % actually read increments from the file
                    nIncrements = numel(increments);
                    incrementNames = topsFile.incrementNamesFromNumbers( ...
                        fHeader, increments);
                    incrementCell = cell(1,nIncrements);
                    for ii = 1:nIncrements
                        name = incrementNames(ii,:);
                        if any(strcmp(contents, name))
                            s = load(fileWithPath, name);
                            incrementCell{ii} = s.(name);
                        end
                    end
                    
                else
                    warning('%s: "%s" has no topsFile metadata', ...
                        mfilename, fileWithPath);
                end
            else
                warning('%s: "%s" does not exist()', ...
                    mfilename, fileWithPath);
            end
        end
        
        % Write a new data increment to a topsFile.
        % @param fHeader a topsFile header struct as returned from
        % newTopsFileHeader().
        % @param newIncrement any data increment to append to the topsFile
        % @details
        % If @a newIncrement is provided, appends the @a newIncrement to
        % the topsFile on disk, then updates the hjeader metadata on disk.
        % If a@ newIncrement is omitted, only writes header metadata
        % to disk.  If the topsFile doesn't already exist on disk, creates
        % the new file first.
        % @details
        % Since write() updates header metadata only after writing the new
        % increment data, concurrent read() calls, such as from a separate
        % Matlab instance, should be able to safely ignore increment data
        % that's in the process of being written.
        % @details
        % Returns @a fHeader, which may have been modified with new
        % metadata.
        function fHeader = write(fHeader, newIncrement)
            fileWithPath = fullfile(fHeader.filePath, fHeader.fileName);
            
            if ~exist(fileWithPath)
                % create the file
                save(fileWithPath, 'fHeader');
            end
            
            if nargin > 1
                % new data increment to append
                incrementTime = feval(fHeader.dateTimeFunction);
                incrementName = topsFile.incrementNamesFromNumbers( ...
                    fHeader, incrementTime);
                s = struct(incrementName, {newIncrement});
                save(fileWithPath, incrementName, '-append', ...
                    '-struct', 's', incrementName);
                fHeader.writtenIncrements(end+1) = incrementTime;
            end
            
            % update header data only after the increments were written
            %   let concurrent read() calls ignore increments as they are
            %   being written
            save(fileWithPath, 'fHeader', '-append');
        end
        
        % Get data increment names from date-and-time numbers.
        function names = incrementNamesFromNumbers(fHeader, numbers)
            n = numel(numbers);
            dateStrings = datestr(numbers, fHeader.datestrFormat);
            prefixes = repmat(fHeader.incrementPrefix, n, 1);
            names = cat(2, prefixes, dateStrings);
        end
    end
end