close all
clear

addpath(genpath('crewes/'))

use_TNT = 1
bandpass_y = 1
freq = 100
square_y = 0
normalize_y = 1
pick_new_points_seg3 = 0
cmap_scale = .3
radius = 0.005;  % in degrees; adjust as needed


%% --- Setup and Data Loading ---
if use_TNT == 1

fullpath = 'mine_harris_data/MiningHarrisburgDAS_UTC_20250321_183602.252.h5';
info = h5info(fullpath);
disp(info)
dataset_name = info.Datasets.Name;
data = h5read(fullpath, ['/' dataset_name]);
data2 = data(:,23000:23400);
else

fullpath = 'mine_harris_data/MiningHarrisburgDAS_UTC_20250321_184202.252.h5';
info = h5info(fullpath);
disp(info)
dataset_name = info.Datasets.Name;
data = h5read(fullpath, ['/' dataset_name]);
data2 = data(:,15700:16100);
end

dt = 1/str2num(info.Datasets.Attributes(1).Value);
dx = 1;
t = (1:size(data2,2)) * dt;
x = (1:size(data2,1)) * dx;

%% --- Data Preprocessing ---
% Remove mean from each trace (row) and apply butterband filter
data2 = double(data2);
data2 = data2 - mean(data2, 2);
if bandpass_y ==1
data2 = butterband(data2', t, 0, freq)';
end

if square_y == 1
    data2 = data2.^2;
end
% Normalize each row
if normalize_y  == 1
maxs = max(abs(data2), [], 2);
data2 = data2 ./ maxs;
end

%% --- Extract IDAS Location ---
IDAS_lat = str2double(info.Datasets.Attributes(68).Value);
IDAS_lon = str2double(info.Datasets.Attributes(69).Value);

%% --- Create Basemap ---

fig = figure('Units','inches','Position',[1, 1, 10, 10]);
ax = geoaxes(fig);
geobasemap(ax, 'satellite');  % Set basemap to satellite mode
hold(ax, 'on');

% Define geolimits centered at the IDAS location
latLimits = [IDAS_lat - radius, IDAS_lat + radius];
lonLimits = [IDAS_lon - radius, IDAS_lon + radius];
geolimits(ax, latLimits, lonLimits);

% Plot the IDAS location using a triangle marker.
geoscatter(ax, IDAS_lat, IDAS_lon, 150, 'r', '^', 'filled');
title(ax, sprintf('Satellite Basemap Centered at [%.4f, %.4f]', IDAS_lat, IDAS_lon));

%% --- Define Geometry for Segment 1 (Outgoing Leg) ---
nPoints1 = 115;      % Number of traces in segment 1
spacing = 1;         % Spacing between traces in meters
offsetAngle1 = 250;  % Bearing (degrees from North) for outgoing leg

% Conversion factors (approximate for short distances)
degPerMeter_lat = 1/111320;  
degPerMeter_lon = 1/(111320 * cosd(IDAS_lat));

% Distance vector for seg1 (each trace 1 m apart)
distances1 = (1:nPoints1) * spacing;

% Compute changes in lat and lon for seg1
delta_lat1 = distances1 * degPerMeter_lat * cosd(offsetAngle1);
delta_lon1 = distances1 * degPerMeter_lon * sind(offsetAngle1);

% Coordinates for seg1
seg1_lats = IDAS_lat + delta_lat1;
seg1_lons = IDAS_lon + delta_lon1;

%% --- Define Geometry for Segment 2 (Doubling Back Leg) ---
nPointsTotal = 217;
nPoints2 = nPointsTotal - nPoints1;  % Number of points for seg2

% Set new offset angle for seg2 (exact double-back: offsetAngle1 + 180)
offsetAngle2 = offsetAngle1 + 180;  % adjust as desired

% Distance vector for seg2 (each trace 1 m apart)
distances2 = (1:nPoints2) * spacing;

% Compute changes in lat and lon for seg2
delta_lat2 = distances2 * degPerMeter_lat * cosd(offsetAngle2);
delta_lon2 = distances2 * degPerMeter_lon * sind(offsetAngle2);

% seg2 starts at turning point (last point of seg1)
startLat2 = seg1_lats(end);
startLon2 = seg1_lons(end);

% Coordinates for seg2 (with a small adjustment)
seg2_lats = startLat2 + delta_lat2 + 0.00002;
seg2_lons = startLon2 + delta_lon2;


%% --- Interactive Selection for Segment 3 Key Points ---
if pick_new_points_seg3 ==1
    disp('Click on the map to define key points for segment 3. Press Enter when finished.');
    % Plot seg1 in blue for reference.
    geoscatter(ax, seg1_lats, seg1_lons, 20, 'b', 'filled');
    % Plot seg2 in magenta for reference.
    geoscatter(ax, seg2_lats, seg2_lons, 20, 'm', 'filled');
    
    % Capture key points using ginput (x=longitude, y=latitude in geoaxes)
    [key_lons, key_lats] = ginput;  %#ok<GNP1>
    if isempty(key_lats)
        error('No key points selected for seg3.');
    end
    
    % Plot key points for visual feedback (cyan circles)
    geoscatter(ax, key_lats, key_lons, 100, 'c', 'filled');
    
    spacing_m = 1;  % Desired spacing in meters
    
    % Preallocate arrays for seg3 coordinates
    seg3_lats = [];
    seg3_lons = [];
    for k = 1:length(key_lats)-1
        % Starting and ending key points
        pt1_lat = key_lats(k);  pt1_lon = key_lons(k);
        pt2_lat = key_lats(k+1);  pt2_lon = key_lons(k+1);
        
        % Average latitude for conversion factor
        avgLat = (pt1_lat + pt2_lat) / 2;
        degPerMeter_lon_seg = 1/(111320 * cosd(avgLat));
        
        % Differences (in degrees)
        dlat = pt2_lat - pt1_lat;
        dlon = pt2_lon - pt1_lon;
        
        % Approximate distance in meters
        dist_lat = abs(dlat) / degPerMeter_lat;
        dist_lon = abs(dlon) / degPerMeter_lon_seg;
        dist_m = sqrt(dist_lat^2 + dist_lon^2);
        
        % Number of interpolation points (at least two)
        n_interp = ceil(dist_m / spacing_m) + 1;
        
        % Linear interpolation between the key points
        interp_lats = linspace(pt1_lat, pt2_lat, n_interp);
        interp_lons = linspace(pt1_lon, pt2_lon, n_interp);
        
        % Append interpolation points (avoiding duplicate endpoints)
        if k < length(key_lats)-1
            seg3_lats = [seg3_lats, interp_lats(1:end-1)]; %#ok<AGROW>
            seg3_lons = [seg3_lons, interp_lons(1:end-1)]; %#ok<AGROW>
        else
            seg3_lats = [seg3_lats, interp_lats];
            seg3_lons = [seg3_lons, interp_lons];
        end
        save('Segment_3_lats.mat','seg3_lats')
        save('Segment_3_lons.mat','seg3_lons')    
    end
    else
        load('Segment_3_lats.mat');
        load('Segment_3_lons.mat');
end


%% --- Combine All Segments into One Set of Coordinates ---
all_lats = [seg1_lats, seg2_lats, seg3_lats];
all_lons = [seg1_lons, seg2_lons, seg3_lons];

%% --- Plot the Entire Fiber Path on the Basemap ---
% Plot seg3 (user-defined part) in green.
geoscatter(ax, seg3_lons, seg3_lats, 20, 'g', 'filled');
% Mark turning point between seg1 and seg2.
geoscatter(ax, seg1_lats(end), seg1_lons(end), 150, 'k', 'p', 'filled');
total = numel(seg1_lats) + numel(seg2_lats) + numel(seg3_lats);

%% --- Create a New Figure for Data and Map Panels ---
% Adjust the merge for the final figure as per your fix:
total_lats = [seg1_lats, seg2_lats, seg3_lons];
total_lons = [seg1_lons, seg2_lons, seg3_lats];
close
fig2 = figure('Units','inches','Position',[1, 1, 10, 10],'Color', 'w');

% --- Left Panel: DAS Data ---
ax_data = subplot(1,3,1);
set(ax_data, 'Color', 'w'); % 确保坐标轴背景为白
h_img = imagesc(t,x,data2);
caxis( [-1 1] * max(data2,[],'all') * cmap_scale);
axis(ax_data, 'tight')
xlabel('Time sample')
ylabel('Channel')
title('DAS Data')
hold(ax_data, 'on');
h_vline = xline(ax_data, 1, 'r', 'LineWidth', 2);
nnn = numel(total_lats);
yline(ax_data, nnn)
yline(ax_data, 115)
yline(ax_data, 217)

% --- Right Panel: Map with Scatter Points ---
% Create geoaxes manually in the right two-thirds.
ax_map = geoaxes('Parent',fig2, 'Units','normalized', 'Position',[0.38, 0.1, 0.57, 0.8]);
geobasemap(ax_map, 'satellite');
hold(ax_map, 'on');
geolimits(ax_map, latLimits, lonLimits);
h_scatter = geoscatter(ax_map, total_lats, total_lons, 20, data2(1:nnn,1), 'filled');
% (Optional: Uncomment the next line to plot the connecting fiber path.)
% geoplot(ax_map, total_lats, total_lons, 'g-', 'LineWidth', 2);

%% --- Animation Loop ---
for tt = 1:size(data2,2)
    % Update DAS data panel: move the vertical line.
    h_vline.Value = tt*dt;
    
    % Update map panel scatter: update color data based on current amplitude.
    ampVals = data2(1:nnn, tt);
    h_scatter.CData = ampVals;
    
    % Optionally update the color axis range.
    caxis(ax_map, [-1 1] * max(data2,[],'all') * cmap_scale);
    
    pause(0.01)
end

