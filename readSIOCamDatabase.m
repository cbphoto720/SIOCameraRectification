function returnData = readSIOCamDatabase(Path_to_SIO_CamDatabase, options)
%% Import the entire database file OR data from a specific camera!
% Output:
% ----------------
%   If you choose not to specify any options:
%       - ReturnData (table)        :   The entire SIO Camera Database files, complete with 
%                                       camera Coordinates, intrinsics, poses, and the local origins
%   
%
%   Default output when input options are specified:
%       - ReturnData (struct)       :   Camera coordinates, intrinsics, pose, and the local origin
%           -> ReturnData,ReturnData.Intrinsics, ReturnData.Pose, ReturnData.LocalOrigin
%   Output with "Tablemode=true" argument:
%       - ReturnData (table)        :   Camera coordinates, intrinsics, pose, and the local origin
%
% Input Arguments:
% ----------------
%       - Path_to_SIO_CamDatabase (string)  :   Full path to the SIO Camera Database file.
%
%   If you want to specify a DateofGCP, CamSN, or CamNickname by
%   using the one or all of following optional input args:
%       - CamSN (numeric)           : Camera serial number
%       - CamNickname (string)      : Camera nickname
%       - DateofGCP (datetime/string)    : Date in 'YYYYMMDD' format or datetime of the last GCP survey for this site
%       - Tablemode (logical)       :   Change export mode from Struct to table
%      
%   **  If you aren't specific enough, you will be asked to provide more
%       keywords because there are multiple entries matching your information.
%
%   **  It is highly likely you will need to include the DateofGCP in order to
%       nail down a specific database entry.  If you don't know the DateofGCP,
%       either look in the Database, or specify what you do know and the
%       error function will give you multiple results you can pick from.
%
%   **  Use tablemode to return all rows that fit your criteria.  (useful
%       for all cams on 1 survey date, or all dates a specific CamSN was surveyed)
%
%
% Examples: 
% ----------------
%       - FullDatabaseTable (table) = readSIOCamDatabase(Path_to_SIO_CamDatabase)
%       - SeacliffCamA (struct) = readSIOCamDatabase(Path_to_SIO_CamDatabase,DateofGCP=20250122,CamSN=21217396)
%           -> SeacliffCamA,SeacliffCamA.Intrinsics, SeacliffCamA.Pose, SeacliffCamA.LocalOrigin
%       - SecliffCamA (table) = readSIOCamDatabase(Path_to_SIO_CamDatabase,DateofGCP=20250122,CamSN=21217396,Tablemode=true)
%           -> A table view of a specific camera
%       - SecliffCamA (table) = readSIOCamDatabase(Path_to_SIO_CamDatabase,DateofGCP=20250122,Tablemode=true)
%           -> A table of all cameras that were surveyed on the given date
%
% Written by Carson Black 20240214
arguments
    Path_to_SIO_CamDatabase (1,1) string {mustBeValidFile}
    options.CamSN (1,1) {mustBeNumeric} = getDefaultOptions().CamSN;
    options.CamNickname (1,1) {mustBeText} = getDefaultOptions().CamNickname;
    options.DateofGCP (1,1) {mustBeValidDate} = getDefaultOptions().DateofGCP;
    options.Tablemode (1,1) {mustBeNumericOrLogical} = getDefaultOptions().Tablemode;
end

%% Set up the Import Options and import the data
if isnumeric(options.DateofGCP)
    options.DateofGCP=datetime(options.DateofGCP,"ConvertFrom","yyyyMMdd");
elseif isstring(options.DateofGCP) || ischar(options.DateofGCP)
    options.DateofGCP=datetime(options.DateofGCP,"Format","yyyyMMdd");
end

opts = delimitedTextImportOptions("NumVariables", 25);

% Specify range and delimiter
opts.DataLines = [2 Inf];
opts.Delimiter = "\t";

% Specify column names and types
opts.VariableNames = ["CamSN", "CamNickname", "DateofGCP", "Northings", "Eastings", "Height", "UTMzone", "ac", "c0U", "c0V", "fx", "fy", "d1", "d2", "d3", "t1", "t2", "NU", "NV", "pitch", "roll", "azimuth", "originUTMnorthing", "originUTMeasting", "theta"];
opts.VariableTypes = ["double", "string", "datetime", "double", "double", "double", "double", "double", "double", "double", "double", "double", "double", "double", "double", "double", "double", "double", "double", "string", "string", "string", "string", "string", "string"];

% Specify file level properties
opts.ExtraColumnsRule = "ignore";
opts.EmptyLineRule = "read";

% Specify variable properties
opts = setvaropts(opts, ["CamNickname", "pitch", "roll", "azimuth", "originUTMnorthing", "originUTMeasting", "theta"], "WhitespaceRule", "preserve");
opts = setvaropts(opts, ["CamNickname", "pitch", "roll", "azimuth", "originUTMnorthing", "originUTMeasting", "theta"], "EmptyFieldRule", "auto");
opts = setvaropts(opts, "DateofGCP", "InputFormat", "yyyyMMdd", "DatetimeFormat", "preserveinput");

% Import the data
DBtable = readtable(Path_to_SIO_CamDatabase, opts);

%% Determine what the user wants as output

% Get default options
defaults = getDefaultOptions();

% Store logical differences in an array
diffFlags = [ ...
    options.CamSN ~= defaults.CamSN, ...
    options.CamNickname ~= defaults.CamNickname, ...
    options.DateofGCP ~= defaults.DateofGCP ...
];
isTablemodeDifferent = options.Tablemode ~= defaults.Tablemode;

% Determine which case applies
if ~any(diffFlags) && ~isTablemodeDifferent % Program Default
    returnData=DBtable;
elseif ~any(diffFlags) && isTablemodeDifferent % User really likes tables
    returnData=DBtable;    
else % User has tried to specify a Camera, Let's find it!
    % Extract field names where the user provided a value
    fieldNames = fieldnames(options);
    idx = find(strcmp(fieldNames, 'Tablemode'));
    fieldNames(idx)=[]; % Delete tablemode for the database search
    selectedFields = fieldNames(diffFlags);

    % Construct filtering conditions dynamically
    filterMask = true(height(DBtable),1); % Start with all rows included
    for i = 1:numel(selectedFields)
        fieldName = selectedFields{i}; % Extract string from cell
        filterMask = filterMask & (DBtable.(fieldName) == options.(fieldName));
    end

    % Apply filter to the table
    Potentialvals = DBtable(filterMask, :);
    
    if(height(Potentialvals)>1) && options.Tablemode==true % if the user wants a table, give them a table of all searches
        returnData=Potentialvals;
    elseif (height(Potentialvals)>1) && options.Tablemode==false % if not in Tablemode, error out to 1 camera
        for i = 1:height(Potentialvals)
            % Display in a more readable format
            fprintf('CamSN: %d, CamNickname: %s, DateofGCP: %s\n', ...
                Potentialvals.CamSN(i), ...
                Potentialvals.CamNickname{i}, ...
                string(Potentialvals.DateofGCP(i)) ...
            );
        end

        Error('Multiple camera entries found.  Please specify more arguments to pick 1 camera')
    elseif (height(Potentialvals)==1) && options.Tablemode==false
        returnData=Potentialvals; %WIP: Struct is WIP
    end
    
    % If no matches were found, notify the user
    if isempty(Potentialvals)
        warning('No matching cameras found in the database.');
    end
end



end


%ᐠ⸜ˎ_ˏ⸝^⸜ˎ_ˏ⸝^⸜ˎ_ˏ⸝ᐟᐠ⸜ˎ_ˏ⸝^⸜ˎ_ˏ⸝^⸜ˎ_ˏ⸝ᐟᐠ⸜ˎ_ˏ⸝^⸜ˎ_ˏ⸝^⸜ˎ_ˏ⸝ᐟᐠ⸜ˎ_ˏ⸝^⸜ˎ_ˏ⸝^⸜ˎ_ˏ⸝ᐟᐠ⸜ˎ_ˏ⸝ᐟᐠ
% Internal Functions

function defaults = getDefaultOptions()
    defaults = struct( ...
        'CamSN', 0, ...
        'CamNickname', "", ...
        'DateofGCP', datetime(0,1,1), ... %datime for NaT (like NaN but Not a datetime)
        'Tablemode', false ...
    );
end

function mustBeValidFile(filePath)
    if ~isfile(filePath)
        error("The input must be a valid file.");
    end
end

% Custom validation function to check if input is a valid date.
function mustBeValidDate(dateInput) 
    if ischar(dateInput) || isstring (dateInput) %try to convert to double
        dateInput=str2double(dateInput);
    end

    if isa(dateInput, "datetime")
        % If it's a datetime, it's valid.
        return;
    elseif isnumeric(dateInput) && isscalar(dateInput)
        try datetime(dateInput,"ConvertFrom",'yyyymmdd');
            return
        catch
            error('Could not convert numeric input to datetime.  Please use YYYYMMDD format');
        end
    else % if nothing else
        error("mustBeValidDate:InvalidInput", "Input must be a datetime or a numeric date in YYYYMMDD format.");
    end
end
