# hd数据特征做机器学习算法需要用到的几个函数
# 2025\03\14   zhumengying

import numpy as np
import pandas as pd

def horizontally_concatenate(features):
    """
    将一个包含多个 DataFrame 的列表按列（横向）拼接，并确保索引对齐。

    参数:
        features (list): 包含多个 DataFrame 的列表，每个 DataFrame 形状为 (49, 16)。

    返回:
        pd.DataFrame: 横向拼接后的 DataFrame，形状为 (49, 16 * len(features))。
    """
    # 确保输入是一个列表
    if not isinstance(features, list) or not all(isinstance(df, pd.DataFrame) for df in features):
        raise ValueError("Input must be a list of DataFrames.")

    # 检查所有 DataFrame 的行数是否一致
    num_rows = features[0].shape[0]
    if not all(df.shape[0] == num_rows for df in features):
        raise ValueError("All DataFrames must have the same number of rows for horizontal concatenation.")

    # 忽略索引，直接按行顺序拼接
    concatenated_df = pd.concat([df.reset_index(drop=True) for df in features], axis=1)

    return concatenated_df

def horizontally_concatenate2(features):
    """
    将一个包含多个 DataFrame 的列表按列（横向）拼接，并确保索引对齐。

    参数:
        features (list): 包含多个 DataFrame 的列表，每个 DataFrame 形状为 (49, 16)。

    返回:
        pd.DataFrame: 横向拼接后的 DataFrame，形状为 (49, 16 * len(features))。
    """
    # 确保输入是一个列表
    if not isinstance(features, list) or not all(isinstance(df, pd.DataFrame) for df in features):
        raise ValueError("Input must be a list of DataFrames.")

    # 检查所有 DataFrame 的行数是否一致
    num_rows = features[0].shape[0]
    if not all(df.shape[0] == num_rows for df in features):
        raise ValueError("All DataFrames must have the same number of rows for horizontal concatenation.")

    # 获取参考索引（以第一个 DataFrame 的索引为准）
    reference_index = features[0].index

    # 对齐所有 DataFrame 的索引
    aligned_features = [df.reindex(reference_index) for df in features]

    # 横向拼接
    concatenated_df = pd.concat(aligned_features, axis=1)

    return concatenated_df

# 加载数据
def load_modality_data(modality_dir):
    """加载单个模态下所有ROI的特征和标签"""
    features = []
    labels = []
    # 读取Excel文件的所有sheet（假设每个sheet对应一个ROI）
    data = pd.read_excel(modality_dir)
    # 获取唯一 ROI
    roi_values = data['ROI'].unique()[:-1]
    # 用于存储第一个 ROI 的标签以进行一致性检查
    reference_labels = None
    # 用于存储所有 ROI 的特征名称
    all_feature_names = []

    # 处理不同 ROI
    for roi in roi_values:
        roi_data = data[data['ROI'] == roi].copy()
        roi_data.drop(columns=['ROI'], inplace=True)

        # 按 'ClassicValue' 排序
        sorted_table = roi_data.sort_values(by='ClassicValue')
        # 获取特征列名称，并添加 ROI 前缀
        feature_names = [f"{roi}_{col}" for col in sorted_table.columns[:-5]]

        # 筛选 ClassicValue 为 0、1、2 的行
        selected_data = sorted_table[sorted_table['ClassicValue'].isin([0, 1, 2])]

        # # 删除最后5列，保留其他列
        # selected_data = selected_data.iloc[:, :-5]

        # 提取特征
        roi_features = selected_data.iloc[:, :-5]

        # 提取标签（单独提取 'ClassicValue' 列）
        roi_labels = selected_data['ClassicValue'].values

        # 检查标签一致性
        if reference_labels is None:
            reference_labels = roi_labels  # 初始化参考标签
        elif not np.array_equal(reference_labels, roi_labels):
            raise ValueError(f"Labels are inconsistent between ROIs. Mismatch found for ROI: {roi}")

        features.append(roi_features)
        # 获取特征列名称，并添加 ROI 前缀
        all_feature_names.extend(feature_names)  # 将特征名称拼接到总列表中
        # labels.append(roi_labels)

    # 合并所有ROI的特征
    features = horizontally_concatenate(features)
    labels = reference_labels  # 假设所有ROI的标签一致，取第一个即可
    return features, labels, all_feature_names  # 返回特征矩阵和统一标签

def remove_highly_correlated(X, threshold=0.8):
    """移除高度相关的特征"""
    corr_matrix = pd.DataFrame(X).corr().abs() # 1. 计算特征之间的相关性矩阵
    upper = corr_matrix.where(np.triu(np.ones(corr_matrix.shape), k=1).astype(bool)) # 2. 提取上三角矩阵（去掉对角线和下三角部分）
    to_drop = [col for col in upper.columns if any(upper[col] > threshold)] # 3. 找出需要移除的特征列
    return np.delete(X, to_drop, axis=1), [i for i in range(X.shape[1]) if i not in to_drop] # 4. 删除高度相关的特征

# 加载数据
def load_all_data(modality_dir):
    """
    加载单个模态下所有ROI的特征和标签，并根据受试者名称对齐数据。
    如果某个受试者在当前ROI中不存在，则填充 NaN 值。
    特征矩阵的行名会被设置为 subject_names。
    """
    features = []
    all_feature_names = []

    # 读取Excel文件的所有sheet（假设每个sheet对应一个ROI）
    data = pd.read_excel(modality_dir)
    data['ROI'] = data['ROI'].replace({'Pu': 'PU', 'Ca': 'CN'})

    # 获取唯一 ROI
    roi_values = data['ROI'].unique() # [:-1]
    # roi_name = ['PU', 'CN', 'GPe', 'GPi', 'SN', 'RN', 'TH', 'DN']

    # 初始化参考受试者列表和标签
    reference_subjects = None
    reference_labels = None

    # 遍历所有 ROI
    for i, roi in enumerate(roi_values):
        roi_data = data[data['ROI'] == roi].copy()
        roi_data.drop(columns=['ROI'], inplace=True)

        # 按 'ClassicValue' 排序
        sorted_table = roi_data.sort_values(by='ClassicValue')

        # 筛选 ClassicValue 为 0、1、2 的行
        selected_data = sorted_table[sorted_table['ClassicValue'].isin([0, 1, 2])]

        # 提取特征 # 提取受试者名称（最后一列）作为索引
        subject_names = selected_data.iloc[:, -1]
        roi_features = selected_data.iloc[:, :-2]
        roi_features.index = subject_names.tolist()  # 设置行名

        # 添加 ROI 前缀到特征名称
        feature_names = [f"{roi}_{col}" for col in roi_features.columns]
        roi_features.columns = feature_names

        # 提取标签（单独提取 'ClassicValue' 列）
        roi_labels = selected_data.set_index(subject_names)['ClassicValue']  # 确保是 Pandas Series
        # 检查标签一致性
        if reference_labels is None:
            reference_subjects = subject_names  # 初始化参考受试者列表
            reference_labels = roi_labels.reindex(reference_subjects)

        else:
            # 对齐特征数据到参考受试者列表，填充缺失值为 NaN
            aligned_roi_features = roi_features.reindex(reference_subjects)

            # 对齐标签数据到参考受试者列表，填充缺失值为 NaN
            aligned_roi_labels = roi_labels.reindex(reference_subjects)

            # 使用对齐后的特征和标签
            roi_features = aligned_roi_features


        features.append(roi_features)
        # 获取特征列名称，并添加 ROI 前缀
        all_feature_names.extend(feature_names)  # 将特征名称拼接到总列表中
        # labels.append(roi_labels)

    # 合并所有ROI的特征
    features = horizontally_concatenate2(features)
    labels = reference_labels  # 假设所有ROI的标签一致，取第一个即可
    return features, labels, all_feature_names  # 返回特征矩阵和统一标签

# 加载数据
def load_all_data_nor(modality_dir):
    """
    加载单个模态下所有ROI的特征和标签，并根据受试者名称对齐数据。
    如果某个受试者在当前ROI中不存在，则填充 NaN 值。
    特征矩阵的行名会被设置为 subject_names。
    """
    features = []
    all_feature_names = []

    # 读取Excel文件的所有sheet（假设每个sheet对应一个ROI）
    data = pd.read_excel(modality_dir)
    data['ROI'] = data['ROI'].replace({'Pu': 'PU', 'Ca': 'CN'})

    # 获取唯一 ROI
    roi_values = data['ROI'].unique() # [:-1]
    # roi_name = ['PU', 'CN', 'GPe', 'GPi', 'SN', 'RN', 'TH', 'DN']

    # 初始化参考受试者列表和标签
    reference_subjects = None
    reference_labels = None

    # 遍历所有 ROI
    for i, roi in enumerate(roi_values):
        roi_data = data[data['ROI'] == roi].copy()
        roi_data.drop(columns=['ROI'], inplace=True)

        # 按 'ClassicValue' 排序
        sorted_table = roi_data.sort_values(by='ClassicValue')

        # 筛选 ClassicValue 为 0、1、2 的行
        selected_data = sorted_table[sorted_table['ClassicValue'].isin([0, 1, 2])]

        # 提取特征 # 提取受试者名称（最后一列）作为索引
        subject_names = selected_data.iloc[:, -1]
        roi_features = selected_data.iloc[:, :-5]
        roi_features.index = subject_names.tolist()  # 设置行名

        # 添加 ROI 前缀到特征名称
        feature_names = [f"{roi}_{col}" for col in roi_features.columns]
        roi_features.columns = feature_names

        # 提取标签（单独提取 'ClassicValue' 列）
        roi_labels = selected_data.set_index(subject_names)['ClassicValue']  # 确保是 Pandas Series
        # 检查标签一致性
        if reference_labels is None:
            reference_subjects = subject_names  # 初始化参考受试者列表
            reference_labels = roi_labels.reindex(reference_subjects)

        else:
            # 对齐特征数据到参考受试者列表，填充缺失值为 NaN
            aligned_roi_features = roi_features.reindex(reference_subjects)

            # 对齐标签数据到参考受试者列表，填充缺失值为 NaN
            aligned_roi_labels = roi_labels.reindex(reference_subjects)

            # 使用对齐后的特征和标签
            roi_features = aligned_roi_features


        features.append(roi_features)
        # 获取特征列名称，并添加 ROI 前缀
        all_feature_names.extend(feature_names)  # 将特征名称拼接到总列表中
        # labels.append(roi_labels)

    # 合并所有ROI的特征
    features = horizontally_concatenate2(features)
    labels = reference_labels  # 假设所有ROI的标签一致，取第一个即可
    return features, labels, all_feature_names  # 返回特征矩阵和统一标签