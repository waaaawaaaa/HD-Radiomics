% 感觉sub32的T2W比较蓝，看看是怎么回事
% 2024/04/27 朱梦莹

clear; clc;

% 设置文件夹路径
sequence = 'T2W_TSE';
folder_path = ['G:/重建数据/extract/sub009/' sequence];
% srcUrl = "/DATA2023/zmy/smri_hd/OLED_T2/charles_output/fetal_500.Charles";
% 获取文件列表
file_pattern = 'I*'; % 匹配文件名模式
file_list = dir(fullfile(folder_path, file_pattern)); % 获取匹配的文件列表
num_files = min(21, numel(file_list)); % 获取文件总数，最多读取前21个文件

h = 560;
w = 560;

% 设置拼接后的行数和列数
num_rows = 3;
num_cols = 7;

% 创建一个用于存储拼接后图像的数组
tiled_image = zeros(num_rows * h, num_cols * w);
tiled_ksp = zeros(num_rows * 128, num_cols * 128);

% 逐个读取文件并拼接数据
for i = 1:num_files
    % 读取数据
    file_path = fullfile(folder_path, ['I',num2str(i*10)]);
    
    image = dicomread(file_path);
    image = im2double(image);

% 将每个slice填充到拼接后的图像数组中
    row = floor((i - 1) / num_cols) + 1;
    col = mod(i - 1, num_cols) + 1;
    slice = squeeze(image);
    tiled_image((row - 1) * h + 1 : row * h, (col - 1) * w + 1 : col * w) = slice;
end

% 显示拼接后的图像
figure;
imshow(tiled_image, [0,0.02]); % 设置显示范围
title('brain,label平铺拼接后的图像');
colormap jet;colorbar;
