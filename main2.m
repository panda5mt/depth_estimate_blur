clear all;
close all;
vidRD = VideoReader('./img/driverec.mp4','CurrentTime',88);
vidWR = VideoWriter('./img/encode','MPEG-4');
open(vidWR);
%vidWR.FrameRate = vidRD.FrameRate;
direction = [0 0 1];
countr = 0;
while hasFrame(vidRD)
    img = readFrame(vidRD);
    img = imrotate(img,-90);
    img = imresize(img, [640 480]);
%%%%
% HSV変換し、輝度情報だけ使用する
ref_V = im2double(rgb2hsv(img));
ref_V = ref_V(:,:,3); 
ref_scale = ref_V;

% 4値化する(OTSU) 
ref_gray_bk = ref_V; 
gthresh3 = my_graythresh(ref_V);
ref_V(ref_V > gthresh3) = 0; 

gthresh2 = my_graythresh(ref_V);

ref_V = ref_gray_bk;
ref_V(ref_V > gthresh2) = 0; 
gthresh = my_graythresh(ref_V);


ref_V(:) = 0.5;
ref_V(ref_gray_bk < gthresh3) = 0.0;
ref_V(ref_gray_bk < gthresh2) = 1.5;
ref_V(ref_gray_bk < gthresh) = .5;

% 初期検討時パラメータ
% ref_V(:) = 0.0;
% ref_V(ref_gray_bk < gthresh3) = 1.0;
% ref_V(ref_gray_bk < gthresh2) = 2.1;
% ref_V(ref_gray_bk < gthresh) = 0.5;


% 大津の3値化の結果を確認する場合は下記3行をコメントアウト
% figure(1)
% imshow(ref_V ./ max(ref_V,[],"all"))
% title("Otsu's method (3-values)")


%tick = tic;
% sparse defocus blur
ref_SD = (abs(f_blur(img,4) - (img)));
ref_SD = ref_SD(:,:,2);

% depth estimation
% 大津の手法によりセグメントした結果に疎(sparse)な深度推定を反映させ、
% 密(dense)な結果にする
% 言い換えると、大津の3値化により簡易的に物体検出をし、
% defocus blurによる結果で塗り絵をしているだけ
im_width = width(ref_SD);
im_height = height(ref_SD);

img_FD = zeros(size(ref_SD));
fill_enable = false;
edge_factor = 0;
N = 15; % フィルタ演算する1辺の長さ = N x N (pixel)

for i=1:N:im_width-N 
    for j=1:N:im_height-N 
        pick_defocus =  ref_SD(j:j+N-1,i:i+N-1);
        pick_matrices = ref_V(j:j+N-1,i:i+N-1);

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
            img_FD(j:j+N-1,i:i+N-1) = double(edge_factor) * pick_matrices ; 
        end

        if mat_sum == 0
            fill_enable = false;
            edge_factor = 0;
        end 
    end    
end

%toc(tick)

i=0;
img_FD(img_FD < i) = 0; % remove background noise
im = ind2rgb(uint8(img_FD),turbo(190));
countr = countr + 1;
if countr > 60
    countr = 0;
    figure(2)
    imshow(im)
    drawnow
end
writeVideo(vidWR,im);


%%%%
end


close(vidWR);
