% 静止画の高速簡易深度推定(屋内)
clear all;
clc;
img = imread('./img/WIN_20230316_17_12_59_Pro.jpg');

% gray = R .* 0.3 + G .* 0.59 + B .* 0.11
% ref_gray = img(:,:,2);% .* 0.3 + img(:,:,2) .* 0.59 + img(:,:,3) .* 0.11;

% HSV変換し、輝度情報だけ使用する
ref_V = rgb2hsv(img);
ref_V = ref_V(:,:,3); 
ref_scale = ref_V;

% 3値化する(OTSU) 
ref_gray_bk = ref_V; 
gthresh1 = my_graythresh(ref_V);
ref_V(ref_V > gthresh1) = 0; 

gthresh2 = my_graythresh(ref_V);
ref_V = ref_gray_bk;

ref_V(ref_gray_bk < gthresh2) = 2.0;
ref_V(ref_gray_bk >= gthresh2) = 4.0;
ref_V(ref_gray_bk >= gthresh1) = 0.0;

figure(1)
imshow(ref_V ./ max(ref_V,[],"all"))
title("Otsu's method (3-values)")
%colorbar


% sparse defocus blur
ref_SD = (abs(f_blur(img,4) - (img)));
ref_SD = ref_SD(:,:,2);

% depth estimation
% 大津の手法によりセグメントした結果に疎な深度推定を反映させ、
% 密(dense)な結果にする
% 言い換えると、大津の3値化により簡易的に物体検出をし、
% defocus blurによる結果で塗り絵をしているだけ
im_width = width(ref_SD);
im_height = height(ref_SD);

img_FD = zeros(size(ref_SD));
fill_enable = false;
edge_factor = 0;
N = 10; % フィルタ演算する1辺の長さ = N x N (pixel)

for i=1:N:im_width-N 
    for j=1:N:im_height-N 
        pick_defocus =  ref_SD(j:j+N-1,i:i+N-1);
        pick_matrices = ref_V(j:j+N-1,i:i+N-1);

        ker_max = max(pick_defocus, [], 'all');
        mat_sum = sum(pick_matrices, 'all');

        if (ker_max > 0) % エッジがある
            if (fill_enable)
                if edge_factor < ker_max
                    edge_factor = ker_max;
                end
            else
                edge_factor = ker_max;
                fill_enable = true;
            end
        end

        if fill_enable
            img_FD(j:j+N-1,i:i+N-1) = double(edge_factor) * pick_matrices ; 
        end

        if mat_sum == 0
            fill_enable = false;
            edge_factor = 0;
        end 
    end    
end

%img_FD = f_blur(img_FD,50); 

i=0;
img_FD(img_FD < i) = 0; % remove background noise

figure(2)
colormap('turbo')
imagesc(imresize(uint8(img_FD),2))
colorbar
drawnow





