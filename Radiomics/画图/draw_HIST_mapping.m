% 流程图里面需要画一个直方图代表我提取出来的特征
% 2025/04/16 zhumengying

% 清空工作区
clear; clc; %close all;

% 加载 .mat 文件中的 ROI 数据
roi = load('H:\重建数据\mapping_unet_best\peizhun\PD_out_t2s\ROI_processed\T2star_Mapping\ROI\sub001_HC_roiData.mat').roiInfo;

% 初始化存储数据和名称
num_rois = length(roi); % ROI 的数量
data_roi = cell(1, num_rois); % 用于存储每个 ROI 的数据
roi_names = cell(1, num_rois); % 用于存储每个 ROI 的名称
data_counts = zeros(1, num_rois); % 用于存储每个 ROI 的数据量

% 提取每个 ROI 的数据和名称，并统计数据量
for i = 1:num_rois
    data_roi{i} = roi(i).Data; % 提取数据
    data_roi{i} = data_roi{i}(:); % 展平为一维数组
    data_roi{i} = data_roi{i}(~isnan(data_roi{i}) & isfinite(data_roi{i})); % 去除 NaN 和 Inf 值
    roi_names{i} = roi(i).Name; % 提取名称
    data_counts(i) = length(data_roi{i}); % 统计数据量
    
    % 打印每个 ROI 的数据范围
    if ~isempty(data_roi{i})
        disp([roi_names{i}, ': ', num2str(min(data_roi{i})), ' 到 ', num2str(max(data_roi{i}))]);
    else
        disp([roi_names{i}, ': 数据为空']);
    end
end

% 按数据量从大到小排序
[~, sorted_idx] = sort(data_counts, 'descend'); % 获取排序索引
data_roi = data_roi(sorted_idx); % 按排序索引重新排列数据
roi_names = roi_names(sorted_idx); % 按排序索引重新排列名称

% 定义颜色（使用渐变色）
% colors = parula(num_rois); % 根据 ROI 数量生成渐变色
colors = double([
    171, 198, 228;   % 红色
    195, 147, 152;   % 绿色
    252, 218, 186;   % 蓝色
    167, 210, 186;   % 黄色
    208, 202, 222;   % 品红色
    128, 177, 211;   % 灰色
    244, 127, 114;    % 橙色
    251, 180, 99   % 青色
])/255;

% 创建图形窗口
fig = figure; % 创建图形窗口
fig.Position(3:4) = [700, 400]; % 只设置宽度和高度（800 像素宽，600 像素高）
hold on;

% 设置 bin 宽度
bin_width = 1; % 根据数据分布调整 bin 宽度
max_height = 150; % 手动设置最大高度

% 绘制每个 ROI 的直方图（限制最大高度）
for i = 1:num_rois
    if ~isempty(data_roi{i}) % 跳过空数据
        % 计算直方图
        [counts, edges] = histcounts(data_roi{i}, 'BinWidth', bin_width);
        limited_counts = min(counts, max_height); % 限制最大高度
        
        % 绘制直方图
        bar(edges(1:end-1), limited_counts, 'FaceColor', colors(i, :), 'FaceAlpha', 0.6, 'EdgeColor', 'none');
    end
end

% 添加图例和标题
% 获取所有 sheet 名称
roi_values = {'TH', 'PU', 'CN', 'GPe', 'GPi', 'DN', 'RN', 'SN'};
% 添加图例、标题和标签
lgd = legend(roi_values, 'Location', 'northeast'); % 图例显示 ROI 名称
lgd.Box = 'off'; % 隐藏图例的边框
lgd.FontSize = 11; % 调整图例字体大小（可以根据需要调整）
% xlabel('Intensity', 'FontSize', 12);
% ylabel('Frequency', 'FontSize', 12);
axis tight; % 自动调整坐标轴范围以适应数据

% 美化图形
% grid on; % 添加网格线
hold off;