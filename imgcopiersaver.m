function imgcopiersaver(inputFolder, outputFolder, numCopies, baseFilename)
    % PROCESS_TIF_IMAGES Processes TIFF images by copying and renaming them.
    %
    % Args:
    %   inputFolder (string): Path to the folder containing subfolders with .tif images.
    %   outputFolder (string): Path to the folder where processed images will be saved.
    %   numCopies (double): Number of copies to create for each image.
    %   baseFilename (string): Common base filename for all processed images.

    % Ensure output folder exists
    if ~isfolder(outputFolder)
        mkdir(outputFolder);
    end

    % Get list of all .tif files in input folder and subfolders
    tifFiles = dir(fullfile(inputFolder, '**', '*.tif'));

    if isempty(tifFiles)
        error('No TIFF files found in the input folder or its subfolders.');
    end

    % Process each .tif file
    for fileIdx = 1:length(tifFiles)
        % Read the full path of the current .tif file
        inputFile = fullfile(tifFiles(fileIdx).folder, tifFiles(fileIdx).name);

        % Create copies with sequential numbering
        for copyIdx = 0:(numCopies - 1)
            % Generate the new filename
            newFilename = sprintf('%s_%02d.tif', baseFilename, (fileIdx - 1) * numCopies + copyIdx); %FLAG: leading zeros should be smart to account for the max # of frames
            outputFile = fullfile(outputFolder, newFilename);

            % Only create images with the 3 RGB channels
            if copyIdx==0
                importimg=imread(inputFile);
                newimg=importimg(:,:,1:3); % Only take the first 3 channels for RGB
                imwrite(im2uint16(newimg), outputFile);

                extracopies=outputFile; % New target for imgs to be copied from
                % clear importimg, newimg
            else
                % Copy the file more efficiently than opening it every time
                copyfile(extracopies, outputFile);
            end
        end
    end

    fprintf('Processed %d TIFF files and created %d copies each.\n', length(tifFiles), numCopies);
end
