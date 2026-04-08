% 对我特征的统计结果画图, 拼接称一张大图
% 2025/04/11  zhumengying

mergeFiguresIntoSubplots('t2star_mapping', 4, 4)
function mergeFiguresIntoSubplots(outputFileName, rows, cols)
    % 合并多个 figure 成子图形式
    %
    % 参数:
    %   outputFileName: 输出文件名（例如 'merged_subplots.png'）
    %   rows: 子图的行数
    %   cols: 子图的列数

    % 获取所有打开的 figure 句柄
    figHandles = findall(groot, 'Type', 'figure');
    
    % 检查是否有足够的 figure
    if isempty(figHandles)
        error('没有找到任何打开的 figure。');
    elseif length(figHandles) > rows * cols
        warning('打开的 figure 数量超过指定的布局大小，多余的 figure 将被忽略。');
    end

    % 创建新的 figure 用于绘制子图
    figure;
    set(gcf, 'Units', 'normalized', 'Position', [0.1, 0.1, 0.8, 0.8]);  % 设置窗口大小

    % 遍历每个 figure 并将其作为子图绘制
    for i = 1:min(length(figHandles), rows * cols)
        % 当前 figure
        fig = figHandles(i);

        % 捕获当前 figure 的内容
        frame = getframe(fig);  % 获取 figure 的图像数据
        img = frame2im(frame);  % 转换为图像矩阵

        % 创建子图
        subplot(rows, cols, i);
        imshow(img);  % 显示捕获的图像
        axis off;     % 关闭坐标轴
        title(['Figure ', num2str(i)]);  % 添加标题
    end

    % 调整子图间距
    tightfig;  % 自动调整子图间距

    % 保存拼接后的子图
    if ~isempty(outputFileName)
        saveas(gcf, outputFileName);  % 保存为文件
        disp(['子图已保存为: ', outputFileName]);
    end
end

%% 辅助函数：自动调整子图间距
function tightfig()
    % 自动调整子图间距
    set(gca, 'LooseInset', get(gca, 'TightInset'));
    drawnow;
end