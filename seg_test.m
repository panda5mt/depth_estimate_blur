clc;clear;
vid_read = VideoReader('./img/driverec.mp4','CurrentTime',640);
%vid_write = VideoWriter('./img/encode','MPEG-4');
%open(vid_write);
while hasFrame(vid_read)
    
    img = readFrame(vid_read);
    img = imresize(img, [480 640]);
    imwrite(img,'./img/encode.png','png');
    ref = rgb2hsv(img);
    factor = zeros(1,5);
    %% Sparse depth estimation
    img = img(:,:,2);

    ref_spa = double((f_blur(img,3,2)) - (f_blur(img,15,2)));
    %ref_spa = (imgaussfilt(im2gray(img),1.3)-imgaussfilt(im2gray(img),1.5)).*2;

    e = edge((img),'log'); % あとで手実装する    
    ref_spa(e == 0) = 0;
    
    %% dense depth estimation
    % HSV変換(変数:ref)
    % H(色相)とS(彩度)の情報を使い類似度を求める
    ref_hue = ref(:,:,1) - 0.5;
    ref_sat = ref(:,:,2);
    ref_val = ref(:,:,3);
    
    % ref_sml = (ref_val./ ref_sat);
    % R = (ref_sml <= -0.5) .* 1 + (ref_sml <= 0.5) .* 2 + (ref_sml <= 0.7) .* 3;

    % 大津の5値化
    ref_gray_bk = ref_val; 
    gthresh1 = my_graythresh(ref_val);
    ref_val(ref_val > gthresh1) = 0; 
    gthresh2 = my_graythresh(ref_val);
    ref_val(ref_val > gthresh2) = 0; 
    gthresh3 = my_graythresh(ref_val);
    ref_val(ref_val > gthresh3) = 0; 
    gthresh4 = my_graythresh(ref_val);

    % 屋外晴天時と室内
    ref_val = 10 - (ref_gray_bk >= gthresh4) .* 2 ...
            - (ref_gray_bk >= gthresh3) .* 2 ...
            - (ref_gray_bk >= gthresh2) .* 2 ... 
            - (ref_gray_bk >= gthresh1) .* 2; % 2,4,6,8,10のみ

    % 大津のn値化と輪郭の検証は下記4行をコメントアウト
    figure(1); colormap("default")
    imagesc(ref_val);%clim([0 2])
    colorbar; 

    im_width = width(ref_spa);
    im_height = height(ref_spa);
    
    img_dense = zeros(size(ref_spa));
    fill_enable = false;
    edge_factor = 0;
    fill_factor = 0;
    fill_counter = 0; %同じエッジ要素で塗りつぶし続けることを制限するためのカウンタ
    N = 20;

    for i=1:N:im_width-N 
        for j=1:N:im_height-N 
            pick_defocus =  ref_spa(j:j+N-1,i:i+N-1);
            pick_matrices = ref_val(j:j+N-1,i:i+N-1);
            
            for k = 1:5
                aa = (pick_matrices == k * 2);
            z = max(aa .* double(pick_defocus),[],"all");
            if (z > -1)
             factor(k) = z;
            end
                
            end
            img_dense(j:j+N-1,i:i+N-1) =  ...
                              double(factor(1)) * (pick_matrices == 1 * 2) ...
                            + double(factor(2)) * (pick_matrices == 2 * 2) ...
                            + double(factor(3)) * (pick_matrices == 3 * 2) ...
                            + double(factor(4)) * (pick_matrices == 4 * 2) ...
                            + double(factor(5)) * (pick_matrices == 5 * 2) ...
                            ;

        end 
    end
    
    

    % figure(2)
    % colormap('default')
    % %img_dense(e == 0) = 0;
    % imagesc(img_dense);clim([0 60])
    % colorbar

    im = ind2rgb(uint8(img_dense),turbo(30));
    %writeVideo(vid_write,im);

end
%close(vid_write);