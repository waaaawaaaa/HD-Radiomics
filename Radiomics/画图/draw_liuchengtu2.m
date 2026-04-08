% oled 幅值和相位
inputFile='H:\重建数据\dcm_to_nii\HC\OLED_T2raw\sub011_OLED_T2.nii.gz';
nii_data = niftiread(inputFile);
figure();imshow(nii_data(:,:,12),[]);
% colormap jet;colorbar

inputFile='H:\重建数据\dcm_to_nii\HC\OLED_T2raw\sub011_OLED_T2_ph.nii.gz';
nii_data = niftiread(inputFile);
figure();imshow(nii_data(:,:,12),[]);
% colormap jet;colorbar

%mapping
inputFile='H:\重建数据\zmy_final\dcm_to_nii\T2Mapping\sub011_HC_T2Mapping.nii.gz';
nii_data = niftiread(inputFile);
figure();imshow(nii_data(:,:,12),[0,2]);
colormap jet;%colorbar

inputFile='H:\重建数据\ants_data\qulugu_fsl\T1W\sub011_HC_T1W_brain.nii.gz';
nii_data = niftiread(inputFile);
imshow(nii_data(:,:,13),[]);

inputFile='H:\重建数据\ants_data\qulugu_fsl\T2W\sub011_HC_T2W_brain.nii.gz';
nii_data = niftiread(inputFile);
imshow(nii_data(:,:,13),[]);

inputFile='H:\重建数据\mapping_unet_best\normalize_99_mask\T1W\sub001_T1W_normalized.nii.gz';
nii_data = niftiread(inputFile);
figure();imshow(nii_data(:,:,13),[]);

inputFile='H:\重建数据\mapping_unet_best\normalize_99_mask\T2W\sub001_T2W_normalized.nii.gz';
nii_data = niftiread(inputFile);
figure();imshow(nii_data(:,:,13),[]);

inputFile='H:\重建数据\mapping_unet_best\normalize_99_mask\T2W_FLAIR\sub001_T2W_FLAIR_normalized.nii.gz';
nii_data = niftiread(inputFile);
figure();imshow(nii_data(:,:,13),[]);

inputFile='H:\重建数据\fsl\AAL配准\MNI152_T1_1mm_brain_mask_zmy.nii.gz';
nii_data = niftiread(inputFile);
figure();imshow(nii_data(:,:,84),[]);

seqFile_t1w = 'H:\重建数据\mapping_unet_best\peizhun\Register_jiegouxiang_t1_2_t2\T1W_2_t2w\sub001_T1W_Warped.nii.gz';
seq_T1W_image = niftiread(seqFile_t1w);
inputFile='H:\重建数据\mapping_unet_best\normalize_99_mask\T2W\sub001_T2W_normalized.nii.gz';
nii_data = niftiread(inputFile);
MASK = nii_data > 0;
image = seq_T1W_image./nii_data;
% 替换结果中的 NaN 和 Inf 值
image(isnan(image)) = 0; % 替换 NaN
image(isinf(image)) = 0; % 替换 Inf   [0,15]
image = image.*MASK;

% 将图像数据归一化到 [0, 1] 范围
nii_data_min = min(image(:));  % 获取图像的最小值
%         nii_data_max = max(nii_data(:));  % 获取图像的最大值
nii_data_max = prctile(image(image>0),99);  % 采用95%的值作为最大值来归一化
image_normalized = (image - nii_data_min) / (nii_data_max - nii_data_min);  % 归一化
figure();imshow(image_normalized(:,:,13),[0,0.6]);
hfh_1 = imfreehand();
brain_ROI_slice = createMask(hfh_1);
figure();imshow(image_normalized(:,:,13).*brain_ROI_slice,[0,0.6]);

% 配准后
inputFile='H:\重建数据\mapping_unet_best\peizhun\PD_out_t2m\T2W\sub011_HC_T2W_Warped.nii.gz';
nii_data = niftiread(inputFile);
figure();imshow(nii_data(:,:,12));
hfh_1 = imfreehand();
brain_ROI_slice = createMask(hfh_1);
figure();imshow(nii_data(:,:,12).*brain_ROI_slice);

inputFile='H:\重建数据\mapping_unet_best\peizhun\PD_out_t2m\T1W\sub011_HC_T1W_Warped.nii.gz';
nii_data = niftiread(inputFile);
figure();imshow(nii_data(:,:,12));
hfh_1 = imfreehand();
brain_ROI_slice = createMask(hfh_1);
figure();imshow(nii_data(:,:,12).*brain_ROI_slice);

%配准后
inputFile='H:\重建数据\zmy2\bet_brain_extraction\T2Mapping0.45\sub001_T2Mapping_brain.nii.gz';
nii_data = niftiread(inputFile);
imshow(nii_data(:,:,11),[0,2]);
colormap jet;

inputFile='H:\重建数据\ants_data\PD_out_all2\T1W\sub001_T1W_Warped.nii.gz';
nii_data = niftiread(inputFile);
imshow(nii_data(:,:,11),[]);

inputFile='H:\重建数据\ants_data\PD_out_all2\T2W\sub001_T2W_Warped.nii.gz';
nii_data = niftiread(inputFile);
imshow(nii_data(:,:,11),[]);

inputFile='H:\重建数据\ants_data\PD_out_all2\T2star_Mapping\sub001_T2star_Mapping_Warped.nii.gz';
nii_data = niftiread(inputFile);
imshow(nii_data(:,:,11),[0 2]);
colormap jet;