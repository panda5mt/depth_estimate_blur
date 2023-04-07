% fast blur function(Osafune-Blur)
function img = f_blur(img, n)

    kernel_1d = pascal_1d(n);
    k_sum = sum(kernel_1d,"all");
    kernel_1d = kernel_1d ./k_sum;

    x_size = size(img,2);
    y_size = size(img,1);
    z_size = size(img,3);
    
    for c=1:z_size
        i = img(:,:,c);
        for y=1:y_size
            i(y,:) = conv(i(y,:),kernel_1d,'same');
        end
        for x=1:x_size
            i(:,x) = medfilt1(double(i(:,x)),floor(n/2));
            %i(:,x) = conv(i(:,x),kernel_1d,'same');
        end
        img(:,:,c) = i;
    end

end