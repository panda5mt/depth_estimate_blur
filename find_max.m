function val = find_max(img,center,find_areas)
% usage: val = find_max(img, [5 8], [4 4]); 

arguments
    img = []
    center = [2,2]
    find_areas = [5 5]
end

    cy = center(1);
    cx = center(2);
    ay = find_areas(1);
    ax = find_areas(2);

    [iy, ix] = size(img);
    val = [];
    % clip
    if cx > ix || cy > ix , return; end
    if ax > ix || ay > iy , return; end
    %if ax > ix || ay > iy , ax = ix; ay = iy; end

    %calc locate for start and end
    % start
    sx = cx - floor(ax/2); 
    sy = cy - floor(ay/2); 

    if sx < 1, sx = 1; end
    if sy < 1, sy = 1; end

    % end
    ex = sx + ax - 1;
    ey = sy + ay - 1;
    
    if ex > ix, ex = ix; end
    if ey > iy, ey = iy; end

    val = max(img(sy:ey, sx:ex),[], 'all');

end