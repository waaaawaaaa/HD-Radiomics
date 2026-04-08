% GraphPad Prism 不能用代码操作，所以将前面得到的Excel表格整理出来
% 按照分类一个不同ROI的格式   %整理成T统计格式，计算均值方差
% 做统计检验
% 2025/02/16 zhumengying

clc;clear;close all;

seq = 'T2star_Mapping';
excel='腐蚀1_T2_cx';
file_root = 'H:\重建数据\mapping_unet_best\peizhun\PD_out_t2s\ROI_processed\';
filename = [file_root seq '_' excel '.xlsx'];  % 替换为你的Excel文件名
data = readtable(filename);

% 创建一个新的Excel文件用于存储结果
output_filename = ['test_',seq,'_' excel '.xlsx'];
excel_output = fullfile(file_root, output_filename);

% 获取唯一的ROI值列表
roi_values = unique(data.ROI);

% 检查是否已存在同名文件，如果是，则先删除
if exist(excel_output, 'file')
    delete(excel_output);
end

% 写入数据到不同的sheet
for i = 1:length(roi_values)
    roi = roi_values{i};  % 使用 {} 运算符来获取单元格中的内容
    roi_data = data(strcmp(data.ROI, roi), :);  % 使用 strcmp 来比较cell中的字符串
    
    sheet_name = roi;  % sheet名称以ROI值命名

    % 移除ROI列
    roi_data(:, 'ROI') = [];  % 移除ROI列
    
    % 按照 'classicvalue' 列的值排序
    sorted_table = sortrows(roi_data, 'ClassicValue');

    features_name = sorted_table.Properties.VariableNames(1:end-4);

    % 创建一个空表格
    result_table = table();
    mean_sd = [];
    for feature = 1:length(features_name)
        %提取出HC Pre_HD HD的每个特征的值
        feature_HC = sorted_table{sorted_table.ClassicValue == 0, features_name{feature}};
        feature_pre_HD = sorted_table{sorted_table.ClassicValue == 1, features_name{feature}};
        feature_HD = sorted_table{sorted_table.ClassicValue == 2, features_name{feature}};

        % 计算均值
        mean_HC = mean(feature_HC);
        mean_pre_HD = mean(feature_pre_HD);
        mean_HD = mean(feature_HD);
        
        % 计算标准差
        std_HC = std(feature_HC);
        std_pre_HD = std(feature_pre_HD);
        std_HD = std(feature_HD);
        temp_data = [mean(feature_HC), std(feature_HC), mean(feature_pre_HD), std(feature_pre_HD), mean(feature_HD), std(feature_HD)];

        datas = {feature_HC, feature_pre_HD, feature_HD};
        p_all = [];
        for a = 1:length(datas)
            for b = a+1:length(datas)
                % 提取要比较的数据
                data1 = datas{a};
                data2 = datas{b};
            
                % ============ 1. 正态性检验 ============
                % S-W检验（小于2000样本适用）
                % 对每组数据进行 Shapiro-Wilk 检验
                [~, p_1] = swtest(data1);
                [~, p_2] = swtest(data2);
                      
                % ============ 2. 方差齐性检验 ============   
                % 将所有数据合并成一个向量
                data_all = [data1;data2]; 
                % 生成分组信息
                group = [ones(length(data1), 1);  % CSF组
                         2 * ones(length(data2), 1)];  % WM组
                [p_levene, stats_levene] = vartestn(data_all, group, 'TestType', 'LeveneAbsolute', 'Display', 'off');
    %         fprintf('Levene检验 p=%.4f, %s\n', p_levene, ternary(p_levene>0.05, '方差齐性成立', '方差不齐'));
    
                 % ============ 3. 选择统计方法 ============
                % 3. Choose appropriate test based on the results of normality and variance homogeneity tests
                if p_1 > 0.05 && p_2 > 0.05 && p_levene > 0.05
                    % Parametric independent t-test (both normality and equal variances)
                    [h, p, stats] = ttest2(data1, data2);
                    disp(['t-test p-value: ', num2str(p)]);
                else
                    % Non-parametric test (Mann-Whitney U test)
                    [p, h, stats] = ranksum(data1, data2);
                    disp(['Mann-Whitney U test p-value: ', num2str(p)]);
                end
                temp_data = [temp_data, p];
            end
        end
        mean_sd = [mean_sd;temp_data];
    end

    % 将数组转换为表格
    data_table2 = array2table(mean_sd, 'VariableNames', {'mean_hc', 'sd_hc', 'mean_pre_hd', 'sd_pre_hd', 'mean_hd', 'sd_hd', 'hc vs. pre_hd', 'hc vs. hd', 'pre_hd vs. hd'}); 

    % 提取数据部分，不包括行名和变量名 不要subject
    data_sorted = sorted_table{:,1:end-1};
    
    % 将数据转换为一个新的表格，每一行数据作为一列，列名为 'subject' 转置了
    data_table = array2table(data_sorted', 'VariableNames', sorted_table.Subject, 'RowNames', sorted_table.Properties.VariableNames(1:end-1));
    % 将行名数据放置到表格
    data_table.ROI = data_table.Properties.RowNames;
    % 将新列移动到表格的第一列
    data_table = [data_table(:,end), data_table(:,1:end-1)];
%     data_table.mean0 = mean_values0';
%     data_table.std0 = std_values0';
%     data_table.mean1 = mean_values1';
%     data_table.std1 = std_values1';
%     data_table.mean2 = mean_values2';
%     data_table.std2 = std_values2';

    % 将每个ROI的数据写入到Excel的不同sheet中
    writetable(data_table, excel_output, 'Sheet', sheet_name, 'Range', 'A1');
    % 计算第二个表格的起始列

    writetable(data_table2, excel_output, 'Sheet', sheet_name, 'Range', 'BN1');
end

disp(['数据已成功分割到不同的sheet中: ', output_filename]);