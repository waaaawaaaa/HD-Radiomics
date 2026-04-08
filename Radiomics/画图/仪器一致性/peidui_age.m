%一致性检验，年龄
% 2025/05/21 zhumengying
clc,clear

% 提取需要的特征列
data0 = single([50,56,71,30,34]);  % 对应的是均值特征
data1 = single([52,69,64,23,33]);

%% 统计检验
% 计算配对数据的差值
diff_data = data0 - data1;
mean_diff = mean(diff_data, 'omitnan');  % Group0 均值
std_diff = std(diff_data, 0, 'omitnan'); % Group0 标准差
fprintf('Mean Difference: %.4f\n', mean_diff);
fprintf('Standard Deviation: %.4f\n', std_diff);

% Shapiro-Wilk 正态性检验
[h_sw, p_sw] = swtest(diff_data); % 使用下载的 swtest 函数

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