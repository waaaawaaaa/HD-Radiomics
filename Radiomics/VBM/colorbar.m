close all;
% 设置 colorbar 参数
colorbar_length = 256;
colorbar_height = 30;

% 创建 colorbar 数据（例如：从 0.95 到 0.05）
x = linspace(0.95, 0.05, colorbar_length);
colorbar_data = repmat(x, colorbar_height, 1);

% 创建图像
figure('Position', [100, 100, 600, 60]);
imagesc(colorbar_data);
colormap(hot);  % 使用 hot 颜色映射
axis off;
% title('Hot Colorbar with Labels Outside', 'FontSize', 14);

% 设置坐标轴范围（手动控制绘图区域）
xlim([0, colorbar_length + 100]);  % 扩展右边空间写标签
ylim([0, colorbar_height]);

% 添加最小值标签（写在 colorbar 左边外面）
text(-10, colorbar_height / 2, '0', ...
    'Color', 'k', ...       % 黑色字体
    'FontSize', 14, ...
    'VerticalAlignment', 'middle', ...
    'HorizontalAlignment', 'right');

% 添加最大值标签（写在 colorbar 右边外面）
text(colorbar_length + 10, colorbar_height / 2, '0.05', ...
    'Color', 'k', ...
    'FontSize', 14, ...
    'VerticalAlignment', 'middle', ...
    'HorizontalAlignment', 'left');

% 创建灰度 colorbar 数据
x_gray = linspace(0, 1, colorbar_length);
gray_data = repmat(x_gray, colorbar_height, 1);

figure('Position', [100, 100, 600, 60]);
imagesc(gray_data);
colormap(gray);
axis off;
% title('Gray Colorbar with Labels Outside', 'FontSize', 14);

% 设置绘图区域范围
xlim([0, colorbar_length + 100]);
ylim([0, colorbar_height]);

% 添加标签
text(-10, colorbar_height / 2, '0', ...
    'Color', 'k', 'FontSize', 14, ...
    'VerticalAlignment', 'middle', 'HorizontalAlignment', 'right');

% 添加最大值标签（写在 colorbar 右边外面）
% 添加最大值标签（写在 colorbar 右边外面，紧凑排布）
label_offset_x = 10;  % 标签离 colorbar 的横向距离（更小）
text(colorbar_length + label_offset_x, colorbar_height - 13, '100%', ...
    'Color', 'k', ...
    'FontSize', 14, ...
    'VerticalAlignment', 'top', ...
    'HorizontalAlignment', 'left');

text(colorbar_length + label_offset_x, 13, '200ms', ...
    'Color', 'k', ...
    'FontSize', 14, ...
    'VerticalAlignment', 'bottom', ...
    'HorizontalAlignment', 'left');