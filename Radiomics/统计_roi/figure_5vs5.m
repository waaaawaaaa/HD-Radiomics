% 对健康受试者的两个仪器分类，整理成T统计格式，计算均值方差  5 vs 5
% 想做出图放在论文里，按理来说，做个Mann-Whitney U检验+散点图，Bland-Altman 图，证明一致性
% 2025/04/02 zhumengying

clc; clear; close all;

% 参数设置
seq = 'T2star_Mapping';
excel = '腐蚀1_T2_cx';
file_root = 'H:\重建数据\mapping_unet_best\peizhun\PD_out_t2s\ROI_processed\';
filename = [file_root seq '_' excel '0.xlsx'];  % 替换为你的Excel文件名
data = readtable(filename);

% 获取唯一的ROI值列表，并排除 "DN"
roi_values = unique(data.ROI);
roi_values = roi_values(~strcmp(roi_values, 'DN'));  % 排除 "DN"

% 初始化变量，用于存储所有ROI的数据
all_data0 = [];  % Group0 数据
all_data1 = [];  % Group1 数据

% 定义颜色映射表
color_0 = [202, 200, 239] / 255;  % 浅蓝色（Ingenia CX）
color_1 = [201, 239, 190] / 255; % 浅黄色（Ingenia Elition X）

figure;hold on;

% 设置柱形图的宽度和间隔
bar_width = 0.3;  % 柱形图宽度
group_offset = 0.6;  % 组之间的间隔

for i = 1:length(roi_values)
    roi = roi_values{i};  % 使用 {} 运算符来获取单元格中的内容
    roi_data = data(strcmp(data.ROI, roi), :);  % 使用 strcmp 来比较cell中的字符串
    
    sheet_name = roi;  % sheet名称以ROI值命名

    % 移除ROI列
    roi_data(:, 'ROI') = [];  % 移除ROI列

    % 定义第一组 HC Subject (Ingenia Elition X)
    group1_subjects = ["sub004_HC", "sub019_HC", "sub024_HC", "sub026_HC", "sub027_HC"];
    
    % 提取第一组数据，并按指定顺序排列
    [~, idx_group1] = ismember(group1_subjects, roi_data.Subject);
    classic1 = roi_data(idx_group1, :);
    
    % 定义第二组 HC Subject (Ingenia CX)
%     group0_subjects = ["sub001_HC", "sub025_HC", "sub021_HC", "sub008_HC", "sub012_HC"];
    group0_subjects = ["sub002_HC", "sub021_HC", "sub020_HC", "sub008_HC", "sub012_HC"];
    
    % 提取第二组数据，并按指定顺序排列
    [~, idx_group0] = ismember(group0_subjects, roi_data.Subject);
    classic0 = roi_data(idx_group0, :);

    % 提取需要的特征列
    data0 = single(classic0{:, 1:1});  % 对应的是均值特征
    data1 = single(classic1{:, 1:1});

    % 将当前ROI的数据添加到总数据中
    all_data0 = [all_data0; data0];
    all_data1 = [all_data1; data1];

    %% 统计检验
    % Mann-Whitney U 检验
    [p_value, h] = ranksum(data0, data1);
    disp(['ROI: ', roi]);
    disp(['Mann-Whitney U 检验 p 值: ', num2str(p_value)]);
    if h == 1
        disp('两组数据有显著差异');
    else
        disp('两组数据无显著差异');
    end

    %% 计算均值和标准差
    mean0 = mean(data0, 'omitnan');  % Group0 均值
    std0 = std(data0, 0, 'omitnan'); % Group0 标准差
    mean1 = mean(data1, 'omitnan');  % Group1 均值
    std1 = std(data1, 0, 'omitnan'); % Group1 标准差

    %% 绘制柱形图
    bar_x_group0 = i - bar_width / 2-0.05;  % Group0 柱形图位置
    bar_x_group1 = i + bar_width / 2+0.05;  % Group1 柱形图位置

    % 绘制柱形图
    bar(bar_x_group0, mean0, bar_width, 'FaceColor', color_0, 'EdgeColor', 'none');  % Group0 柱形图
    bar(bar_x_group1, mean1, bar_width, 'FaceColor', color_1, 'EdgeColor', 'none');  % Group1 柱形图

      %% 叠加数据散点（改进版）
    % Group0 散点
    n_points0 = length(data0); % 数据点数量
    scatter_x_group0 = linspace(i - bar_width / 2 - bar_width / 4, ...
                                i - bar_width / 2 + bar_width / 4, n_points0);
    scatter(scatter_x_group0-0.05, data0, 30, color_0, 'filled', 'MarkerEdgeColor', 'k');
    
    % Group1 散点
    n_points1 = length(data1); % 数据点数量
    scatter_x_group1 = linspace(i + bar_width / 2 - bar_width / 4, ...
                                i + bar_width / 2 + bar_width / 4, n_points1);
    scatter(scatter_x_group1+0.05, data1, 30, color_1, 'filled', 'MarkerEdgeColor', 'k');
    
    %% 添加误差棒
    errorbar(bar_x_group0, mean0, std0, 'k', 'LineStyle', 'none', 'LineWidth', 1.2);
    errorbar(bar_x_group1, mean1, std1, 'k', 'LineStyle', 'none', 'LineWidth', 1.2);

    %% 标记显著性
    % 根据 p 值选择显著性标记
    if p_value < 0.001
        sig_mark = '***'; % 极显著
    elseif p_value < 0.01
        sig_mark = '**';  % 高度显著
    elseif p_value < 0.05
        sig_mark = '*';   % 显著
    else
        sig_mark = 'ns';    % 无显著性
    end

    % 在柱形图上方标注显著性
    if ~isempty(sig_mark)
        max_y = max([data0; data1]); % 获取柱形图的最大高度
        sig_y = max_y + 0.024 * max_y; % 显著性横线的高度
        sig_text_y = sig_y + 0.005 * max_y; % 显著性标记的高度

        % 绘制显著性横线
        plot([bar_x_group0, bar_x_group1], [sig_y, sig_y], ...
             'k-', 'LineWidth', 1); % 显著性横线

        % 添加显著性标记
        text((bar_x_group0 + bar_x_group1) / 2, sig_text_y, sig_mark, ...
             'HorizontalAlignment', 'center', 'VerticalAlignment', 'bottom', ...
             'FontSize', 9, 'FontWeight', 'bold');
    end
end

% 设置 X 轴为 ROI 名称
xticks(1:length(roi_values));
xticklabels(roi_values);

% 添加图例，并隐藏图例的边框
lgd = legend({'Ingenia CX', 'Ingenia Elition X'}, 'Location', 'north');
lgd.Box = 'off'; % 隐藏图例的边框

title(['Bar Plot for ', seq]);
ylabel(['Mean ', seq, ' value (ms)']);

hold off;

%% 绘制所有 ROI 合并的 Bland-Altman 图
figure;
mean_values_all = (all_data0 + all_data1) / 2; % 平均值
diff_values_all = all_data0 - all_data1;      % 差值

% 绘制散点图
scatter(mean_values_all, diff_values_all, 50, [67, 112, 180] / 255, 'filled'); % 差值 vs 平均值
hold on;

% 添加参考线
mean_diff_all = mean(diff_values_all, 'omitnan'); % 差值均值
std_diff_all = std(diff_values_all, 0, 'omitnan'); % 差值标准差

% 获取当前绘图区域的横坐标范围
x_limits = xlim;

% 平均线
plot(x_limits, [mean_diff_all, mean_diff_all], '--k', 'LineWidth', 1.5); 

% 上限和下限
upper_limit = mean_diff_all + 1.96 * std_diff_all;
lower_limit = mean_diff_all - 1.96 * std_diff_all;
plot(x_limits, [upper_limit, upper_limit], '--r', 'LineWidth', 1.5); % 上限
plot(x_limits, [lower_limit, lower_limit], '--r', 'LineWidth', 1.5); % 下限

% 绘制 0 的参考线（点划线）
plot(x_limits, [0, 0], ':k', 'LineWidth', 1); % 0 的参考线

% 标注均值、上限和下限的具体数值
text(x_limits(2), mean_diff_all, sprintf(' Mean: %.2f', mean_diff_all), ...
     'VerticalAlignment', 'top', 'HorizontalAlignment', 'right', 'Color', 'k');
text(x_limits(2), upper_limit, sprintf(' Mean+1.96*SD: %.2f', upper_limit), ...
     'VerticalAlignment', 'top', 'HorizontalAlignment', 'right', 'Color', 'r');
text(x_limits(2), lower_limit, sprintf(' Mean-1.96*SD: %.2f', lower_limit), ...
     'VerticalAlignment', 'bottom', 'HorizontalAlignment', 'right', 'Color', 'r');

% 图形标题和标签
title(['Bland-Altman Plot for ', seq]);
xlabel(['Mean ', seq, ' value (ms)']);
ylabel(['Difference in ', seq, ' value (ms)']);
hold off;