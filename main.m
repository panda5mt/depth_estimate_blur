%% 静止画の高速簡易深度推定
clc;
%img = imread('./img/c1cam_room1.jpg');
img = imread('./img/c1cam_car1.jpg');
img = imresize(img, [480 640]);

%% 調整パラメータ
% フィルタ演算する1辺の長さ = N x N (pixel)
N = 10; 
% 物体が存在しないと判断する閾値
thres = 0; % N^2*0.25,N^2*0.5など

% HSV変換し、輝度情報だけ使用する
ref_val = rgb2hsv(img);
ref_val = ref_val(:,:,3); 
ref_scale = ref_val;

%% 3値化する(OTSU) 
ref_gray_bk = ref_val; 
gthresh1 = my_graythresh(ref_val);
ref_val(ref_val > gthresh1) = 0; 

gthresh2 = my_graythresh(ref_val);
ref_val = ref_gray_bk;

% 屋外晴天時と室内
ref_val(ref_gray_bk < gthresh2) = 4.0;
ref_val(ref_gray_bk >= gthresh2) = 2.0;
ref_val(ref_gray_bk >= gthresh1) = 0.0;

% 大津の3値化の結果を確認する場合は下記3行をコメントアウト解除
% figure(1)
% imagesc(ref_val)
% colorvar

tick = tic;

%% sparse defocus blur
ref_spa = (img - (f_blur(img,4)));
ref_spa = ref_spa(:,:,2);
e = edge(im2gray(img),'log'); % あとで手実装する    
ref_spa(e == 0) = 0;

% 輪郭を確認する場合は下記3行をコメントアウト解除
% figure(2)
% imagesc(ref_spa)
% colorbar

%% depth estimation
% 大津の手法によりセグメントした結果に疎(sparse)な深度推定を反映させ、
% 密(dense)な結果にする
% 言い換えると、大津の3値化により簡易的に物体検出をし、
% defocus blurによる結果で塗り絵をしているだけ
im_width = width(ref_spa);
im_height = height(ref_spa);

img_dense = zeros(size(ref_spa));
fill_enable = false;
edge_factor = 0;


for i=1:N:im_width-N 
    for j=1:N:im_height-N 
        pick_defocus =  ref_spa(j:j+N-1,i:i+N-1);
        pick_matrices = ref_val(j:j+N-1,i:i+N-1);

        ker_max = max(pick_defocus, [], 'all');
        mat_sum = sum(pick_matrices, 'all');

        if (ker_max > 0) % エッジがある
            if (fill_enable)
                if edge_factor < ker_max
                    edge_factor = ker_max; % 近傍のエッジで最大のものを採用
                end
            else
                edge_factor = ker_max;
                fill_enable = true;
            end
        end

        if fill_enable
            img_dense(j:j+N-1,i:i+N-1) = double(edge_factor) * pick_matrices ; 
        end

        if mat_sum <= thres
            fill_enable = false;
            edge_factor = 0;
        end 
    end    
end

toc(tick)

% i=0;
% img_dense(img_dense < i) = 0; % remove background noise

figure(3)
colormap('turbo')
imagesc(imresize(uint8(img_dense),2))
colorbar
drawnow





