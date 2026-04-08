% 计算网络重建结果与模版的差异
% 看看网络学得怎么样，这里我是用的test的数据
% 2024/04/29 zhumengying

clc;clear;
file_path = '/data4/zmy/HD/HD_smri/MoSL_Recon/result/test/model_T2_mask_result_order.mat';
% file_path = '/data4/zmy/reconstruction/result/OLED_T2star_zmy_815_result_OLED_T2.mat';
data=load(file_path);
% x= data.simulate_input;   %[21 256 256 2]  网络的输入
label = data.simulate_label;   %[21 256 256] 给的是T2W
y = data.simulate_output;    %[21 256 256]   slice:21 网络的输出

% 计算每个切片的 SSIM 和 PSNR
num_slices = size(label, 1);
ssim_values = zeros(num_slices, 1);
psnr_values = zeros(num_slices, 1);

for slice = 1:num_slices
    ssim_values(slice) = ssim(y(slice, :, :), label(slice, :, :));
    psnr_values(slice) = psnr(y(slice, :, :), label(slice, :, :));
end

% 计算均值
mean_ssim = mean(ssim_values);
mean_psnr = mean(psnr_values);

% 显示均值结果
disp('T2');
disp('SSIM 平均值:');
disp(mean_ssim);
disp('PSNR 平均值:');
disp(mean_psnr);
