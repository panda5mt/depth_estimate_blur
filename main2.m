clear;
close all;
vid_read = VideoReader('./img/driverec1.mp4','CurrentTime',1);
vid_write = VideoWriter('./img/encode','MPEG-4');%VideoWriter('./img/encode','Motion JPEG AVI');
open(vid_write);
%vidWR.FrameRate = vidRD.FrameRate;

countr = 0;
while hasFrame(vid_read)
    img = readFrame(vid_read);
    %img = imrotate(img,-90); % image processing toolbox
    img = imresize(img, [640 480]);
    %%%%
    %% HSV変換し、輝度情報(V:Luminance)だけ使用する
    ref_lum = (rgb2hsv(img));
    ref_lum = double(ref_lum(:,:,3));
    
    % ref_scale = ref_V;
    % imagesc((ref_scale))
    % colorbar
    
    %% n値化する(OTSU) 
    ref_gray_bk = ref_lum; 
    gthresh3 = my_graythresh(ref_lum);
    ref_lum(ref_lum > gthresh3) = 0; 
    gthresh2 = my_graythresh(ref_lum);
    
    ref_lum = ref_gray_bk;
    ref_lum(ref_lum > gthresh2) = 0; 
    gthresh = my_graythresh(ref_lum);
    
    % 検討パラメータその1
    % ref_lum(:) = 0.5;
    % ref_lum(ref_gray_bk < gthresh3) = 0.0;
    % ref_lum(ref_gray_bk < gthresh2) = 1.5;
    % ref_lum(ref_gray_bk < gthresh) = .5;
    
    % 検討パラメータその2
    ref_lum(:) = 0.0;
    ref_lum(ref_gray_bk < gthresh3) = 0.5;
    ref_lum(ref_gray_bk < gthresh2) = 2.0;
    ref_lum(ref_gray_bk < gthresh) = 0.0;
    
    % 検討パラメータその3
    % ref_lum(ref_gray_bk > 0.5) = 1;
    % ref_lum(ref_gray_bk > 0.55) = 0;
    % ref_lum(ref_gray_bk < gthresh3) = 0.5;
    % ref_lum(ref_gray_bk < gthresh2) = 1.5;
    % ref_lum(ref_gray_bk < gthresh) = 0.0;
    
    % 大津の3値化の結果を確認する場合は下記3行をコメントアウト
    % figure(1)
    % imshow(ref_lum ./ max(ref_lum,[],"all"))
    % title("Otsu's method (N-values)")
    
    %tick = tic;
    % sparse defocus blur
    ref_spa = (abs(f_blur(img,4) - (img)));
    ref_spa = ref_spa(:,:,2);
    
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
    N = 15; % フィルタ演算する1辺の長さ = N x N (pixel)
    
    for i=1:N:im_width-N 
        for j=1:N:im_height-N 
            pick_defocus =  ref_spa(j:j+N-1,i:i+N-1);
            pick_matrices = ref_lum(j:j+N-1,i:i+N-1);
    
            ker_max = max(pick_defocus, [], 'all');
            mat_sum = sum(pick_matrices, 'all');
    
            if (ker_max > 0) % エッジがある
                if (fill_enable)
                    if edge_factor < ker_max
                        edge_factor = ker_max; % 近傍のエッジで最大のものを採用
                    end
                else
                    edge_factor = ker_max;
                    fill_enable = true; % 塗りつぶしフラグをtrue
                end
            end
    
            if fill_enable
                img_dense(j:j+N-1,i:i+N-1) = double(edge_factor) * pick_matrices ; 
            end
    
            if mat_sum == 0 % 近傍に物体がない
                fill_enable = false; % 塗りつぶしフラグをfalse
                edge_factor = 0;
            end 
        end    
    end
    %toc(tick)
    
    i=0; % todo: fix this. this is bias(background noise).
    img_dense(img_dense < i) = 0; % remove background noise
    im = ind2rgb(uint8(img_dense),turbo(190));
    countr = countr + 1;
    if countr > 60
        countr = 0;
        figure(2)
        imshow(im)
        drawnow
    end
    writeVideo(vid_write,im);

end
% 書き込みしたビデオファイルをクローズ
close(vid_write);
