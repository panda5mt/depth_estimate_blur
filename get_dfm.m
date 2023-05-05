function diff_img = get_dfm(Y, dm, ohm)

arguments
    Y = []
    dm = []
    ohm = 5
end

img = Y;

% ブロックごとに中心周囲差を計算
block_size = ohm; % ブロックサイズ
half_size = floor(block_size/2); % 中心ピクセルからブロック端までの距離
[M, N] = size(img); % 画像サイズ
diff_img = zeros(M, N); % 差分画像の初期化
for i = half_size+1:M-half_size
    for j = half_size+1:N-half_size
        block = img(i-half_size:i+half_size, j-half_size:j+half_size);
        blk_dm = dm(i-half_size:i+half_size, j-half_size:j+half_size);
        
        center_pixel = block(half_size+1, half_size+1);
        [x, y] = meshgrid(1:block_size);
        distance = sqrt((x-half_size-1).^2 + (y-half_size-1).^2); % 中心ピクセルとの距離
        weight = 1/(sqrt(2*pi))*exp(-(distance)^2/2); % ユークリッド距離による重み
        block_diff = double(abs(block - center_pixel)) .* weight .* sum(blk_dm,"all");
        diff_img(i,j) = sum(block_diff(:),"all");
    end
end

% 結果の表示
%imshow(diff_img, []);
end