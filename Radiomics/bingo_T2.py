#修改一下保存，保存成最佳的模型
# 2025\01\06   zhumengying
# train

import os
import csv
import argparse
import numpy as np

import torch
from tensorboardX import SummaryWriter

from network.UNet import Inference,loss_fun_total

from tools.data_loader import get_loader
from tools.evaluation import get_nmse
from tools.misc import mkexperiment,save_torch_result
from tools.modelsummary import summary

def main(config):
    # 初始化变量
    patience = config.model_save_patience  # 提前停止的耐心值
    best_val_loss = float('inf')
    early_stop_counter = 0

    #-----选择GPU-----#
    os.environ['CUDA_VISIBLE_DEVICES'] = config.GPU_NUM

    #-----使每次生成的随机数相同-----#
    np.random.seed(1)
    torch.manual_seed(1)

    # -----建立实验-----#
    experiment_path = mkexperiment(config, cover=True)
    save_inter_result = os.path.join(experiment_path, 'inter_result')
    model_path = os.path.join(config.model_path,config.name)

    # -----读取数据-----#
    data_dir = config.data_dir
    train_batch = get_loader(data_dir, config, crop_key=config.CROP_KEY, num_workers=3, shuffle=True, mode='train')
    val_batch = get_loader(data_dir, config, crop_key=config.CROP_KEY, num_workers=1, shuffle=True, mode='test')
    brain_batch = get_loader(data_dir, config, crop_key=False, num_workers=1, shuffle=False, mode='brain')

    # -----模型-----#
    net = Inference(config.INPUT_C, config.OUTPUT_C, config.FILTERS)
    if config.CROP_KEY:
        summary(net, (config.INPUT_C, config.CROP_SIZE, config.CROP_SIZE))
    else:
        summary(net, (config.INPUT_C, config.INPUT_H, config.INPUT_W))

    #-----模型-----#
    net = Inference(config.INPUT_C,config.OUTPUT_C,config.FILTERS)

    # -----损失函数-----#
    criterion = loss_fun_total(config.regular)

    if torch.cuda.is_available():
        net.cuda()
        criterion.cuda()

    # -----优化器-----#
    optimizer = torch.optim.Adam(net.parameters(), lr=config.lr,betas=(config.beta1, config.beta2))

    #-----Setup device-----#
    device = torch.device("cuda" if torch.cuda.is_available() else "cpu")

    # -----Tensorboard-----#
    writer_train = SummaryWriter(log_dir = os.path.join(os.path.join(experiment_path, 'tensorboard'),'train'))
    writer_val = SummaryWriter(log_dir= os.path.join(os.path.join(experiment_path, 'tensorboard'),'val'))

    # ----csv表----- #
    f = open(os.path.join(experiment_path, 'result.csv'), 'a', encoding='utf-8', newline='')
    wr = csv.writer(f)
    wr.writerow(['train loss', 'val loss','val nmse', 'lr', 'total_iters', 'epochs'])

    if config.mode =='train':
        total_iters = 0
        for epoch in range(1,config.num_epochs+1):
            net = net.train()
            train_loss = 0
            train_length = 0
            val_loss = 0
            val_nmse = 0
            val_length = 0

            # ********************************************train*****************************************************#
            for i,(images, GT) in enumerate(train_batch):
                images = images.type(torch.FloatTensor)
                GT = GT.type(torch.FloatTensor)

                images = images.to(device)
                GT = GT.to(device)

                SR = net(images)  # forward

                loss = criterion(SR, GT)
                train_loss += loss.item()

                optimizer.zero_grad()  # clear grad
                loss.backward()  # backward
                optimizer.step()  # update

                train_length += images.size(0)

                total_iters += 1

                # learing rate decay
                if (total_iters % config.lr_updata) == 0:
                    for param_group in optimizer.param_groups:
                        param_group['lr'] = param_group['lr'] * 0.8
                lr = optimizer.param_groups[0]['lr']

                if total_iters%config.step == 0:
                    # # ********************************************VAL*****************************************************#
                    net.eval()
                    for i,(images_val, GT_val) in enumerate(val_batch):
                        images_val = images_val.type(torch.FloatTensor)
                        GT_val = GT_val.type(torch.FloatTensor)
                        images_val = images_val.to(device)
                        GT_val = GT_val.to(device)

                        SR_val = net(images_val)
                        loss = criterion(SR_val, GT_val)
                        nmse = get_nmse(SR_val[:,0:1,:,:], GT_val[:,0:1,:,:])
                        val_nmse += nmse
                        val_loss += loss.item()
                        val_length += images_val.size(0)
                        # break

                    # Print the log info
                    print(
                        'Epoch [%d/%d], Total_iters [%d], Train Loss: %.5f, Val Loss: %.5f, Val Nmse: %.5f, lr: %.8f' % (
                            epoch, config.num_epochs, total_iters,
                            train_loss / train_length, val_loss / val_length, val_nmse / val_length, lr))
                    writer_train.add_scalar('data/loss', train_loss / train_length, total_iters)
                    writer_val.add_scalar('data/loss', val_loss/val_length, total_iters)
                    wr.writerow([train_loss / train_length, val_loss / val_length, val_nmse / val_length, lr, total_iters, epoch])

                    # Early stopping and save best model logic
                    if epoch > 200:
                        if (val_loss / val_length) < best_val_loss:
                            best_val_loss = val_loss / val_length

                            # Save the best model
                            best_model_path = os.path.join(model_path, f"{config.name}_best_model.pth")
                            torch.save(net.state_dict(), best_model_path)

                            early_stop_counter = 0  # Reset counter if we improve
                        else:
                            early_stop_counter += 1
                            print(f"early stop counter increased:{early_stop_counter}")

                    train_loss = 0
                    train_length = 0
                    val_loss = 0
                    val_nmse = 0
                    val_length = 0

                    ## ********************************************test_brain***********************************************#
                    for i, (brain_images, _) in enumerate(brain_batch):
                        brain_images = brain_images.type(torch.FloatTensor)
                        brain_images = brain_images.to(device)
                        SR_brain = net(brain_images)

                        # save result in fold
                        save_dir = os.path.join(save_inter_result, 'inter_T2_' + str(total_iters) + '_brain')
                        save_torch_result(SR_brain[:, 0:1, :, :], save_dir,
                                         format='png', cmap='jet', norm=False, crange=[0, 1.9])

                    net.train()

            # # -----save_model-----#
            # if (epoch) % config.model_save_step == 0 and epoch > config.model_save_start:
            #     if not os.path.exists(model_path):
            #         os.mkdir(model_path)
            #     torch.save(net.state_dict(), model_path + '/' + config.name + '_epoch_' +str(epoch) + '.pth')
            if early_stop_counter >= patience:
                print("Early stopping triggered.")
                break

        f.close()
        writer_train.close()
        writer_val.close()


if __name__ == '__main__':
    parser = argparse.ArgumentParser()

    # experiment name
    parser.add_argument('--name', type=str, default='experiment')
    parser.add_argument('--experiment_path', type=str, default='')
    parser.add_argument('--data_dir', type=str, default='/DATA2023/zmy/smri_hd/OLED_T2/charles_output_mask/')
    parser.add_argument('--GPU_NUM', type=str, default='2')

    # model hyper-parameters
    parser.add_argument('--INPUT_H', type=int, default=256)
    parser.add_argument('--INPUT_W', type=int, default=256)
    parser.add_argument('--INPUT_C', type=int, default=2)
    parser.add_argument('--OUTPUT_C', type=int, default=1)
    parser.add_argument('--LABEL_C', type=int, default=1)
    parser.add_argument('--DATA_C', type=int, default=3)
    parser.add_argument('--FILTERS', type=int, default=64)

    parser.add_argument('--CROP_KEY', type=bool, default=True)
    parser.add_argument('--CROP_SIZE', type=int, default=96)

    # training hyper-parameters
    parser.add_argument('--num_epochs', type=int, default=2600)
    parser.add_argument('--BATCH_SIZE', type=int, default=8)
    parser.add_argument('--NUM_WORKERS', type=int, default=1)
    parser.add_argument('--lr', type=float, default=1e-4)
    parser.add_argument('--lr_updata', type=int, default=30000)  # epoch num for lr updata
    parser.add_argument('--beta1', type=float, default=0.9)  # momentum1 in Adam
    parser.add_argument('--beta2', type=float, default=0.999)  # momentum2 in Adam
    parser.add_argument('--regular', type=float, default=0.001)

    parser.add_argument('--step', type=int, default=500)
    parser.add_argument('--model_save_patience', type=int, default=200) # 提前停止的耐心值
    parser.add_argument('--model_save_start', type=int, default=1)
    parser.add_argument('--model_save_step', type=int, default=200)

    # misc
    parser.add_argument('--mode', type=str, default='train')
    parser.add_argument('--model_path', type=str, default='./models/')
    parser.add_argument('--result_path', type=str, default='./result/')

    config = parser.parse_args()

    config.name = 'model_T2_mask'
    main(config)

    torch.cuda.empty_cache()