% 関心領域を深度推定
clear; close; clc;

check_blur = false;

vid_read = VideoReader('./img/driverec.mp4','CurrentTime',640);
if hasFrame(vid_read)
    
img = readFrame(vid_read);
img = imresize(img, [480 640]);

end

figure(1)
imshow(img)

rect = drawrectangle('Label','distance-estimate','Color',[1 0 0]);
roi1 = rect.Position; % 囲った部分を記憶
roi1
while hasFrame(vid_read)
    img = readFrame(vid_read);
    img = imresize(img, [480 640]);
    rgb = insertShape(img,"rectangle",roi1,LineWidth=5);
    imshow(rgb)
    
    imgCrop = imcrop(img,roi1);
    [Y,Z] = roi_calc(imgCrop); % Y:推定距離、Z:分散。 Zが小さい場合(今回は11以下)、深度推定データとしての信頼性は低い
    a = ['gauss_ave=' num2str(Y) ', var=' num2str(Z)];
    disp(a);
end