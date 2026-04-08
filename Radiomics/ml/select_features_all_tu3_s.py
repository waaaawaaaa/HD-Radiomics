# 进行特征筛选，最后统计一下   读入的数据是最原始整理出来的数据
# 对NAN值填充   画出ROC图  之前的插值不对
# 2025\05\22   zhumengying

import matplotlib
matplotlib.use('TkAgg')  # 或者使用 'Qt5Agg'
import matplotlib.pyplot as plt
from sklearn.inspection import permutation_importance
from sklearn.linear_model import LogisticRegression
from sklearn.svm import SVC
from sklearn.neighbors import KNeighborsClassifier
import numpy as np
from sklearn.feature_selection import (VarianceThreshold, SelectKBest, f_classif, SelectFromModel, RFE)
from sklearn.linear_model import LassoCV
from sklearn.ensemble import RandomForestClassifier
from sklearn.preprocessing import StandardScaler,MinMaxScaler
import os
import pandas as pd
from xgboost import XGBClassifier
from imblearn.over_sampling import SMOTE
from sklearn.metrics import accuracy_score, f1_score, auc, roc_curve, confusion_matrix
from sklearn.model_selection import StratifiedKFold, cross_val_predict
from my_function import load_all_data, horizontally_concatenate2, remove_highly_correlated
# from imblearn.over_sampling import GeometricSMOTE
from sklearn.preprocessing import label_binarize

import matplotlib.pyplot as plt
import matplotlib as mpl

# 设置字体为 Arial，并保留为可编辑文本（Type 3）
mpl.rcParams['font.family'] = 'sans-serif'
mpl.rcParams['font.sans-serif'] = ['Arial']
# 关键设置：SVG 中保留字体为文本（不是路径）
plt.rcParams['svg.fonttype'] = 'none'

# 设置字体大小等样式
mpl.rcParams.update({
    'font.size': 12,
    'axes.labelsize': 22,
    'axes.titlesize': 26,
    'xtick.labelsize': 18,
    'ytick.labelsize': 18,
    'legend.fontsize': 20,
})


# ==================== 1. 数据加载与整合 ====================
# 设置路径  mapping
# seqs = ['T2star_Mapping', 'T2Mapping'] # 'T2star_Mapping', 'T2Mapping', 't1w_t2w', 'T2W_FLAIR', 'T2W', 'T1W'
# seqs_name = ['T2*', 'T2']
# data_root = 'H:/重建数据/mapping_unet_best/peizhun'  # 统一使用反斜杠
# excel_name = ['_zhuzhu4', '_zhuzhu4']
#
# data_dirs = [
#     'PD_out_t2s/ROI_processed2',  # 子目录
#     'PD_out_t2m/ROI_processed',
# ]

# # 设置路径 all  顺序不影响
# seqs = ['T2W', 't1w_t2w', 'T2W_FLAIR', 'T1W', 'T2star_Mapping', 'T2Mapping'] # 'T2star_Mapping', 'T2Mapping', 't1w_t2w', 'T2W_FLAIR', 'T2W', 'T1W'
# seqs_name = ['T2*', 'T2', 'T2W', 'T1W/T2W', 'FLAIR', 'T1W']
# data_root = 'H:/重建数据/mapping_unet_best/peizhun'  # 统一使用反斜杠
# excel_name = ['_mask_zhuzhu4', '_mask_zhuzhu4', '_mask_zhuzhu4', '_mask_zhuzhu4', '_zhuzhu4', '_zhuzhu4']
#
# data_dirs = [
#     'Register_jiegouxiang_1vs1/T2W/ROI_processed',  # 注意子目录层级
#     'Register_jiegouxiang_1vs1/T1W_T2W/ROI_processed',
#     'Register_jiegouxiang_1vs1/T2W_FLAIR/ROI_processed',
#     'Register_jiegouxiang_1vs1/T1W/ROI_processed',
#     'PD_out_t2s/ROI_processed2',  # 子目录
#     'PD_out_t2m/ROI_processed',
# ]

# 设置路径  结构像
seqs = ['T1W', 'T2W', 'T2W_FLAIR', 't1w_t2w'] # 'T2star_Mapping', 'T2Mapping', 't1w_t2w', 'T2W_FLAIR', 'T2W', 'T1W'
seqs_name = ['T1W', 'T2W', 'FLAIR', 'T1W/T2W']
data_root = 'H:/重建数据/mapping_unet_best/peizhun'  # 统一使用反斜杠
excel_name = ['_mask_zhuzhu4', '_mask_zhuzhu4', '_mask_zhuzhu4', '_mask_zhuzhu4']

data_dirs = [
    'Register_jiegouxiang_1vs1/T1W/ROI_processed',  # 注意子目录层级
    'Register_jiegouxiang_1vs1/T2W/ROI_processed',
    'Register_jiegouxiang_1vs1/T2W_FLAIR/ROI_processed',
    'Register_jiegouxiang_1vs1/T1W_T2W/ROI_processed',
]

# 自定义 RGB 颜色
custom_colors = {
    "LR": "#ABC6E4",
    "RF": "#C39398",
    "SVM": "#FCDABA",
    "XGBoost": "#A7D2BA",
    "KNN": "#D0CADE"
}

all_features = []
all_feature_names = []
reference_labels = None
reference_feature_names = None
reference_subjects = None# 用于存储参考特征名称
for i in range(len(seqs)):
    # 修正路径拼接方式
    modality_dir = os.path.join(
        data_root,
        data_dirs[i],  # 确保该目录存在
        f"{seqs[i]}_腐蚀1_T2_cx{excel_name[i]}.xlsx"
    )
    features, label, feature_names = load_all_data(modality_dir)
    # 获取特征列名称，并添加 ROI 前缀
    seq_feature_names = [f"{seqs_name[i]}_{col}" for col in feature_names]
    features.columns = seq_feature_names

    # 初始化参考受试者列表和标签
    if reference_subjects is None:
        reference_subjects = features.index  # 初始化参考受试者列表
        reference_labels = label  # 初始化参考标签
    else:
        # 对齐特征数据到参考受试者列表，填充缺失值为 NaN
        aligned_features = features.reindex(reference_subjects)
        # 使用对齐后的特征
        features = aligned_features

    all_features.append(features)
    all_feature_names.extend(seq_feature_names)

# 合并所有模态的特征（5模态×8ROI×13特征=520特征）
X = horizontally_concatenate2(all_features) # 最终形状：(n_samples, 520)
y = np.array(reference_labels)  # 形状：(n_samples,)

# ==================== 1. 缺失值处理 ====================
# 使用线性插值填充 NaN
# X_filled = X.interpolate(method='linear', axis=1)  # axis=1 表示按行插值

# 如果需要填充边缘的 NaN（如开头或结尾的 NaN），可以使用 limit_direction 参数
X_filled = X.interpolate(method='linear', axis=0, limit_direction='both')

# 检查数据
print(f"特征矩阵形状: {X.shape}, 标签形状: {y.shape}")

# ==================== 1. 数据预处理 ====================
scaler = StandardScaler()
# scaler = MinMaxScaler()
X_scaled = scaler.fit_transform(X_filled)   # 标准化，按特征，一列一列的计算

# ==================== 2. 相关性过滤 ====================
X_corr_filtered, corr_selected_indices = remove_highly_correlated(X_scaled, threshold=0.80)
corr_selected_feature_names = [all_feature_names[i] for i in corr_selected_indices]
print(f"相关性过滤后特征数: {X_corr_filtered.shape[1]}")

# ==================== 3. 单变量特征筛选（ANOVA） ====================
anova_features_to_select = min(70, int(X_corr_filtered.shape[1]/2))
anova_selector = SelectKBest(f_classif, k=anova_features_to_select)  # 增大 k 值
X_anova = anova_selector.fit_transform(X_corr_filtered, y)  # 拟合模型并筛选特征
anova_selected_indices = anova_selector.get_support(indices=True)
anova_selected_feature_names = [corr_selected_feature_names[i] for i in anova_selected_indices]
print(f"ANOVA筛选后特征数: {X_anova.shape[1]}")

# ==================== 4. Lasso正则化（L1） ====================
# 创建 LassoCV 模型，增加最大迭代次数和调整正则化参数范围
lasso = LassoCV(cv=5, alphas=np.logspace(-4, 0, 100), max_iter=10000, random_state=42) #自动选择对目标变量 y 最重要的特征
lasso_selector = SelectFromModel(lasso)
X_lasso = lasso_selector.fit_transform(X_anova, y)
lasso_selected_indices = lasso_selector.get_support(indices=True)
lasso_selected_feature_names = [anova_selected_feature_names[i] for i in lasso_selected_indices]
print(f"Lasso筛选后特征数: {X_lasso.shape[1]}")

# ==================== 5. RFE递归特征消除 ====================
# 使用随机森林作为基模型
rf = RandomForestClassifier(max_depth=5, class_weight='balanced', random_state=42)
n_features_to_select = min(8, X_lasso.shape[1])  # 动态设置保留的特征数
rfe_selector = RFE(rf, n_features_to_select=n_features_to_select, step=5)# 递归特征消除（RFE） 方法，结合 随机森林分类器 ，逐步筛选出对目标变量 y 最重要的 20 个特征
X_rfe = rfe_selector.fit_transform(X_lasso, y)
rfe_selected_indices = rfe_selector.get_support(indices=True)
rfe_selected_feature_names = [lasso_selected_feature_names[i] for i in rfe_selected_indices]
print(f"RFE筛选后特征数: {X_rfe.shape[1]}")

# ==================== 6. 数据平衡 ====================
# 通过在少数类样本之间生成新的合成样本，增加少数类的样本数量，从而使类别分布更加平衡。
# smote = SMOTE(random_state=42)
# X_resampled, y_resampled = smote.fit_resample(X_rfe, y)
X_resampled=X_rfe
y_resampled = y
# 使用 Geometric SMOTE 进行过采样
# geo_smote = GeometricSMOTE(random_state=42)
# X_resampled, y_resampled = geo_smote.fit_resample(X_rfe, y)

# ==================== 7. 最终模型训练与评估 ====================
# 初始化分层交叉验证
cv = StratifiedKFold(n_splits=5, shuffle=True, random_state=1234)

# 定义模型列表
models = {
    "LR": LogisticRegression(max_iter=1000, solver='lbfgs', random_state=42),
    "RF": RandomForestClassifier(max_depth=5, class_weight='balanced', random_state=42),
    "SVM": SVC(kernel='rbf', probability=True, random_state=42),
    "XGBoost": XGBClassifier(
        max_depth=3,
        learning_rate=0.1,
        subsample=0.8,
        eval_metric='mlogloss',
        random_state=42
    ),
    "KNN": KNeighborsClassifier(n_neighbors=3)
}

# 存储每个模型的结果
results = {}
# 创建一个空的 DataFrame 来存储所有模型的特征重要性
feature_importance_df = pd.DataFrame(index=rfe_selected_feature_names)

# 将目标变量二值化（One-vs-Rest）
classes = np.unique(y_resampled)
y_resampled_bin = label_binarize(y_resampled, classes=classes)
n_classes = len(classes)

# 设置图像宽高
plt.figure(figsize=(12, 10))  # 宽度为 12 英寸，高度为 8 英寸

# 遍历每个模型并计算评估指标
for model_name, model in models.items():
    print(f"正在评估模型: {model_name}")

    # 使用 cross_val_predict 获取预测结果
    y_pred = cross_val_predict(model, X_resampled, y_resampled, cv=cv)

    # 使用 cross_val_predict 获取预测概率
    if hasattr(model, "predict_proba"):
        y_pred_prob = cross_val_predict(model, X_resampled, y_resampled, cv=cv, method="predict_proba")
    elif hasattr(model, "decision_function"):
        y_pred_prob = cross_val_predict(model, X_resampled, y_resampled, cv=cv, method="decision_function")
    else:
        raise ValueError(f"模型 {model_name} 不支持概率预测或决策函数")

    # 离散化预测概率
    bins = [0, 0.2, 0.4, 0.6, 0.8, 1.0]
    y_pred_prob_discrete = np.digitize(y_pred_prob[:, 1], bins=bins) / len(bins)

    # 计算混淆矩阵
    cm = confusion_matrix(y_resampled, y_pred)

    # 初始化存储每个类别的 FPR、TPR 和 AUC
    fpr = dict()
    tpr = dict()
    roc_auc = dict()

    # 初始化指标
    sensitivity_per_class = []
    specificity_per_class = []

    for i, cls in enumerate(classes):
        # 计算每个类别的 TP, TN, FP, FN
        tp = cm[i, i]  # 当前类别的真正例
        fn = cm[i, :].sum() - tp  # 当前类别的假负例
        fp = cm[:, i].sum() - tp  # 当前类别的假正例
        tn = cm.sum() - (tp + fn + fp)  # 当前类别的真负例

        # 计算敏感性和特异性
        sensitivity = tp / (tp + fn) if (tp + fn) > 0 else 0
        specificity = tn / (tn + fp) if (tn + fp) > 0 else 0

        sensitivity_per_class.append(sensitivity)
        specificity_per_class.append(specificity)

        fpr[i], tpr[i], _ = roc_curve(y_resampled_bin[:, i], y_pred_prob[:, i])
        roc_auc[i] = auc(fpr[i], tpr[i])

    # 计算宏平均敏感性和特异性
    sensitivity_macro = np.mean(sensitivity_per_class)
    specificity_macro = np.mean(specificity_per_class)

    # 计算其他指标
    accuracy = accuracy_score(y_resampled, y_pred)
    f1_macro = f1_score(y_resampled, y_pred, average='macro')

    # 存储结果
    results[model_name] = {
        "Accuracy": accuracy,
        "F1-Macro": f1_macro,
        "Sensitivity-Macro": sensitivity_macro,
        "Specificity-Macro": specificity_macro
    }

    # 打印结果
    print(f"  F1-Macro: {f1_macro:.4f}")
    print(f"  Sensitivity-Macro: {sensitivity_macro:.4f}")
    print(f"  Specificity-Macro: {specificity_macro:.4f}")
    print(f"  Accuracy: {accuracy:.4f}")
    print("-" * 40)

    # 拟合模型以提取特征重要性
    model.fit(X_resampled, y_resampled)

    # 根据模型类型计算特征重要性
    if model_name == "LR":
        # 逻辑回归：使用系数作为特征重要性
        coefficients = model.coef_[0]
        feature_importances = np.abs(coefficients)  # 取绝对值
        importance_type = "Coefficients"
    elif model_name == "RF":
        # 随机森林：使用内置的特征重要性
        feature_importances = model.feature_importances_
        importance_type = "Feature Importances"
    elif model_name == "XGBoost":
        # XGBoost：使用内置的特征重要性
        feature_importances = model.feature_importances_
        importance_type = "Feature Importances"
    elif model_name == "SVM":
        # SVM：使用排列重要性（SVM 不提供内置特征重要性）
        perm_importance = permutation_importance(model, X_resampled, y_resampled, scoring='f1_macro', random_state=42)
        feature_importances = perm_importance.importances_mean  # 提取均值
        importance_type = "Permutation Importance"
    elif model_name == "KNN":
        # KNN：使用排列重要性（KNN 不提供内置特征重要性）
        perm_importance = permutation_importance(model, X_resampled, y_resampled, scoring='f1_macro', random_state=42)
        feature_importances = np.abs(perm_importance.importances_mean)  # 提取均值
        importance_type = "Permutation Importance"
    else:
        feature_importances = None

    # 存储特征重要性结果
    if feature_importances is not None:
        # 确保 feature_importances 是数组或列表
        if isinstance(feature_importances, (float, np.floating)):
            feature_importances = np.array([feature_importances])  # 转换为数组
        elif not isinstance(feature_importances, (list, np.ndarray)):
            raise ValueError("feature_importances 必须是数组或列表，但得到的是其他类型。")

        results[model_name]["Feature Importances"] = feature_importances
        sorted_indices = np.argsort(feature_importances)[::-1]

        # 打印特征重要性
        print(f"  {importance_type}:")
        for i in sorted_indices[:5]:  # 打印前 10 个最重要的特征
            print(f"    {rfe_selected_feature_names[i]}: {feature_importances[i]:.4f}")

    # 存储特征重要性结果
    if feature_importances is not None:
        feature_importance_df[model_name] = feature_importances

    fpr["micro"], tpr["micro"], _ = roc_curve(y_resampled_bin.ravel(), y_pred_prob.ravel())
    roc_auc["micro"] = auc(fpr["micro"], tpr["micro"])

    # 计算宏平均 ROC 曲线和 AUC
    all_fpr = np.unique(np.concatenate([fpr[i] for i in range(n_classes)]))
    mean_tpr = np.zeros_like(all_fpr)
    for i in range(n_classes):
        mean_tpr += np.interp(all_fpr, fpr[i], tpr[i])  # 插值以对齐 FPR
    mean_tpr /= n_classes

    fpr["macro"] = all_fpr
    tpr["macro"] = mean_tpr
    roc_auc["macro"] = auc(fpr["macro"], tpr["macro"])

    # 绘制宏平均 ROC 曲线
    plt.plot(
        fpr["macro"], tpr["macro"],
        label=f"{model_name} (AUC = {roc_auc['macro']:.4f})",
        color=custom_colors[model_name],
        lw=5,
        drawstyle = 'steps-post'  # 强制曲线呈现阶梯状
    )
    # plt.plot(
    #     fpr["micro"], tpr["micro"],
    #     label=f"{model_name} (AUC = {roc_auc['micro']:.4f})",
    #     color=custom_colors[model_name],
    #     lw=5
    # )
# 添加对角线（随机猜测线）
plt.plot([0, 1], [0, 1], color='gray', linestyle='--', lw=5)

# 美化图形
# plt.title("ROC Curves", fontsize=26, fontweight='bold', pad=20)
plt.xlabel("False Positive Rate (FPR)", fontsize=22, fontweight='bold')
plt.ylabel("True Positive Rate (TPR)", fontsize=22, fontweight='bold')
plt.legend(loc="lower right", fontsize=20, frameon=False)
# plt.grid(True, linestyle='--', alpha=0.7)

# 设置 x 轴和 y 轴范围为 [0, 1]
plt.xlim(0, 1)
plt.ylim(0, 1)

# 设置 x 轴和 y 轴刻度字体大小
plt.xticks(fontsize=18)  # 增大 x 轴刻度字体
plt.yticks(fontsize=18)  # 增大 y 轴刻度字体

# 调整布局
plt.tight_layout()


# 保存图形
plt.savefig('roc_curves.png', dpi=300, bbox_inches='tight')
plt.savefig('roc_curves_s.svg', format='svg', bbox_inches='tight', dpi=300)

# 对每列进行归一化处理
feature_importance_df = feature_importance_df.div(feature_importance_df.sum(axis=0), axis=1)

# 计算每个特征的总重要性
feature_importance_df['Total Importance'] = feature_importance_df.sum(axis=1)

# 按总重要性降序排序
feature_importance_df = feature_importance_df.sort_values(by='Total Importance', ascending=False)

# 删除辅助列 "Total Importance"（如果需要）
feature_importance_df = feature_importance_df.drop(columns=['Total Importance'])

# 提取颜色列表（按模型顺序）
colors = [custom_colors[model] for model in feature_importance_df.columns]

# 绘制水平堆叠条形图
ax = feature_importance_df.plot(
    kind='barh',  # 使用水平条形图
    stacked=True,
    figsize=(12, 8),
    color=colors,  # 使用自定义颜色
    width=0.8       # 条形宽度
)

# 美化标题和标签
# plt.title("Feature Importances", fontsize=18, fontweight='bold', pad=20)
plt.xlabel("Normalized Importance", fontsize=14, fontweight='bold')  # X 轴改为 "Normalized Importance"
# plt.ylabel("Features", fontsize=14, fontweight='bold')  # Y 轴改为 "Features"

# 调整 Y 轴标签
plt.yticks(fontsize=14)
plt.xticks(fontsize=14)  # 增大 x 轴刻度字体

# 美化图例并将其放置在图形内部
plt.legend(
    loc='upper right',            # 图例放置在图形内部右上角
    fontsize=14,                   # 图例字体大小
    title_fontsize=14,             # 图例标题字体大小
    frameon=False                  # 移除图例边框
)

# 添加网格线
ax.xaxis.grid(True, linestyle='--', alpha=0.7)  # 水平条形图使用垂直网格线

# 保留 X 轴和 Y 轴的线条，移除顶部和右侧的边框
ax.spines['top'].set_visible(False)    # 隐藏顶部边框
ax.spines['right'].set_visible(False)  # 隐藏右侧边框
ax.spines['bottom'].set_visible(True)  # 显示底部边框（X 轴）
ax.spines['left'].set_visible(True)    # 显示左侧边框（Y 轴）

# 可选：调整 X 轴和 Y 轴线条的样式
ax.spines['bottom'].set_linewidth(1.5)  # 设置 X 轴线条粗细
ax.spines['left'].set_linewidth(1.5)    # 设置 Y 轴线条粗细

# 调整布局
plt.tight_layout()

# 保存图形
plt.savefig('zhongyaoxing.png', dpi=300, bbox_inches='tight')
plt.savefig('zhongyaoxing_s.svg', format='svg', bbox_inches='tight', dpi=300)
