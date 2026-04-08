% 流程图里面需要画一个直方图代表我提取出来的特征，流式直方图
% 2025/04/16 zhumengying

% 加载 .mat 文件中的 ROI 数据
roi = load('H:\重建数据\mapping_unet_best\peizhun\PD_out_t2s\ROI_processed\T2star_Mapping\ROI\sub001_HC_roiData.mat').roiInfo;

% 初始化存储数据和名称
num_rois = length(roi); % ROI 的数量
data_roi = cell(1, num_rois); % 用于存储每个 ROI 的数据
roi_names = cell(1, num_rois); % 用于存储每个 ROI 的名称

% 提取每个 ROI 的数据和名称
for i = 1:num_rois
    data_roi{i} = roi(i).Data; % 提取数据
    data_roi{i} = data_roi{i}(:); % 展平为一维数组
    data_roi{i} = data_roi{i}(~isnan(data_roi{i}) & isfinite(data_roi{i})); % 去除 NaN 和 Inf 值
    roi_names{i} = roi(i).Name; % 提取名称
    
    % 打印每个 ROI 的数据范围
    if ~isempty(data_roi{i})
        disp([roi_names{i}, ': ', num2str(min(data_roi{i})), ' 到 ', num2str(max(data_roi{i}))]);
    else
        disp([roi_names{i}, ': 数据为空']);
    end
end

% 过滤掉空的 ROI 数据
non_empty_indices = cellfun(@isempty, data_roi) == 0; % 找到非空 ROI 的索引
data_roi = data_roi(non_empty_indices); % 保留非空 ROI 数据
roi_names = roi_names(non_empty_indices); % 保留对应的 ROI 名称

% 按数据量从大到小排序
data_sizes = cellfun(@length, data_roi); % 计算每个 ROI 的数据点数量
[~, sorted_indices] = sort(data_sizes, 'descend'); % 按数据量降序排序
data_roi = data_roi(sorted_indices); % 对 ROI 数据重新排序
roi_names = roi_names(sorted_indices); % 对 ROI 名称重新排序

% 合并所有非空 ROI 数据
if ~isempty(data_roi)
    all_data = vertcat(data_roi{:}); % 使用 vertcat 将所有非空 ROI 数据合并为一个列向量
    global_min = min(all_data);
    global_max = max(all_data);
else
    error('所有 ROI 数据均为空，无法绘制图表！');
end

% 手动设置 y 轴的最大值
y_axis_max = 150; % 设置 y 轴的最大值（根据需要调整）

% 绘制完全叠加的山峦式直方图（基于计数）
fig = figure; % 创建图形窗口
fig.Position(3:4) = [700, 400]; % 只设置宽度和高度（800 像素宽，600 像素高）
hold on; % 允许在同一图中绘制多条曲线
colors = parula(length(data_roi)); % 根据 ROI 数量生成渐变色
num_bins = 50; % 设置直方图的 bin 数量

for i = 1:length(data_roi)
    % 计算直方图（不归一化，直接使用计数）
    [counts, edges] = histcounts(data_roi{i}, num_bins);
    bin_centers = (edges(1:end-1) + edges(2:end)) / 2; % 计算 bin 中心点
    
    % 绘制填充区域（完全叠加）
    fill([bin_centers, fliplr(bin_centers)], ...
         [counts, zeros(size(counts))], ...
         colors(i, :), 'FaceAlpha', 0.4, 'EdgeColor', 'none');
end

% 获取所有 sheet 名称
roi_values = {'TH', 'PU', 'CN', 'GPe', 'GPi', 'DN', 'RN', 'SN'};
% 添加图例、标题和标签
lgd = legend(roi_values, 'Location', 'northeast'); % 图例显示 ROI 名称

lgd.Box = 'off'; % 隐藏图例的边框
lgd.FontSize = 12; % 调整图例字体大小（可以根据需要调整）
xlabel('Intensity', 'FontSize', 12);
ylabel('Frequency', 'FontSize', 12);

% 设置图形外观
xlim([global_min, global_max]); % 设置 x 轴范围
ylim([0, y_axis_max]); % 手动设置 y 轴的最大值
% grid on; % 显示网格
hold off; % 结束绘图