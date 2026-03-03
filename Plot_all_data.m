close all
clear

names = dir('mine_harris_data/');

for n = 1:numel(names)
    % Skip if it's a directory or doesn't start with 'Min'
    if names(n).isdir || ~startsWith(names(n).name, 'Min')
        continue
    end

    fullpath = fullfile('mine_harris_data/', names(n).name);
    disp(fullpath)
    
    try
        info = h5info(fullpath);
        disp(info)

        % Get dataset name from the 'info' struct
        dataset_name = info.Datasets.Name;

        % Now read the data
        data = h5read(fullpath, ['/' dataset_name]);

        imagesc(data(1:300,:))
        pause()

    catch ME
        warning("Could not read file %s\nReason: %s", names(n).name, ME.message)
    end
end

% good data
% ../mine_harris/MiningHarrisburgDAS_UTC_20250321_183602.252.h5
% ../mine_harris/MiningHarrisburgDAS_UTC_20250321_184202.252.h5
