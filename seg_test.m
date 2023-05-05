clc;clear;
vid_read = VideoReader('./img/driverec.mp4','CurrentTime',653);
%vid_write = VideoWriter('./img/encode','MPEG-4');
%open(vid_write);
factor_l = zeros(1,5);
            
while hasFrame(vid_read)
    
    img = readFrame(vid_read);
    img = imresize(img, [480 640]);
    imwrite(img,'./img/encode.png','png');
    ref = rgb2hsv(img);
    factor = zeros(1,5);
    %% Sparse depth estimation
    img = img(:,:,2);

    ref_spa = double((f_blur(img,3,1)) - (f_blur(img,9,1))) ;
    %ref_spa = (imgaussfilt(im2gray(img),1.3)-imgaussfilt(im2gray(img),1.5)).*2;

    e = edge((img),'log'); % あとで手実装する    
    ref_spa(e == 0) = 0;
   
    %% dense depth estimation
    % HSV変換(変数:ref)
    % H(色相)とS(彩度)の情報を使い類似度を求める
    ref_hue = cos(ref(:,:,1) .* 2 .* pi);
    ref_sat = ref(:,:,2);
    ref_val = ref(:,:,3);
    
    ref_gray_bk = ref_val; 
    gthresh1 = my_graythresh(ref_val);
    ref_val(ref_val > gthresh1) = 0; 
    gthresh2 = my_graythresh(ref_val);

    % 屋外晴天時と室内
    ref_val = (ref_gray_bk >= gthresh2) .* 1 ... 
            + (ref_gray_bk >= gthresh1) .* 1; 
   
    factor = ((ref_hue > 0) .*  1 ...
            + (ref_hue <= 0) .* -1 ...
            );

    ref_val = ref_val .*  factor; % -2~+2までの5階調になる(0を含むので)
                    
    % % 大津のn値化と輪郭の検証は下記4行をコメントアウト
    figure(1); colormap("default")
    m = min(ref_spa>0,[],'all')
    x = max(ref_spa,[],"all")
    imagesc(ref_spa);clim([10 x])
    colorbar; 

    im_width = width(ref_spa);
    im_height = height(ref_spa);
    
    img_dense = zeros(size(ref_spa));
    fill_enable = false;
    edge_factor = 0;
    fill_factor = 0;
    fill_counter = 0; %同じエッジ要素で塗りつぶし続けることを制限するためのカウンタ
    N = 40;

    for i=1:N:im_width-N 
        for j=1:N:im_height-N 
            pick_defocus =  ref_spa(j:j+N-1,i:i+N-1);
            pick_matrices = ref_val(j:j+N-1,i:i+N-1);
            
            l = 1;
            for k=unique(ref_val)'
                factor = (pick_matrices == k);
                fill_factor = mean(ref_spa(factor),'all');
                if ~isempty(fill_factor) && fill_factor > 0
                %fill_factor
                    factor_l(l) = fill_factor;
                    img_dense(j:j+N-1,i:i+N-1) = img_dense(j:j+N-1,i:i+N-1) + double(factor) .* fill_factor;
                else
                    img_dense(j:j+N-1,i:i+N-1) = img_dense(j:j+N-1,i:i+N-1) + factor_l(l);
                end
                l = l + 1;
            end

        end 
    end
    
    

    figure(2)
    colormap('default')
    %img_dense(e == 0) = 0;
    imagesc(img_dense.*10);clim([0 15])
    colorbar
    drawnow
    % %im = ind2rgb(uint8(img_dense),turbo(30));
    % %writeVideo(vid_write,im);

end
%close(vid_write);