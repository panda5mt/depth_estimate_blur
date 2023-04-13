% 関心領域を深度推定
clear; close; clc;

check_blur = false;

img = imread('./img/encode01.png');
img = imresize(img, [480 640]);
while true
figure(1)

if check_blur
    B = f_blur(im2gray(img), 3, 2) - f_blur(im2gray(img), 15, 2);
    e = edge(im2gray(img),'log');
    B(e==0)=0;
    imagesc(B.*5)
else
    imshow(img)
end
rect = drawrectangle('Label','distance-estimate','Color',[1 0 0]);
roi1 = rect.Position;

imgCrop = imcrop(img,roi1);
[Y,Z] = roi_calc(imgCrop); % Y:推定距離、Z:分散。 Zが小さい場合(今回は11以下)、深度推定データとしての信頼性は低い
a = ['dist=' num2str(Y) ', var=' num2str(Z)];
disp(a);

end