% 对我特征的统计结果画图
% 2025/04/11 zhumengying

clc; clear;close all;

% 读取数据
seq = 't1w_t2w';  % T2Mapping 或 T2star_Mapping
excel = '腐蚀1_T2_cx_mask4';
file_root = 'H:\重建数据\mapping_unet_best\peizhun\Register_jiegouxiang_1vs1\T2W\ROI_processed';
% filename = fullfile(file_root, [seq '_' excel '0.xlsx']);
filename = fullfile(file_root, ['test3_' seq '_' excel '.xlsx']);

% 获取所有 sheet 名称
roi_values = {'Ca', 'Pu', 'GPe', 'GPi', 'TH', 'RN', 'SN', 'DN'};
roi_names = {'CN', 'PU', 'GPe', 'GPi', 'TH', 'RN', 'SN', 'DN'};

% 初始化一个 cell 数组存储每个 sheet 的数据
all_data = cell(length(roi_values), 1);

% 循环读取每个 sheet 的数据
for i = 1:length(roi_values)
    sheet_name = roi_values{i};
    all_data{i} = readtable(filename, 'Sheet', sheet_name);
    fprintf('已读取 sheet: %s\n', sheet_name);
end

features_name = all_data{1,1}{1:13,'ROI'};
features_danwei = {'','','','','','','','','','','','','(mm^3)'};

% 遍历每个特征并绘制分组箱线图
for j = 1:length(features_name)
    feature = features_name{j};  % 当前特征
    figure(); hold on;
    
    all_data_combined = [];
    group_positions = [];  % 存储每个箱体的位置
    mean_tezheng = [];
    all_test = [];
    
    box_gap = 0.5;  % 组内箱体之间的间距系数，值越小箱体越靠近
    group_gap = 0.7;  % 每个 ROI 组之间的间距系数

    % 将 RGB 值归一化到 [0, 1] 范围
    color_HC = [240, 155, 160] / 255;       % 浅红色
    color_pre_HD = [234, 184, 131] / 255;   % 橙色
    color_HD = [155, 187, 225] / 255;      % 浅蓝色
    filledcolor1 = [46,114,188]/255;
    
    % 初始化组的偏移量
    current_position = 0;
    
    for i = 1:length(roi_values)
        roi = roi_values{i};  % 当前 ROI
        ROI_data = all_data{i,1};
        roi_data = ROI_data(:,1:end-16);  % 筛选出当前 ROI 的数据
        % 更新列名
        roi_data.Properties.RowNames = ROI_data{:, 1};
        roi_data = roi_data(:, 2:end);
        
        roi_test = ROI_data(j,end-14:end);
        roi_test.Properties.RowNames = strcat(roi, '_', ROI_data.ROI(j));
        % 假设 all_test 是最终合并的表格，roi_test 是当前要添加的表格
        if isempty(all_test)  % 初始化
            all_test = roi_test;
        else      
            % 假设 all_test 是主表，roi_test 是要合并的子表
            try
                all_test = [all_test; roi_test];  % 垂直合并
            catch ME
                % 检查错误类型
                if contains(ME.message, '无法串联表变量')
                    disp('列数据类型不一致，正在自动修复...');
                    % 获取所有列名
                    common_vars = intersect(all_test.Properties.VariableNames, roi_test.Properties.VariableNames);
                    % 统一数据类型（强制转为元胞数组）
                    for var = common_vars
                        var_name = var{1};
                        if ~isequal(class(all_test.(var_name)), class(roi_test.(var_name)))
                            roi_test.(var_name) = num2cell(roi_test.(var_name));
                            all_test.(var_name) = num2cell(all_test.(var_name));
                        end
                    end
                    all_test = [all_test; roi_test];  % 重新合并
                else
                    error('合并失败: %s', ME.message);
                end
            end
           
        end

        mean_tezheng = [mean_tezheng, roi_test.mean_hc,roi_test.mean_pre_hd,roi_test.mean_hd];

        % 提取当前特征的数据
        feature_data = roi_data{j, :};
        class_row_index = strcmp(roi_data.Properties.RowNames, 'ClassicValue');
        class_data = roi_data{class_row_index, :};
        feature_HC = feature_data(class_data == 0);
        feature_pre_HD = feature_data(class_data == 1);
        feature_HD = feature_data(class_data == 2);

        % Find the maximum length among the three groups
        max_length = 27;
        
        % Pad the shorter vectors with NaNs
        feature_HC_pad = padarray(feature_HC', [max_length - length(feature_HC), 0], NaN, 'post');
        feature_pre_HD_pad = padarray(feature_pre_HD', [max_length - length(feature_pre_HD), 0], NaN, 'post');
        feature_HD_pad = padarray(feature_HD', [max_length - length(feature_HD), 0], NaN, 'post');

        % 组合数据
        all_data_combined = [all_data_combined,feature_HC_pad,feature_pre_HD_pad,feature_HD_pad]; 

        % 更新组的位置
        group_positions = [group_positions, current_position, current_position + box_gap, current_position + 2 * box_gap];

        current_position = current_position + 2*box_gap + group_gap;  % 增加位置间隔
        
    end
%     ax1 = axes;  % 主坐标轴
    % 绘制箱线图
    boxplot(all_data_combined, 'colors', 'k', 'symbol', '', 'Widths',0.4, 'positions',group_positions);
    y_max = find_max_box(all_data_combined);
    y_min = find_min_box(all_data_combined);
    range = y_max - y_min;
    ylim([y_min-range*0.02, y_max+range*0.07]);  % 设置主 Y 轴范围为 0~0.1
    
    scatter(group_positions, mean_tezheng, '*', 'Color', filledcolor1)


    % 获取箱体的所有对象（boxes, whiskers, medians, outliers）
    h = findobj(gca, 'Tag', 'Box');
    
    % 获取所有箱体的数量
    num_boxes = length(h);
    
    % 遍历每个箱体并设置颜色
    for k = 1:num_boxes
        % 算出这是第几个 ROI 的哪种组
        box_idx = num_boxes - k + 1;  % 反向索引
        group_type = mod(box_idx-1, 3) + 1;  % HC:1, pre-HD:2, HD:3
    
        % 根据组别选择颜色
        switch group_type
            case 1
                this_color = color_HC;
            case 2
                this_color = color_pre_HD;
            case 3
                this_color = color_HD;
        end
    
        % 填充箱体颜色
        patch(get(h(k), 'XData'), get(h(k), 'YData'), this_color, 'FaceAlpha', 0.6, 'EdgeColor', 'k');
    end

    % 获取 whisker 和 median 的对象
    h_whiskers = findobj(gca, 'Tag', 'Whisker');
    h_medians = findobj(gca, 'Tag', 'Median');
    
    % 修改 whisker 和 median 的颜色
    set(h_whiskers, 'Color', 'k');  % whiskers 设置为黑色
    set(h_medians, 'LineWidth', 1.5);  % median 设置为更粗

    xticks(group_positions(3*(1:length(group_positions) / 3) - 1));
    xticklabels(roi_names );

    % 添加每组之间的垂直分隔虚线
    n_rois = length(roi_values);
    for i = 1:(n_rois)
        % 标出显著性
        sig(all_data_combined(:,3*i-2:3*i), all_test(i,:), group_positions(:,3*i-2:3*i));

        % 找出当前组最后一个箱体的位置（即每组的最后一个位置）
        line_x = group_positions(3*i) + group_gap/2;  % 加一点偏移，让线更居中
        
        % 获取当前 y 轴范围
        y_limits = ylim;
    
        % 绘制虚线
        plot([line_x, line_x], y_limits, '--', 'Color', [0.5 0.5 0.5], 'LineWidth', 1);
    end

    % 调整图形美观
%     title(['特征: ', feature], 'Interpreter', 'none')
    ylabel([feature ' ' features_danwei{j}])
    set(gca, 'FontSize', 10)
    box off;    
end

function sigline(x, y, p, height_step)
    % 输入检查
    if nargin < 4
        error('需输入 x, y, p, height_step 四个参数');
    end
    x = x(:)';  % 确保x为行向量
     
    % 显著性标记（根据p值添加*号）
    if p < 0.001
        text(mean(x), y, '***', ...
             'HorizontalAlignment', 'center', 'VerticalAlignment', 'bottom', ...
             'FontSize', 11, 'FontWeight', 'bold');
    elseif (0.001 <= p) && (p < 0.01)
        text(mean(x), y, '**', ...
             'HorizontalAlignment', 'center', 'VerticalAlignment', 'bottom', ...
             'FontSize', 11, 'FontWeight', 'bold');
    elseif (0.01 <= p) && (p < 0.05)
        text(mean(x), y, '*', ...
             'HorizontalAlignment', 'center', 'VerticalAlignment', 'bottom', ...
             'FontSize', 11, 'FontWeight', 'bold');
    else
        text(mean(x), y+height_step, 'ns', ...
             'HorizontalAlignment', 'center', 'VerticalAlignment', 'bottom', ...
             'FontSize', 9, 'FontWeight', 'bold');
    end
    
    % 绘制显著性线（水平线+固定长度的垂直线）
    plot(x, [y+height_step,y+height_step], '-k', 'LineWidth', 1);                  % 水平线
    plot([1; 1]*x(1), [y, y+height_step], '-k', 'LineWidth', 1); % 左垂直线
    plot([1; 1]*x(2), [y, y+height_step], '-k', 'LineWidth', 1); % 右垂直线
    
end

%% 标记显著性
function sig(all_data_combined_roi, all_test_roi, group_positions_roi)
    %% 标记显著性
    % 检查总体显著性
    if all_test_roi.p_test >= 0.05
%         disp('无显著性差异');
        return;
    end

    % 获取y轴范围
    y_limits = ylim;  % 当前y轴范围
    y_range = y_limits(2) - y_limits(1);  % y轴总高度

    height_step = 0.02 * y_range;              % 高度增量为y轴范围的5%
        
    % 获取最大值作为y轴基准
    y_max = find_max_box(all_data_combined_roi);

    % 初始化显著性线高度倍数
    sig_height_multiplier = 1.05;  % 初始显著性线高度比例
    sig_height_step = 0.05;       % 每层显著性线的高度增量

    % 定义组名及其对应的列索引
    groups = {'hc', 'pre_hd', 'hd'};
    group_indices = [1, 2, 3];  % 对应 group_positions_roi 的列索引

    % 定义组间比较的p值和对应组名
    comparisons = {
        'hc', 'pre_hd', extractCellValue(all_test_roi.hc_vs_pre_hd{1});  % 注意：使用 {} 访问 cell 内容
        'hc', 'hd', extractCellValue(all_test_roi.hc_vs_hd{1});
        'pre_hd', 'hd', extractCellValue(all_test_roi.pre_hd_vs_hd{1})
    };

    % 遍历每一对组，检查显著性并绘制标记
    for i = 1:size(comparisons, 1)
        group1 = comparisons{i, 1};  % 第一组名称
        group2 = comparisons{i, 2};  % 第二组名称
        p_value = comparisons{i, 3}; % 组间p值

        % 检查是否显著
        if p_value >= 0.05
            continue;  % 跳过不显著的组对
        end

        %% 找到组的位置
        idx1 = strcmp(groups, group1);  % 第一组索引
        idx2 = strcmp(groups, group2);  % 第二组索引
        x1 = group_positions_roi(1, group_indices(idx1));  % 第一组x位置
        x2 = group_positions_roi(1, group_indices(idx2));  % 第二组x位置

        % 计算当前显著性线的高度
        current_y = y_max + height_step;

        % 调用sigline函数绘制显著性线
        sigline([x1, x2], current_y-height_step, p_value, height_step);

        % 更新显著性线高度倍数，避免重叠
        y_max = y_max + 2*height_step;
    end
end

%% 递归提取嵌套 cell 中的实际数值
function value = extractCellValue(cellData)
    % 如果是 cell 类型，递归提取内容
    while iscell(cellData)
        if isempty(cellData)
            error('Cell 数据为空，无法提取 p 值');
        end
        cellData = cellData{1};  % 提取第一个元素
    end

    % 确保最终提取的是数值
    if ~isnumeric(cellData)
        value = str2double(cellData);
    else

        value = cellData;  % 返回提取的数值
    end
end

%% 找到箱线图的最大值
function global_max = find_max_box(data)
    % 初始化结果数组
    max_box = NaN(1, size(data, 2));  % 默认值为 NaN

    % 遍历每一列数据
    for col = 1:size(data, 2)
        % 提取当前列数据，并去除 NaN 值
        column_data = data(:, col);
        column_data = column_data(~isnan(column_data));

        % 如果当前列为空，跳过
        if isempty(column_data)
            continue;
        end

        % 计算四分位数
        Q1 = prctile(column_data, 25);  % 第一四分位数
        Q3 = prctile(column_data, 75);  % 第三四分位数
        IQR = Q3 - Q1;                  % 四分位距

        % 计算上边界
        upbound1 = Q3 + 1.5 * IQR;

        % 筛选出小于上边界的数据
        filtered_data = column_data(column_data < upbound1);

        % 如果筛选后的数据为空，记录 NaN；否则计算最大值
        if isempty(filtered_data)
            max_box(col) = NaN;
        else
            max_box(col) = max(filtered_data);
        end
    end
    % 找到所有列最大值中的全局最大值
    % 忽略 NaN 值
    valid_max_box = max_box(~isnan(max_box));
    if isempty(valid_max_box)
        global_max = NaN;  % 如果没有有效值，返回 NaN
    else
        global_max = max(valid_max_box);  % 全局最大值
    end
end

function global_min = find_min_box(data)
    % 初始化结果数组
    min_box = NaN(1, size(data, 2));  % 默认值为 NaN

    % 遍历每一列数据
    for col = 1:size(data, 2)
        % 提取当前列数据，并去除 NaN 值
        column_data = data(:, col);
        column_data = column_data(~isnan(column_data));

        % 如果当前列为空，跳过
        if isempty(column_data)
            continue;
        end

        % 计算四分位数
        Q1 = prctile(column_data, 25);  % 第一四分位数
        Q3 = prctile(column_data, 75);  % 第三四分位数
        IQR = Q3 - Q1;                  % 四分位距

        % 计算下边界
        lowbound1 = Q1 - 1.5 * IQR;

        % 筛选出大于下边界的数据
        filtered_data = column_data(column_data > lowbound1);

        % 如果筛选后的数据为空，记录 NaN；否则计算最小值
        if isempty(filtered_data)
            min_box(col) = NaN;
        else
            min_box(col) = min(filtered_data);
        end
    end

    % 找到所有列最小值中的全局最小值
    % 忽略 NaN 值
    valid_min_box = min_box(~isnan(min_box));
    if isempty(valid_min_box)
        global_min = NaN;  % 如果没有有效值，返回 NaN
    else
        global_min = min(valid_min_box);  % 全局最小值
    end
end