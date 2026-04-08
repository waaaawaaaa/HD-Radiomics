% GraphPad Prism 不能用代码操作，所以将前面得到的Excel表格整理出来
% 按照分类一个不同ROI的格式   %整理成T统计格式，计算均值方差
% 2024/12/16 zhumengying

clc;clear;

seq = 'T2Mapping';
excel='腐蚀1_T2_cx';
file_root = 'H:\重建数据\mapping_unet_best\peizhun\PD_out_t2m\ROI_processed\';
filename = [file_root seq '_' excel '.xlsx'];  % 替换为你的Excel文件名
data = readtable(filename);

% 创建一个新的Excel文件用于存储结果
output_filename = ['zhengli_',seq,'_' excel '.xlsx'];
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

    % 根据ClassicValue列拆分成两个子表
    classic_HC = sorted_table(sorted_table.ClassicValue == 0, :);
    classic_preHD = sorted_table(sorted_table.ClassicValue == 1, :);
    classic_MHD = sorted_table(sorted_table.ClassicValue == 2, :);
    mean_values_HC = mean(classic_HC{:, 1:end-1}, 'omitnan');  % 根据列计算均值，排除 NaN
    std_values_HC = std(classic_HC{:, 1:end-1}, 0, 1, 'omitnan');  % 根据列计算标准差，排除 NaN

    mean_values_preHD = mean(classic_preHD{:, 1:end-1}, 'omitnan');  % 根据列计算均值，排除 NaN
    std_values_preHD = std(classic_preHD{:, 1:end-1}, 0, 1, 'omitnan');  % 根据列计算标准差，排除 NaN
    
    % 计算 ClassicValue 为 2 的均值和标准差，排除 NaN
    mean_values_MHD = mean(classic_MHD{:, 1:end-1}, 'omitnan');  % 根据列计算均值，排除 NaN
    std_values_MHD = std(classic_MHD{:, 1:end-1}, 0, 1, 'omitnan');  % 根据列计算标准差，排除 NaN

        % 保留两位小数
    mean_values_HC = round(mean_values_HC, 2);
    std_values_HC = round(std_values_HC, 2);
    mean_values_preHD = round(mean_values_preHD, 2);
    std_values_preHD = round(std_values_preHD, 2);
    mean_values_MHD = round(mean_values_MHD, 2);
    std_values_MHD = round(std_values_MHD, 2);

    % 提取数据部分，不包括行名和变量名 不要subject
    data_sorted = sorted_table{:,1:end-1};
    
    % 将数据转换为一个新的表格，每一行数据作为一列，列名为 'subject' 转置了
    data_table = array2table(data_sorted', 'VariableNames', sorted_table.Subject, 'RowNames', sorted_table.Properties.VariableNames(1:end-1));
    % 将行名数据放置到表格
    data_table.ROI = data_table.Properties.RowNames;
    % 将新列移动到表格的第一列
    data_table = [data_table(:,end), data_table(:,1:end-1)];
    data_table.mean_HC = mean_values_HC';
    data_table.std_HC = std_values_HC';
    data_table.mean_preHD = mean_values_preHD';
    data_table.std_preHD = std_values_preHD';
    data_table.mean_MHD = mean_values_MHD';
    data_table.std_MHD = std_values_MHD';

    % 将每个ROI的数据写入到Excel的不同sheet中
    writetable(data_table, excel_output, 'Sheet', sheet_name, 'FileType', 'spreadsheet', 'WriteMode', 'append');
end

disp(['数据已成功分割到不同的sheet中: ', output_filename]);