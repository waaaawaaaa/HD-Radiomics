% 亨廷顿舞蹈症的图像重建
% 2024  zhumengying

%% 1、整理数据
% 全部解压缩
unzip_file  %sub001还要手动添加一个受试者名的文件夹统一一下
% 发现序列ID在不同受试者之间对应不上的问题
Series_Description  %查看序列
differ_info   %查看两图像头文件差异
% 发现同一序列基本没有差异，采集顺序的原因
extract_file %要提取的序列名，放到另一个文件中 提取的是第一个符合条件的序列
extract_file_fix  %提取的是最后一个符合条件的序列
%有极个别层数多了一个，打不开，直接删掉
del_empty_file  %写了个Excel文件，可以看到删了之后的文件数


%% 2、转成实部和虚部
% 整理成网络需要格式

% 查看噪声
SNR_caculate   %发现采的数据加了mask，算不了噪声


%查看t2w的顺序
show_label_order

%将.dcm文件转成.nii文件  为后面配准做准备
% dcm_to_nii   %T1W  有点不对，直接用MRICRO GL转
batch_dcm2nii  %T1W 
OLED_dcm2nii   %要保留原来OLED采集的头文件，转原始的dcm到nii，再用网络跑出来的结果替换它

git_save  %将nii文件保存成GIT，方便放在PPT里演示
