% 因为后面的配准直接在软件上做，需要先转成.nii格式
% 将网络输出的.mat文件转成nii.gz文件，需要每一个受试者每一个受试者转，256*256*21
% 再服务器上无法解压超过2G的.gz文件，在本地电脑上弄
% 将缩放倍数改成1，不会影响后面的去颅骨
% 2024/12/11 zhumengying

clc;clear;
file_root = 'H:\重建数据\dcm_to_nii\HC\';
out_root = 'H:\重建数据\mapping_unet_best\2nii\T2Mapping_Elition_HC\'; %保存路径
file_path = ['H:\重建数据\mapping_unet_best\2nii\model_T2_mask_Elition_HC_order.mat'];  %输入文件
% file_path = '/data4/zmy/reconstruction/result/OLED_T2star_zmy_815_result_OLED_T2.mat';
existing_nii_path = [file_root 'OLED_T2raw\']; %原始.NII文件的路径

data=load(file_path);
% x= data.simulate_input;   %[21 256 256 2]  网络的输入
label = data.simulate_label;   %[21 256 256] 给的是T2W
y = data.simulate_output;    %[21 256 256]   slice:21 网络的输出

% 检查输出文件夹是否存在，如果不存在，则创建
if ~exist(out_root, 'dir')
    mkdir(out_root);
end

slice=21;

num_subjects = size(y, 1) / slice; % 每个受试者有21层，计算受试者数量

for sub = 1:num_subjects
% for sub = 31:35
    % 选择要拼接的slice范围
    start_slice = (sub-1)*slice+1;
    end_slice = sub*slice;

    % 将所选范围的slice拼接成一个3D数组
    y_slices = y(start_slice:end_slice, :, :);

%     % 使用 permute 函数进行维度变换
%     t2mapping = permute(data, [2, 3, 1]); % 将维度由 [slices, h, w] 变换为 [h, w, slices]
    
    % 初始化堆叠后的数组
    t2mapping = [];
    
    % 将每个slice填充到拼接后的图像数组中
    for i = 1:end_slice - start_slice + 1
        y_slice = rot90(squeeze(y_slices(i, :, :)),1);

        if isempty(t2mapping)
            t2mapping = y_slice;
        else
            t2mapping = cat(3, t2mapping, y_slice);%正着拼接
%             t2mapping = cat(3, y_slice, t2mapping);%倒着拼接
        end
          
    end

    sub_filename = ['sub' num2str(sub, '%03d')];


%     histogram(t2mapping)
%     percentile = prctile(t2mapping(:), 70); % 找到40%位置的百分位数
%     imshow3D(t2mapping,[percentile,2])

    % 读取现有 NIfTI 文件的头信息和数据
    existing_nii_file = [existing_nii_path sub_filename '_OLED_T2.nii.gz']; 
    nii_info = niftiinfo(existing_nii_file); % 假设现有的 NIfTI 文件名为 existing_nii_file.nii
    nii_data = niftiread(nii_info);

    
    % 确保 MATLAB 数据与 NIfTI 数据的大小相匹配
    assert(isequal(size(t2mapping), size(nii_data)), 'MATLAB 数据与 NIfTI 数据的大小不匹配。');

    % 将 MATLAB 数据的值赋值给 NIfTI 数据
    nii_data_new = t2mapping;

%     输出文件名
    output_filename = [out_root sub_filename '_HC_T2Mapping.nii'];


    % 将数据类型设置为单精度
    nii_info.Datatype = 'single';
    %将缩放倍数改成1，不会影响后面的去颅骨
    nii_info.raw.scl_slope = 1;
    nii_info.MultiplicativeScaling = 1;
    
    % 保存修改后的 NIfTI 数据为新文件
    niftiwrite(nii_data_new, output_filename, nii_info, compressed=true);
    
%     % 创建 NIfTI 结构体
%     t2mapping_nii = make_nii(t2mapping);
% 
%     if sub<9  % 在前面整理实采数据的时候，因为sub009的尺寸是288*288，就给跳过了
%         output_filename = [out_root 'Subject ' num2str(sub, '%03d') ' _T2Mapping.nii.gz'];
%     else
%         output_filename = [out_root 'Subject ' num2str(sub+1, '%03d') ' _T2Mapping.nii.gz'];
%     end
%     
%     % 保存为.nii.gz文件
%     save_nii(t2mapping_nii, output_filename);

    % 显示结果
    disp(['Finished: ' output_filename]);
end