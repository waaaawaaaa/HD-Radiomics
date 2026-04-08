% 对我特征的统计结果画图
% 2025/04/04 zhumengying

clc; clear;close all;

% 读取数据
seq = 'T2star_Mapping';  % T2Mapping 或 T2star_Mapping
excel = '腐蚀1_T2_cx';
file_root = 'H:/重建数据/mapping_unet_best/peizhun/PD_out_t2s/ROI_processed/';
% filename = fullfile(file_root, [seq '_' excel '0.xlsx']);
filename = fullfile(file_root, ['test3_' seq '_' excel '3.xlsx']);

% 获取所有 sheet 名称
roi_values = {'Ca', 'Pu', 'GPe', 'GPi', 'TH', 'RN', 'SN', 'DN'};

% 初始化一个 cell 数组存储每个 sheet 的数据
all_data = cell(length(roi_values), 1);

% 循环读取每个 sheet 的数据
for i = 1:length(roi_values)
    sheet_name = roi_values{i};
    all_data{i} = readtable(filename, 'Sheet', sheet_name);
    fprintf('已读取 sheet: %s\n', sheet_name);
end

features_name = all_data{1,1}{1:13,'ROI'};

% 遍历每个特征并绘制分组柱状图
for j = 1:length(features_name)
    feature = features_name{j};  % 当前特征
    figure();
    bar_width = 0.2;  % 柱状图宽度
    
    % 将 RGB 值归一化到 [0, 1] 范围
    color_HC = [240, 155, 160] / 255;       % 浅红色
    color_pre_HD = [234, 184, 131] / 255;   % 橙色
    color_HD = [155, 187, 225] / 255;      % 浅蓝色
    
    for i = 1:length(roi_values)
        roi = roi_values(i);  % 当前 ROI
        ROI_data = all_data{i,1};
        roi_data = ROI_data(:,1:end-16);  % 筛选出当前 ROI 的数据
        % 更新列名
        roi_data.Properties.RowNames = ROI_data{:, 1};
        roi_data = roi_data(:, 2:end);
        
        roi_test = ROI_data(1:13,end-14:end);
        roi_test.Properties.RowNames = ROI_data{1:13, 1};

        % 提取当前特征的数据
        feature_data = roi_data{j, :};
%         feature_data = roi_data.(feature);
        class_row_index = strcmp(roi_data.Properties.RowNames, 'ClassicValue');
        class_data = roi_data{class_row_index, :};
        feature_HC = feature_data(class_data == 0);
        feature_pre_HD = feature_data(class_data == 1);
        feature_HD = feature_data(class_data == 2);

        % 绘制分组柱状图
    
        % 绘制柱状图并手动设置颜色
        b1 = bar(i - bar_width, roi_test.mean_hc(j), bar_width, 'FaceColor', color_HC, 'EdgeColor', 'none'); hold on;
        b2 = bar(i, roi_test.mean_pre_hd(j), bar_width, 'FaceColor', color_pre_HD, 'EdgeColor', 'none'); 
        b3 = bar(i + bar_width, roi_test.mean_hd(j), bar_width, 'FaceColor', color_HD, 'EdgeColor', 'none'); 
            
%         % 添加散点图
%         scatter(repmat(i - bar_width, 1, length(feature_HC)) + rand(1, length(feature_HC)) * 0.1 - 0.05, ...
%                 feature_HC, 20, color_HC, 'filled', 'MarkerEdgeColor', 'k');
%         scatter(repmat(i, 1, length(feature_pre_HD)) + rand(1, length(feature_pre_HD)) * 0.1 - 0.05, ...
%                 feature_pre_HD, 20, color_pre_HD, 'filled', 'MarkerEdgeColor', 'k');
%         scatter(repmat(i + bar_width, 1, length(feature_HD)) + rand(1, length(feature_HD)) * 0.1 - 0.05, ...
%                 feature_HD, 20, color_HD, 'filled', 'MarkerEdgeColor', 'k');

         % 添加误差棒
        errorbar(i - bar_width, roi_test.mean_hc(j), roi_test.sd_hc(j), 'k.', 'LineWidth', 1.2);
        errorbar(i, roi_test.mean_pre_hd(j), roi_test.sd_pre_hd(j), 'k.', 'LineWidth', 1.2);
        errorbar(i + bar_width, roi_test.mean_hd(j), roi_test.sd_hd(j), 'k.', 'LineWidth', 1.2);

        %% 标记显著性
        if roi_test.p_test(j) < 0.05 % 证明组间有显著性
            % 将 cell 类型的列转换为数值类型
            if iscell(roi_test.hc_vs_pre_hd) % 检查整个列是否为 cell 类型
                p_hc_vs_pre_hd = str2double(roi_test.hc_vs_pre_hd{j}); % 提取 cell 内容并转换为数值
            else
                p_hc_vs_pre_hd = roi_test.hc_vs_pre_hd(j); % 直接访问数值类型的数据
            end

            if iscell(roi_test.hc_vs_hd)
                p_hc_vs_hd = str2double(roi_test.hc_vs_hd{j});
            else
                p_hc_vs_hd = double(roi_test.hc_vs_hd(j)); % 如果已经是数值类型，确保为 double
            end
            
            if iscell(roi_test.pre_hd_vs_hd)
                p_pre_hd_vs_hd = str2double(roi_test.pre_hd_vs_hd{j});
            else
                p_pre_hd_vs_hd = double(roi_test.pre_hd_vs_hd(j)); % 如果已经是数值类型，确保为 double
            end
            if p_hc_vs_pre_hd < 0.05
%                 max_y = max([data0; data1]); % 获取柱形图的最大高度
                max_y1 = max([roi_test.mean_hc(j)+roi_test.sd_hc(j); roi_test.mean_pre_hd(j)+roi_test.sd_pre_hd(j)]);
                sigline([i - bar_width, i], max_y1, p_hc_vs_pre_hd);
            end
            if p_hc_vs_hd < 0.05
%                 max_y = max([data0; data1]); % 获取柱形图的最大高度
                max_y2 = max([roi_test.mean_hc(j)+roi_test.sd_hc(j); roi_test.mean_hd(j)+roi_test.sd_hd(j)]);
                sigline([i - bar_width, i+bar_width], max_y2*1.1, p_hc_vs_hd);
            end
            if p_pre_hd_vs_hd < 0.05
%                 max_y = max([data0; data1]); % 获取柱形图的最大高度
                max_y3 = max([roi_test.mean_pre_hd(j)+roi_test.sd_pre_hd(j); roi_test.mean_hd(j)+roi_test.sd_hd(j)]);
                sigline([i, i+bar_width], max_y3+0.2, p_pre_hd_vs_hd);
            end
        end
    end
    hold off;
        
    % 设置图形属性
    xlabel('ROI');
    ylabel('Mean Values');
    title(['Feature: ', feature]);
    legend({'HC', 'Pre-HD', 'HD'}, 'Location', 'northwest');
    set(gca, 'XTick', 1:length(roi_values), 'XTickLabel', roi_values);
    grid on;
end


function sigline(x, y, p)
    x = x';
    
    if p<0.001
        text(mean(x), y*1.1, '***', ...
             'HorizontalAlignment', 'center', 'VerticalAlignment', 'bottom', ...
             'FontSize', 11, 'FontWeight', 'bold');
%         plot(mean(x),       y*1.15, '*k')          % the sig star sign
%         plot(mean(x)- 0.02, y*1.15, '*k')          % the sig star sign
%         plot(mean(x)+ 0.02, y*1.15, '*k')          % the sig star sign
    
    elseif (0.001<=p)&&(p<0.01)
        text(mean(x), y*1.1, '**', ...
             'HorizontalAlignment', 'center', 'VerticalAlignment', 'bottom', ...
             'FontSize', 11, 'FontWeight', 'bold');
%         plot(mean(x)- 0.01, y*1.15, '*k')         % the sig star sign
%         plot(mean(x)+ 0.01, y*1.15, '*k')         % the sig star sign
    
    elseif (0.01<=p)&&(p<0.05)
        text(mean(x), y*1.1, '*', ...
             'HorizontalAlignment', 'center', 'VerticalAlignment', 'bottom', ...
             'FontSize', 11, 'FontWeight', 'bold');
%         plot(mean(x), y*1.15, '*k')               % the sig star sign
    else
        text(mean(x), y*1.1, 'ns', ...
             'HorizontalAlignment', 'center', 'VerticalAlignment', 'bottom', ...
             'FontSize', 9, 'FontWeight', 'bold');
    end
    
    plot(x, [1;1]*y*1.08, '-k', 'LineWidth',1); % 显著性的那条直线
    plot([1;1]*x(1), [y*1.05, y*1.08], '-k', 'LineWidth', 1); % 显著性的那条直线的左方下直线
    plot([1;1]*x(2), [y*1.05, y*1.08], '-k', 'LineWidth', 1); % 显著性的那条直线的右方下直线
end
