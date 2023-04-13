function [Y,Z] = roi_calc(imgCrop)
    
    B = f_blur(imgCrop, 3, 2) - f_blur(imgCrop, 15, 2);
    e = edge(im2gray(imgCrop),'log');
    B(e==0)=0;
    Y = mean(B,'all')^2/2;
    Z = var(double(B),0,'all');
end