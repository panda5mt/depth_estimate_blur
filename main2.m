clear;
close all;
vid_read = VideoReader('./img/driverec1.mp4','CurrentTime',0);
vid_write = VideoWriter('./img/encode','MPEG-4');
%vid_write = VideoWriter('./img/encode','Motion JPEG AVI');
open(vid_write);
%vid_write.FrameRate = vid_read.FrameRate;

countr = 0; 
    
N = 10; % フィルタ演算する1辺の長さ = N x N (pixel)
obj_thres = N^2/2;% 物体認識の下限閾値
check_image = true; % 数フレームおきに生成画像を目視確認するか？

while hasFrame(vid_read)
    img = readFrame(vid_read);
    %img = imrotate(img,-90); % image processing toolbox
    img = imresize(img, [640 480]);
    %%%%
    %% HSV変換し、輝度情報(V)だけ使用する
    ref_val = (rgb2hsv(img));
    ref_val = double(ref_val(:,:,3));
    % ref_val2 = ref_val;
    % ref_scale = ref_val;
    % imagesc((ref_scale))
    % colorbar
    
    %% OTSU' Method
    ref_gray_bk = ref_val; 
    gthresh3 = my_graythresh(ref_val);
    ref_val(ref_val > gthresh3) = 0; 
    gthresh2 = my_graythresh(ref_val);
    ref_val = ref_gray_bk;
    ref_val(ref_val > gthresh2) = 0; 
    gthresh = my_graythresh(ref_val);

    % 検討パラメータその1
    % ref_val(:) = 2.0;
    % ref_val(ref_gray_bk < (1+gthresh3)/2) = 0.0;
    % ref_val(ref_gray_bk < gthresh3) = 0.5;
    % ref_val(ref_gray_bk < gthresh2) = 1.0;
    % ref_val(ref_gray_bk < gthresh) = 0.0;
    % % 検討パラメータその1おわり

    % 検討パラメータその2
    ref_val(:) = 2.0;
    ref_val(ref_gray_bk < (1-gthresh2)) = 1.0;
    ref_val(ref_gray_bk < (1-gthresh3)) = 0.0;
    ref_val(ref_gray_bk < gthresh3) = 0.5;
    ref_val(ref_gray_bk < gthresh2) = 1.0;
    ref_val(ref_gray_bk < gthresh) = 0.0;
    % 検討パラメータその2おわり

    % % 白線検出。わざと大きめの値にしている。
    % % 路上でこの色が多く検出される場合、光量が足りてない。
    % % ECUまたはドライバにヘッドライト点灯指示を通知。    
    % %ref_val(ref_gray_bk >= (1-gthresh3)) = 5.0;
    
    
    % 大津の3値化の結果を確認する場合は下記3行をコメントアウト解除
    % figure(1)
    % imshow(ref_val ./ max(ref_val,[],"all"))
    % title("Otsu's method (N-values)")
    
    % tick = tic;
    % sparse defocus blur
    ref_spa = ((img) - f_blur(img,4)).*4;
    ref_spa = ref_spa(:,:,2);
    
    e = edge(im2gray(img),'log'); % あとで手実装する    
    ref_spa(e == 0) = 0;

    
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
                    fill_enable = true; % 塗りつぶしフラグをtrue
                end
            end
    
            if fill_enable
                img_dense(j:j+N-1,i:i+N-1) = double(edge_factor) * pick_matrices ; 
            end
    
            if mat_sum <= obj_thres % 近傍に物体がない
                fill_enable = false; % 塗りつぶしフラグをfalse
                edge_factor = 0;
            end 
        end    
    end
    %toc(tick)
    
    i=0;%30; % todo: fix this. this is bias(background noise).
    img_dense(img_dense < i) = 0; % remove background noise
    im = ind2rgb(uint8(img_dense),turbo(190));

    if check_image
        countr = countr + 1;
        if countr > 60
            countr = 0;
            figure(2)
            imshow(im)
            drawnow
        end
    end

    writeVideo(vid_write,im);

end
% 書き込みしたビデオファイルをクローズ
close(vid_write);
