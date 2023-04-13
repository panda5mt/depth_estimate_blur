function [Y,Z] = roi_calc(imgCrop)
    
    B = f_blur(im2gray(imgCrop), 3, 2) - f_blur(im2gray(imgCrop), 15, 2);
    e = edge(im2gray(imgCrop),'log');
    B(e==0)=0;
    Y = mean(B,'all')^2*10;
    Z = var(double(B),0,'all');
end