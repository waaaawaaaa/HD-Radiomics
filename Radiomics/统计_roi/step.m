% 提取统计值
% 2024/12/16 zhumengying

processed_ROI_t2m   % 对ROI合并  阈值  腐蚀


% 修改mapping后，直接从这里开始做
extract_data  % 保存mat  提取一阶特征


zhengli_excel     %整理成T统计格式，计算均值方差


Ingenia_Elition_t2m    %对健康受试者的两个仪器分类，整理成T统计格式，计算均值方差


%做三组独立测试
test_t2m_3.py
test_t2s_3.py


%%
% 结构像处理
processed_ROI_t2flair  %这个代码有误
extract_data_t2flair


% 结构像处理
processed_ROI_t1W

extract_data_t1w

% 做三组独立测试
test_t1w_3.py


% 看到有人用T1/T2
extract_data_t1w_t2w

% 整理出统计结果
test_mapping_3.py

% 想比较两个仪器
Ingenia_Elition_t2s_5vs5
