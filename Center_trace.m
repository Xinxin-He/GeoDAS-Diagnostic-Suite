close all
clear

fullpath = 'mine_harris_data/MiningHarrisburgDAS_UTC_20250321_183602.252.h5';
% fullpath = '../mine_harris/MiningHarrisburgDAS_UTC_20250321_184202.252.h5';
disp(fullpath)
addpath(genpath('crewes/'))

info = h5info(fullpath);
disp(info)



% Get dataset name from the 'info' struct
dataset_name = info.Datasets.Name;
data = h5read(fullpath, ['/' dataset_name]);
data2 = data(1:250,22500:23400);
% data2 = data(1:300,:);

dt = 1/str2num(info.Datasets.Attributes(1).Value);
t = (1:size(data2,2))*dt;
data2 = double(data2);
data2 = butterband(data2',t,0,100)';

figure('Units','inches','Position',[0 0 6 10])

% window = 50
% for i = window:size(data2,1)-window
%     subplot(5,1,1)
%     imagesc(data2)
%     yline(i)
%     yline(i-(window-1))
%     yline(i+1)
%     yline(i+window)
% 
%     subplot(5,1,2)
%     data3 = data2(i-(window-1):i,:);
%     data4 = flipud(data2(i+1:i+window,:));
%     imagesc(data3)
% 
%     subplot(5,1,3)
%     imagesc(data4)
% 
%     subplot(5,1,4)
%     imagesc(data3-data4)
% 
%     subplot(5,1,5)
%     hold on
%     scatter(i,sum((data3-data4).^2,'all'),'k','filled')
%     hold off
% 
%     pause(.1)
% end



% 设置全局 Colormap，地震数据推荐使用 'seismic' 或 'turbo'，如果没有可以改为 'jet'
colormap('turbo'); 

% 初始背景设为白色
set(gcf, 'Color', 'w');

% 定义一个合理的颜色刻度范围，根据你数据的幅度调整（比如 -5 到 5）
c_limit = [-5000, 5000]; 

window = 50;
for i = window:size(data2,1)-window
    % 子图 1: 全局瀑布图
    subplot(5,1,1)
    imagesc(data2)
    hold on;
    % 清除旧的线（可选，如果想保持干净的话）
    yline(i, 'r', 'LineWidth', 1.5)
    yline(i-(window-1), 'k--')
    yline(i+1, 'r', 'LineWidth', 1.5)
    yline(i+window, 'k--')
    hold off;
    title(['DAS Channel Sliding Window: ', num2str(i)])
    colorbar;
    clim(c_limit);
    
    % 数据处理
    data3 = data2(i-(window-1):i,:);
    data4 = flipud(data2(i+1:i+window,:));
    diff_data = data3 - data4;
    
    % 子图 2: 上窗口数据
    subplot(5,1,2)
    imagesc(data3)
    ylabel('Upper Window')
    colorbar;
    clim(c_limit);
    
    % 子图 3: 下窗口数据 (翻转后)
    subplot(5,1,3)
    imagesc(data4)
    ylabel('Lower (flipped)')
    colorbar;
    clim(c_limit);
    
    % 子图 4: 差异值 (Residuals)
    subplot(5,1,4)
    imagesc(diff_data)
    ylabel('Difference')
    colorbar;
    clim(c_limit/2); % 差异通常较小，可以收窄刻度看细节
    
    % 子图 5: 能量累积分布
    subplot(5,1,5)
    hold on
    energy = sum(diff_data.^2, 'all');
    scatter(i, energy, 'k', 'filled')
    set(gca, 'Color', 'w'); % 确保坐标轴背景白
    ylabel('Energy (SSR)')
    xlabel('Channel Index')
    grid on;
    
    % 强制刷新图形窗口
    drawnow;
    pause(0.05)
end


