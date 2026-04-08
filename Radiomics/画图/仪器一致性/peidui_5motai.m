% 对健康受试者的两个仪器分类，整理成T统计格式，计算均值方差  5 vs 5
% 想做出图放在论文里，按理来说，做个配对检验+散点图，Bland-Altman 图，证明一致性
% 找出一致性的结果
% 2025/05/21 zhumengying

clc; clear; close all;

% 定义第一组 HC Subject (Ingenia Elition X)
group1_subjects = ["sub004_HC", "sub019_HC", "sub024_HC", "sub026_HC", "sub027_HC"];

hc_27 = ["12","06","11","16","17"];
hc_4 = ["01","02","07","25","22","13"];
for si= 1:length(hc_4)
    dynamic_sub4 = "sub0" + hc_4(si) + "_HC";  % 自动拼接为 string 类型

    for eq = 1:length(hc_27)
        figure;
        dynamic_sub = "sub0" + hc_27(eq) + "_HC";  % 自动拼接为 string 类型
    
        % 定义第二组 HC Subject (Ingenia CX)
        %     group0_subjects = ["sub002_HC", "sub021_HC", "sub023_HC", "sub014_HC", "sub006_HC"];
        group0_subjects = [dynamic_sub4, "sub010_HC", "sub023_HC", "sub015_HC", dynamic_sub];
        
        % 参数设置
        seq_names = {'T2','T2*','T1W','T2W','FLAIR'};
        excel = '腐蚀1_T2_cx';
        file_root = 'H:\重建数据\mapping_unet_best\peizhun\';
        
        filenames = {[file_root 'PD_out_t2m\ROI_processed\T2Mapping_' excel '_zhuzhu.xlsx'],
                    [file_root 'PD_out_t2s\ROI_processed2\T2star_Mapping_' excel '_zhuzhu.xlsx'],
                    [file_root 'Register_jiegouxiang_1vs1\T1W\ROI_processed\T1W_' excel '_mask_zhuzhu.xlsx'],
                    [file_root 'Register_jiegouxiang_1vs1\T2W\ROI_processed\T2W_' excel '_mask_zhuzhu.xlsx'],
                    [file_root 'Register_jiegouxiang_1vs1\T2W_FLAIR\ROI_processed\T2W_FLAIR_' excel '_mask_zhuzhu.xlsx']};  % 替换为你的Excel文件名
        
        for s=1:length(seq_names)
            data = readtable(filenames{s});
            
            % 获取唯一的ROI值列表，并排除 "DN"
            roi_values = {'Ca', 'Pu', 'GPe', 'GPi', 'RN', 'SN', 'TH'};
            % 获取所有 sheet 名称
            roi_values1 = {'CN', 'PU', 'GPe', 'GPi', 'RN', 'SN','TH'};
            
            % 初始化变量，用于存储所有ROI的数据
            all_data0 = [];  % Group0 数据
            all_data1 = [];  % Group1 数据
            bar_x_groups1 = [];
            bar_x_groups0 = [];
            
            % 定义颜色映射表
            color_0 = [202, 200, 239] / 255;  % 浅蓝色（Ingenia CX）
            color_1 = [201, 239, 190] / 255; % 浅黄色（Ingenia Elition X）
            
            subplot(2,3,s);hold on;
            
            % 设置柱形图的宽度和间隔
            bar_width = 0.3;  % 柱形图宽度
            group_offset = 0.6;  % 组之间的间隔
            p_all =[];
            y_max_all =[];
            % 初始化存储变量
            mean0_all = []; % 存储 Group0 的均值
            std0_all = [];  % 存储 Group0 的标准差
            mean1_all = []; % 存储 Group1 的均值
            std1_all = [];  % 存储 Group1 的标准差
            mean_diff_all1 = []; % 存储 Group1 的均值
            std_diff_all1 = [];  % 存储 Group1 的标准差
            
            for i = 1:length(roi_values)
                roi = roi_values{i};  % 使用 {} 运算符来获取单元格中的内容
                roi_data = data(strcmp(data.ROI, roi), :);  % 使用 strcmp 来比较cell中的字符串
                
                sheet_name = roi;  % sheet名称以ROI值命名
            
                % 移除ROI列
                roi_data(:, 'ROI') = [];  % 移除ROI列
                
                % 提取第一组数据，并按指定顺序排列
                [~, idx_group1] = ismember(group1_subjects, roi_data.Subject);
                classic1 = roi_data(idx_group1, :);  
                
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
                % 计算配对数据的差值
                diff_data = data0 - data1;
                mean_diff = mean(diff_data, 'omitnan');  % Group0 均值
                std_diff = std(diff_data, 0, 'omitnan'); % Group0 标准差
                mean_diff_all1 = [mean_diff_all1, mean_diff]; % Group0 均值
                std_diff_all1 = [std_diff_all1, std_diff];   % Group0 标准差
                
                % Shapiro-Wilk 正态性检验
                [h_sw, p_sw] = swtest(diff_data); % 使用下载的 swtest 函数
                
                disp(['ROI: ', roi]);
                disp('正态性检验结果:');
                if h_sw == 0
                    disp('差值满足正态性假设');
                else
                    disp('差值不满足正态性假设');
                end
                
                % 根据正态性检验结果选择合适的检验方法
                if h_sw == 0
                    % 如果差值满足正态性假设，使用配对 t 检验
                    [h, p_value] = ttest(data0, data1); % 配对 t 检验
                    disp('使用配对 t 检验');
                else
                    % 如果差值不满足正态性假设，使用 Wilcoxon 符号秩检验
                    [h, p_value] = signrank(data0, data1); % Wilcoxon 符号秩检验
                    disp('使用 Wilcoxon 符号秩检验');
                end
                
                % 输出检验结果
                disp(['p 值: ', num2str(p_value)]);
                if h == 1
                    disp('两组数据有显著差异');
                else
                    disp('两组数据无显著差异');
                end
                p_all = [p_all,p_value];
            
                %% 计算均值和标准差
                mean0 = mean(data0, 'omitnan');  % Group0 均值
                std0 = std(data0, 0, 'omitnan'); % Group0 标准差
                mean1 = mean(data1, 'omitnan');  % Group1 均值
                std1 = std(data1, 0, 'omitnan'); % Group1 标准差
            
                % 将结果追加到存储变量中
                mean0_all = [mean0_all, mean0]; % Group0 均值
                std0_all = [std0_all, std0];   % Group0 标准差
                mean1_all = [mean1_all, mean1]; % Group1 均值
                std1_all = [std1_all, std1];   % Group1 标准差
            
            
                %% 绘制柱形图
                bar_x_group0 = i - bar_width / 2-0.05;  % Group0 柱形图位置
                bar_x_group1 = i + bar_width / 2+0.05;  % Group1 柱形图位置
            
                % 绘制柱形图
                bar(bar_x_group0, mean0, bar_width, 'FaceColor', color_0, 'EdgeColor', 'none');  % Group0 柱形图
                bar(bar_x_group1, mean1, bar_width, 'FaceColor', color_1, 'EdgeColor', 'none');  % Group1 柱形图
            
                % 叠加散点
                scatter(repmat(bar_x_group0, length(data0), 1), data0, 40, color_0, 'filled', 'MarkerEdgeColor', 'k');
                scatter(repmat(bar_x_group1, length(data1), 1), data1, 40, color_1, 'filled', 'MarkerEdgeColor', 'k');
            
                % 添加配对连接线
                for k = 1:min(length(data0), length(data1))
                    % 配对点的 x 坐标和 y 坐标
                    x_pair = [bar_x_group0, bar_x_group1];
                    y_pair = [data0(k), data1(k)];
                    
                    % 绘制连接线
                    line(x_pair, y_pair, 'Color', 'k', 'LineStyle', '--', 'LineWidth', 1);
                end
                
                %% 添加误差棒
                errorbar(bar_x_group0, mean0, std0, 'k', 'LineStyle', 'none', 'LineWidth', 1.2);
                errorbar(bar_x_group1, mean1, std1, 'k', 'LineStyle', 'none', 'LineWidth', 1.2);
            
                %% 标记显著性
                % 获取y轴范围
                max_y = max([data0; data1]); % 获取柱形图的最大高度
                y_max_all =[y_max_all,max_y];
                bar_x_groups0 = [bar_x_groups0,bar_x_group0];
                bar_x_groups1 = [bar_x_groups1,bar_x_group1];
            
            end
            y_limits = ylim;  % 当前y轴范围
            y_range = y_limits(2) - y_limits(1);  % y轴总高度
            
            height_step = 0.02 * y_range;              % 高度增量为y轴范围的2%
            radius = sqrt(40 / pi) / 2;
            
            for i = 1:length(roi_values)
                sigline([bar_x_groups0(i); bar_x_groups1(i)], y_max_all(i)+radius, p_all(i), height_step);
            end
            
            % 设置 X 轴为 ROI 名称
            xticks(1:length(roi_values));
            xticklabels(roi_values1);
            
        %     % 添加图例，并隐藏图例的边框
        %     lgd = legend({'Ingenia CX', 'Ingenia Elition X'}, 'Location', 'north');
        %     lgd.Box = 'off'; % 隐藏图例的边框
            
            % title(['Bar Plot for ', seq_name]);
            ylabel(['Mean ', seq_names{s}, ' value (ms)']);
            
            hold off;
        end
    
        % 将 string 数组合并成一个字符串，用逗号分隔
        subject_list = strjoin(group0_subjects, ", ");
        
        % 添加标题
        sgtitle(subject_list, 'Interpreter', 'none');  % 避免下划线被识别为 LaTeX
    end
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