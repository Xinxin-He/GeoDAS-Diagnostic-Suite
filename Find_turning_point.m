close all
clear

fullpath = 'mine_harris_data/MiningHarrisburgDAS_UTC_20250321_183602.252.h5'; % TNT
% fullpath = 'mine_harris_data/MiningHarrisburgDAS_UTC_20250321_184202.252.h5'; % CO2

addpath(genpath('crewes/'))

info = h5info(fullpath);
disp(info)

% Create a figure with dimensions 10 inches by 10 inches
figure('Units', 'inches', 'Position', [1, 1, 10, 10]);

% Get dataset name from the 'info' struct and read data
dataset_name = info.Datasets.Name;
data = h5read(fullpath, ['/' dataset_name]);
% data2 = data(:,15700:16100); % CO2
data2 = data(:,23000:23400); % TNT


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



%% --- Existing visualization loop (if still needed) ---
phaseShiftDeg = 0;                % Define the desired phase shift in degrees.
phi = deg2rad(phaseShiftDeg);       % Convert to radians.
corrs = zeros(114,1);             % Pre-allocate an array to store correlation coefficients

ref1 = 115
ref2 = 116
for s = 1:114
    % Plot the full normalized data with horizontal lines indicating the two traces
    subplot(3,2,[1 3])
    imagesc(t, x, norm_data)
    yline(115-s, 'b')
    yline(115+s, 'r')
    
    % Compute the phase-shifted version of trace 115+s using the Hilbert transform and arbitrary phase shift.
    shiftedTrace = real(hilbert(norm_data(ref2+s,:)) * exp(1i * phi));
    
    % Plot the two selected traces for comparison
    subplot(3,2,[2 4])
    hold off
    plot(t, norm_data(ref1-s,:), 'b', 'LineWidth', 2)
    hold on
    plot(t, shiftedTrace, 'r', 'LineWidth', 2)
    xlim([0 0.3])
    ylim([-2 2])
    
    % Calculate the zero-lag correlation coefficient between trace 115-s and the phase-shifted trace 115+s
    r = corrcoef(norm_data(ref1-s,:), shiftedTrace);
    corr_coeff = r(1,2);  % Extract the correlation coefficient
    corrs(s) = corr_coeff;  % Store it for plotting
    
    % Plot the correlation coefficient vs. s (with x-axis shifted by 115)
    subplot(3,2,[5 6])
    plot((1:s)+ref1, corrs(1:s), 'ko-')
    yline(0)
    xlabel('s')
    ylabel('Zero-lag correlation coefficient')
    title('Correlation vs. s')
    xlim([ref1 230])
    ylim([-1 1])
    
    pause(.1)
end

%% --- After the loop: Let the user click on the correlation plot to view waveform comparison ---
while true
    % Bring the correlation vs. s plot to focus (assumed to be in subplot(3,2,[5 6]) of figure 6)
    figure(1);   % Replace 1 with the figure number if different
    subplot(3,2,[5 6])
    title('Click on a point in the plot to view the waveform comparison. Right-click to exit.')
    
    % Wait for user input; ginput returns button==1 for left-click, button~=1 to exit.
    [x_click, ~, button] = ginput(1);
    if button ~= 1
        disp('Exiting interactive selection.');
        break;
    end
    
    % Convert the clicked x-coordinate to an s value.
    % The x-axis here runs from ref1 to 230, where x = ref1 corresponds to s=1.
    s_selected = round(x_click - ref1);
    % Make sure s_selected is within bounds.
    s_selected = max(1, min(114, s_selected));
    fprintf('Selected s = %d\n', s_selected);
    
    % Extract the two traces based on the selected s value.
    waveform1 = norm_data(ref1 - s_selected, :);
    waveform2 = norm_data(ref2 + s_selected, :);
    shiftedWaveform2 = real(hilbert(waveform2) * exp(1i * phi));
    
    % Plot the waveform comparison in a new figure or subplot.
    figure(2); clf;
    plot(t, waveform1, 'b', 'LineWidth', 2); hold on;
    plot(t, shiftedWaveform2, 'r', 'LineWidth', 2);
    xlabel('Time (s)');
    ylabel('Normalized amplitude');
    title(sprintf('Waveform Comparison for s = %d (Traces %d and %d)', s_selected, ref1-s_selected, ref2+s_selected));
    xlim([0 0.3]);
    ylim([-2 2]);
    
    % Prompt to pick another point
    choice = questdlg('Pick again?', 'Interactive Selection', 'Yes', 'No', 'Yes');
    if strcmpi(choice, 'No')
        break;
    end
end




