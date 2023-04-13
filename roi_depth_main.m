% 関心領域を深度推定
clear; close;clc;
lap_ker = [     
    0,1,0;
    1,-4,1;
    0,1,0
];

img = imread('./img/encode03.png');
img = imresize(img, [480 640]);
while true
figure(1)
imshow(img)

rect = drawrectangle('Label','distance-estimate','Color',[1 0 0]);
roi1 = rect.Position;

imgCrop = imcrop(img,roi1);
[Y,Z] = roi_calc(imgCrop); % Y:推定距離、Z:分散。 Zが小さい場合(今回は60以下)、深度推定データとしての信頼性は低い
a = ['dist=' num2str(Y) ', var=' num2str(Z)];
disp(a);

end