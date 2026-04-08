% GraphPad Prism 不能用代码操作，所以将前面得到的Excel表格整理出来
% 按照分类一个不同ROI的格式  表格用作T检验，和ROC曲线
% 2024/12/17 zhumengying

clc;clear;

seq = 'T2Mapping';
excel='腐蚀1_T2';
file_root = 'H:\重建数据\zmy_final\PD_out_t2m\ROI_processed\';
filename = [file_root seq '_' excel '.xlsx'];  % 替换为你的Excel文件名
data = readtable(filename);

% 创建一个新的Excel文件用于存储结果
output_filename = ['zhengli_',seq,'_' excel '_roc.xlsx'];
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
    
    sheet_name_t_test = [roi '_t_test'];  % sheet名称以ROI值命名
    sheet_name_ROC = [roi '_ROC'];  % sheet名称以ROI值命名

    % 移除ROI列
    roi_data(:, 'ROI') = [];  % 移除ROI列
    
    % 按照 'classicvalue' 列的值排序
    sorted_table = sortrows(roi_data, 'ClassicValue');

    % 提取数据部分，不包括行名和变量名
    data_sorted = sorted_table{:,1:end-1};
    
    % 将数据转换为一个新的表格，每一行数据作为一列，列名为 'subject'
    data_table = array2table(data_sorted', 'VariableNames', sorted_table.Subject, 'RowNames', sorted_table.Properties.VariableNames(1:end-1));
    % 将行名数据放置到表格
    data_table.ROI = data_table.Properties.RowNames;
    % 将新列移动到表格的第一列
    data_table = [data_table(:,end), data_table(:,1:end-1)];

    % 将每个ROI的数据写入到Excel的不同sheet中
%     writetable(data_table, excel_output, 'Sheet', sheet_name_t_test, 'FileType', 'spreadsheet', 'WriteMode', 'append');

    %%
    % 为整理成ROC曲线所需要的格式
    % 根据ClassicValue列拆分成3个子表
    classic0 = roi_data(roi_data.ClassicValue == 0, :);
    classic1 = roi_data(roi_data.ClassicValue == 1, :);
    classic2 = roi_data(roi_data.ClassicValue == 2, :);

    % 确定 classic0 和 classic1 的行数
    rows0 = height(classic0);
    rows1 = height(classic1);
    rows2 = height(classic2);

    % 确定要写入的行数为两个表中行数的最大值
    maxRows = max(max(rows0, rows1), rows2);
    
    % 重新命名列名，添加后缀以区分
    classic0.Properties.VariableNames = strcat(classic0.Properties.VariableNames, '_0');
    classic1.Properties.VariableNames = strcat(classic1.Properties.VariableNames, '_1');
    classic2.Properties.VariableNames = strcat(classic1.Properties.VariableNames, '_2');
    
    % 合并两个子表
%     mergedData = [classic0(:, 1:end-1), classic1(:, 1:end-1)]; % 去除ClassicValue列
    writetable(classic0, excel_output, 'Sheet', [sheet_name_ROC, '0'], 'FileType', 'spreadsheet', 'WriteMode', 'append');
    writetable(classic1, excel_output, 'Sheet', [sheet_name_ROC, '1'], 'FileType', 'spreadsheet', 'WriteMode', 'append');
    writetable(classic2, excel_output, 'Sheet', [sheet_name_ROC, '2'], 'FileType', 'spreadsheet', 'WriteMode', 'append');

end

disp(['数据已成功分割到不同的sheet中: ', output_filename]);