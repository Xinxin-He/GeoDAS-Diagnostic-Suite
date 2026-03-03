close all
clear

fullpath = 'mine_harris_data/MiningHarrisburgDAS_UTC_20250321_183602.252.h5';
% fullpath = 'mine_harris_data/MiningHarrisburgDAS_UTC_20250321_184202.252.h5';

addpath(genpath('crewes/'))

info = h5info(fullpath);
disp(info)

% Create a figure with dimensions 10 inches by 10 inches
figure('Units', 'inches', 'Position', [1, 1, 10, 10]);

% Get dataset name from the 'info' struct and read data
dataset_name = info.Datasets.Name;
data = h5read(fullpath, ['/' dataset_name]);
% data2 = data(:,15700:16100);
data2 = data(:,23000:23400);


% Time and spatial axes
dt = 1/str2num(info.Datasets.Attributes(1).Value);
dx = 1;
t = (1:size(data2,2)) * dt;
x = (1:size(data2,1)) * dx;

% Remove mean from each trace (row) and apply butterband filter
data2 = double(data2);
data2 = data2 - mean(data2, 2);
data2 = butterband(data2', t, 0, 100)';

% Normalize each row
maxs = max(abs(data2), [], 2);
norm_data = data2 ./ maxs;

%% --- STEP 1: Manual picking on trace 115 ---
plot(t, norm_data(115,:), 'k', 'LineWidth', 2);
xlabel('Time (s)');
ylabel('Amplitude');
title('Manually pick first arrival on trace 115');
[manualX, ~] = ginput(1);  % User clicks on the plot to pick the first arrival
manualArrival = manualX;
fprintf('Manual pick for trace 115: %f s\n', manualArrival);

%% --- STEP 2: Grid search for STA/LTA parameters using trace 115 ---
% Define grid ranges for STA/LTA parameters (in samples)
shortRange = 5:1:19;      % short window lengths
longRange = 21:1:100;     % long window lengths
misfit = zeros(length(shortRange), length(longRange));

trace115 = norm_data(115,:)';

for i = 1:length(shortRange)
    for j = 1:length(longRange)
         predArrival = simple_sta_lta(trace115, shortRange(i), longRange(j), dt);
         misfit(i,j) = abs(predArrival - manualArrival).^3;
    end
end

% Plot misfit matrix
figure;
imagesc(longRange, shortRange, misfit);
xlabel('Long window length (samples)');
ylabel('Short window length (samples)');
title('Misfit between STA/LTA pick and manual pick on trace 115');
colorbar;
set(gca, 'ColorScale', 'log');  % Set color scaling to logarithmic
% caxis([0 .1]*max(misfit,[],'all'))
axis xy  % Ensure the y-axis increases upward

disp('Please select the optimal parameters by clicking on the misfit plot');
[x_pick, y_pick] = ginput(1);
[~, j_opt] = min(abs(longRange - x_pick));
[~, i_opt] = min(abs(shortRange - y_pick));
optShort = shortRange(i_opt);
optLong = longRange(j_opt);
fprintf('Optimal parameters selected: short window = %d, long window = %d\n', optShort, optLong);

%% --- Additional plotting for STA/LTA verification on trace 115 ---
% Using the optimal parameters, compute STA, LTA, and ratio for trace 115
signal = trace115;
shortWindow = optShort;
longWindow = optLong;
abs_signal = abs(signal);
sta = filter(ones(shortWindow,1)/shortWindow, 1, abs_signal);
lta = filter(ones(longWindow,1)/longWindow, 1, abs_signal);
ratio = sta ./ (lta + eps);

% Compute the detected arrival time for trace 115 using STA/LTA
detectedArrival = simple_sta_lta(trace115, optShort, optLong, dt);

figure;
subplot(3,1,1)
plot(t, signal, 'k', 'LineWidth', 2);
xlabel('Time (s)');
ylabel('Amplitude');
title('Trace 115 Signal');

subplot(3,1,2)
plot(t, sta, 'b', 'LineWidth', 2);
hold on;
plot(t, lta, 'r', 'LineWidth', 2);
legend('STA', 'LTA');
xlabel('Time (s)');
ylabel('Amplitude');
title(sprintf('STA (blue) and LTA (red) using short=%d, long=%d', optShort, optLong));

subplot(3,1,3)
plot(t, ratio, 'm', 'LineWidth', 2);
xlabel('Time (s)');
ylabel('STA/LTA Ratio');
title('STA/LTA Ratio for Trace 115');
hold on;
% Mark the detected arrival with a vertical dashed line
xline(detectedArrival, 'k--', 'LineWidth', 2);
legend('STA/LTA Ratio', 'Detected Arrival');

%% --- STEP 3: Apply STA/LTA with optimal parameters to all traces ---
nTraces = size(norm_data, 1);
arrivalTimes = zeros(nTraces,1);
for i = 1:nTraces
    arrivalTimes(i) = simple_sta_lta(norm_data(i,:)', optShort, optLong, dt);
end

%% --- STEP 4: Plot final results with STA/LTA picks ---
figure('Units', 'inches', 'Position', [1, 1, 10, 10]);
subplot(1,2,1);
imagesc(t, x, norm_data);
xlabel('Time (s)');
ylabel('Trace number');
title('Normalized Data with STA/LTA First Arrival Picks');
hold on;
% Overlay STA/LTA picks as scatter points (x: arrival time, y: trace number)
scatter(arrivalTimes, x, 30, 'k', 'filled');
colorbar;
ylim([0 300])

subplot(1,2,2);
% Plot trace 115 with both manual and STA/LTA picks indicated
plot(t, norm_data(115,:), 'k', 'LineWidth', 2);
hold on;
[~, manualIdx] = min(abs(t - manualArrival));
plot(manualArrival, norm_data(115, manualIdx), 'ro', 'MarkerSize', 10, 'LineWidth', 2);
[~, staIdx] = min(abs(t - arrivalTimes(115)));
plot(arrivalTimes(115), norm_data(115, staIdx), 'bs', 'MarkerSize', 10, 'LineWidth', 2);
legend('Trace 115','Manual Pick','STA/LTA Pick');
xlabel('Time (s)');
ylabel('Amplitude');
title('Trace 115 First Arrival Picks');
xlim([0 0.25]);
ylim([-2 2]);

function arrivalTime = simple_sta_lta(signal, shortWindow, longWindow, dt)
    % Ensure the signal is a column vector
    signal = signal(:);
    % Compute the absolute value of the signal
    abs_signal = abs(signal);
    % Compute short-term average (STA) using a moving average filter
    sta = filter(ones(shortWindow,1)/shortWindow, 1, abs_signal);
    % Compute long-term average (LTA) using a moving average filter
    lta = filter(ones(longWindow,1)/longWindow, 1, abs_signal);
    % Compute the ratio (avoid division by zero with eps)
    ratio = sta ./ (lta + eps);
    % Force the pick to occur after the LTA window length
    ratio(1:longWindow) = 0;
    % Find the index where the ratio is maximum (assumed first arrival)
    [~, idx] = max(ratio);
    arrivalTime = idx * dt;
end


