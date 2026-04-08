% 画出结果的柱状图
% 2024/12/16 zhumengying

clc; clear;close all;

% 读取数据
seq = 'T2Mapping';  % T2Mapping 或 T2star_Mapping
excel = '腐蚀1_T2_cx';
file_root = 'H:/重建数据/mapping_unet_best/peizhun/PD_out_t2m/ROI_processed/';
filename = fullfile(file_root, [seq '_' excel '0.xlsx']);
data = readtable(filename);

% 获取唯一 ROI 和特征列名称
roi_values = unique(data.ROI);
features_name = data.Properties.VariableNames(2:end-8);

% 遍历每个特征并绘制分组柱状图
for j = 1:length(features_name)
    feature = features_name{j};  % 当前特征
    
    % 初始化存储均值的数组
    means_HC = zeros(1, length(roi_values));  % HC 均值
    means_pre_HD = zeros(1, length(roi_values));  % pre-HD 均值
    means_HD = zeros(1, length(roi_values));  % HD 均值
    
    for i = 1:length(roi_values)
        roi = roi_values(i);  % 当前 ROI
        roi_data = data(strcmp(data.ROI, roi), :);  % 筛选出当前 ROI 的数据
        
        if isempty(roi_data)
            warning('No data found for ROI: %s', roi);
            continue; % 如果数据为空，跳过当前 ROI
        end
        
        % 按 'ClassicValue' 排序
        sorted_table = sortrows(roi_data, 'ClassicValue');
        
        % 提取当前特征的数据
        feature_data = sorted_table.(feature);
        feature_HC = feature_data(sorted_table.ClassicValue == 0);
        feature_pre_HD = feature_data(sorted_table.ClassicValue == 1);
        feature_HD = feature_data(sorted_table.ClassicValue == 2);
        
        % 计算均值并存储
        means_HC(i) = mean(feature_HC);  % 存储到对应 ROI 的位置
        means_pre_HD(i) = mean(feature_pre_HD);
        means_HD(i) = mean(feature_HD);
    end

    % 绘制分组柱状图
    figure;
    bar_width = 0.2;  % 柱状图宽度
    x = 1:length(roi_values);  % ROI 索引
    
    % 将 RGB 值归一化到 [0, 1] 范围
    color_HC = [240, 155, 160] / 255;       % 浅红色
    color_pre_HD = [234, 184, 131] / 255;   % 橙色
    color_HD = [155, 187, 225] / 255;      % 浅蓝色
    
    % 绘制柱状图并手动设置颜色
    b1 = bar(x - bar_width, means_HC, 'BarWidth', bar_width); hold on;
    b2 = bar(x, means_pre_HD, 'BarWidth', bar_width); 
    b3 = bar(x + bar_width, means_HD, 'BarWidth', bar_width); 
    
    % 手动设置颜色
    set(b1, 'FaceColor', color_HC, 'EdgeColor', 'none'); % HC 柱子
    set(b2, 'FaceColor', color_pre_HD, 'EdgeColor', 'none'); % Pre-HD 柱子
    set(b3, 'FaceColor', color_HD, 'EdgeColor', 'none'); % HD 柱子
    
    hold off;
    
    % 设置图形属性
    xlabel('ROI');
    ylabel('Mean Values');
    title(['Feature: ', feature]);
%     legend({'HC', 'Pre-HD', 'HD'}, 'Location', 'northwest');
    lgd = legend({'HC', 'Pre-HD', 'HD'}, 'Location', 'northwest');
    set(lgd, 'Box', 'off');  % 关键：去掉图例边框
    set(gca, 'XTick', x, 'XTickLabel', roi_values);
    grid on;
end
