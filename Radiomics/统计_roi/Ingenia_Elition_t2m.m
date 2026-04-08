% GraphPad Prism 不能用代码操作，所以将前面得到的Excel表格整理出来
% 对健康受试者的两个仪器分类，整理成T统计格式，计算均值方差
% 2024/12/31 zhumengying

clc;clear;

seq = 'T2Mapping';
excel='腐蚀1_T2_cx';
file_root = 'H:\重建数据\mapping_unet_best\peizhun\PD_out_t2m\ROI_processed\';
filename = [file_root seq '_' excel '.xlsx'];  % 替换为你的Excel文件名
data = readtable(filename);

% 创建一个新的Excel文件用于存储结果
output_filename = [seq,'_两仪器比较5vs5.xlsx'];
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

    % 假设 sorted_table 是已经排序的数据表
    % 定义第一组 HC Subject
    group1_subjects = ["sub004_HC", "sub019_HC", "sub024_HC", "sub026_HC", "sub027_HC"];
    
    % 提取第一组数据
    classic1 = sorted_table(ismember(sorted_table.Subject, group1_subjects), :);
    
    % 提取第二组数据（其他 HC Subject）
    % 使用逻辑条件来排除第一组中的 Subject
    group0_subjects = ["sub001_HC", "sub025_HC", "sub021_HC", "sub028_HC", "sub012_HC"];
    classic0 = sorted_table(ismember(sorted_table.Subject, group0_subjects), :);
%     classic0 = sorted_table(~ismember(sorted_table.Subject, group1_subjects) & endsWith(sorted_table.Subject, '_HC'), :);
    mean_values0 = mean(classic0{:, 1:end-1}, 'omitnan');  % 根据列计算均值，排除 NaN
    std_values0 = std(classic0{:, 1:end-1}, 0, 1, 'omitnan');  % 根据列计算标准差，排除 NaN

    mean_values1 = mean(classic1{:, 1:end-1}, 'omitnan');  % 根据列计算均值，排除 NaN
    std_values1 = std(classic1{:, 1:end-1}, 0, 1, 'omitnan');  % 根据列计算标准差，排除 NaN

    data0 =single(classic0{:, 1:end-1}); 
    data1=single(classic1{:, 1:end-1});

    % 对每一列进行曼-惠特尼 U 检验
    for tz = 1:size(data0, 2)-3
        [p_values(tz), h_values(tz)] = ranksum(data0(:, tz), data1(:, tz));
    end
    
    % 保留两位小数
    mean_values0 = round(mean_values0, 2);
    std_values0 = round(std_values0, 2);
    mean_values1 = round(mean_values1, 2);
    std_values1 = round(std_values1, 2);

    % 提取数据部分，不包括行名和变量名
    data_sorted0 = classic0{:, 1:end-1};  % classic0 数据
    data_sorted1 = classic1{:, 1:end-1};  % classic1 数据
    
    % 将数据转换为一个新的表格，每一行数据作为一列，转置了
    data_table0 = array2table(data_sorted0', 'VariableNames', classic0.Subject, 'RowNames', classic0.Properties.VariableNames(1:end-1));
    data_table1 = array2table(data_sorted1', 'VariableNames', classic1.Subject, 'RowNames', classic1.Properties.VariableNames(1:end-1));
    % 合并两个表格（如果需要）
    data_table = [data_table0 data_table1];  % 将两个表格在行上合并   
%     % 将数据转换为一个新的表格，每一行数据作为一列，列名为 'subject' 转置了
%     data_table = array2table(data_sorted', 'VariableNames', sorted_table.Subject, 'RowNames', sorted_table.Properties.VariableNames(1:end-1));
    % 将行名数据放置到表格
    data_table.ROI = data_table.Properties.RowNames;
    % 将新列移动到表格的第一列
    data_table = [data_table(:,end), data_table(:,1:end-1)];
    data_table.mean0 = mean_values0';
    data_table.std0 = std_values0';
    data_table.mean1 = mean_values1';
    data_table.std1 = std_values1';
    data_table.P = [p_values 0 0 0]';
    data_table.H = [h_values 0 0 0]';


    % 将每个ROI的数据写入到Excel的不同sheet中
    writetable(data_table, excel_output, 'Sheet', sheet_name, 'FileType', 'spreadsheet', 'WriteMode', 'append');
end

disp(['数据已成功分割到不同的sheet中: ', output_filename]);