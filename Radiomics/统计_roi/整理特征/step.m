% 调整了一下特征的顺序，将一样的特征挪到后面了
% 2025/04/04   zhumengying

extract_data    % t2m t2s
extract_data_t2s2
extract_data_t1w.m   %  T1W   T2W   T2W_FLAIR

extract_data_t1w_t2w  % 这个显著性也会好点

% 整理出统计结果
test_mapping_3.py
test_T1_mapping_3.py
test_T1t2_mapping_3.py

% 后面也可以接ML代码
% E:\OneDrive - stu.xmu.edu.cn\重建\zmy_code\重建mapping_best\ml