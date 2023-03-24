close all;
clear;
clc;
img = imread('img/a2.png');

img_fd = f_deblur(img,3);
img_fd1 = f_deblur(img,20);

imshowpair(img_fd,img_fd1,'montage')




