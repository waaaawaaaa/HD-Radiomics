% 给T1W/T2W直接乘上T2w的mask，会好看一丢丢
% 2025/08/02 zhumengying

base_name = 'sub011_HC';  %sub011_HC  sub022 
input_file = fullfile('H:\重建数据\mapping_unet_best\normalize_99_mask\t1w_t2w', [base_name, '_t1w_t2w_normalized.nii.gz']);
t2wfile = fullfile('H:\重建数据\mapping_unet_best\swapdim\', 't2W', [base_name, '_' 't2W' '_normalized.nii.gz']);

nii_data = niftiread(input_file);
nii_info = niftiinfo(input_file);
t2w_data = niftiread(t2wfile);

% 将T2W转成mask（假设非零值为感兴趣区域）
t2w_mask = t2w_data ~= 0;

% 将mask乘上nii_data
nii_data_masked = nii_data .* t2w_mask;
imshow3D(nii_data_masked)

% 构建输出文件名
output_filename = fullfile('H:\重建数据\mapping_unet_best\swapdim\', 'T1W_T2W', [base_name '_' 'T1W_T2W' '_normalized.nii']);

% 保存修改后的 NIfTI 数据为新文件
niftiwrite(nii_data_masked, output_filename, nii_info, 'Compressed', true);
disp(['NIfTI 文件保存成功：', output_filename]);