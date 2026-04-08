% 看一下brain中label的顺序,也可以显示不同受试者同一层的图像
% 2024/04/15 zhumengying

clear; clc;

% 设置文件夹路径
sequence = 'OLED_T2star';
folder_path = ['G:/重建数据/charles_network/' sequence];
% srcUrl = "/DATA2023/zmy/smri_hd/OLED_T2/charles_output/fetal_500.Charles";
% 获取文件列表
file_pattern = 'sub*s14.Charles'; % 匹配文件名模式
file_list = dir(fullfile(folder_path, file_pattern)); % 获取匹配的文件列表
num_files = min(36, numel(file_list)); % 获取文件总数，最多读取前21个文件

h = 256;
w = 256;

% 设置拼接后的行数和列数
num_rows = 4;
num_cols = 9;

% 创建一个用于存储拼接后图像的数组
tiled_image = zeros(num_rows * h, num_cols * w);
tiled_ksp = zeros(num_rows * 128, num_cols * 128);

% 逐个读取文件并拼接数据
for i = 1:num_files
    % 读取数据
    file_name = file_list(i).name;
    file_path = fullfile(folder_path, file_name);
    all_data = 1*Binary2D_reader(file_path, h, w);
    % 第一个图像
    k1_image = all_data(1,:,:) + 1i*all_data(2,:,:);
    
    k1_kspace = fft2c(squeeze(k1_image));
    
    GT = all_data(3,:,:);

% 将每个slice填充到拼接后的图像数组中
    row = floor((i - 1) / num_cols) + 1;
    col = mod(i - 1, num_cols) + 1;
    slice = rot90(squeeze(k1_image));
    tiled_image((row - 1) * h + 1 : row * h, (col - 1) * w + 1 : col * w) = slice;
    tiled_ksp((row - 1) * 128 + 1 : row * 128, (col - 1) * 128 + 1 : col * 128) = k1_kspace(65:192,65:192);
end

% 显示拼接后的图像
figure;
imshow(tiled_image, [0 1]); % 设置显示范围
title('brain,label平铺拼接后的图像');
colormap jet;colorbar;
% figure;
% imshow(tiled_ksp, [0 1]); % 设置显示范围
% title('brain,k space平铺拼接后的图像');
% colormap jet;colorbar;