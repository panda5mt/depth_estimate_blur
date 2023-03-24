function h = my_conv2(f, g, conv_type)
%     FFTタイプの畳み込み
%     多項式 f, g の積を計算する。
% 
%     Parameters
%     ----------
%     f : f[i] に、x^i の係数が入っている
% 
%     g : g[i] に、x^i の係数が入っている
% 
% 
%     Returns
%     -------
%     h : f,g の積
%     
    % h の長さ以上の n=2^k を計算

    arguments
        f = []
        g = []
        conv_type = 'full'
    end
    
    %% サイズ調整
    fft_len_x = 1;
    fft_len_y = 1;
    
    while (2 * fft_len_x) < (size(f,2) + size(g,2) - 1)
        fft_len_x = fft_len_x * 2;
    end
    fft_len_x = fft_len_x * 2 ;

    while (2 * fft_len_y) < (size(f,1) + size(g,1) - 1)
        fft_len_y = fft_len_y * 2;
    end
    fft_len_y = fft_len_y * 2 ;

    % フーリエ変換で実装する
    Ff = fft2(f, fft_len_y,fft_len_x);% Ff = real(Ff);
    Fg = fft2(g, fft_len_y,fft_len_x);% Fg = real(Fg);

    % 各点積
    Fh = Ff .* Fg;

    % フーリエ逆変換
    h = ifft2(Fh);
    % フルサイズの取得
    len_x = size(f,2) + size(g,2) - 1;
    len_y = size(f,1) + size(g,1) - 1;
    h = h(1:1+len_y-1, 1:1+len_x-1);
    
    % same, valid, fullで分ける    
    switch conv_type
        case 'same'
            len_x = size(f,2);
            len_y = size(f,1);
        case 'valid'
            len_x = max(size(f,2)-size(g,2) + 1, 0);
            len_y = max(size(f,1)-size(g,1) + 1, 0);
%         case 'full'
%             len_x = size(f,2) + size(g,2) - 1;
%             len_y = size(f,1) + size(g,1) - 1;
%         otherwise
%             len_x = size(f,2) + size(g,2) - 1;
%             len_y = size(f,1) + size(g,1) - 1;
    end

    st_x = ceil((size(h, 2) - len_x) / 2) + 1;
    st_y = ceil((size(h, 1) - len_y) / 2) + 1;
    h = (h(st_y:st_y + len_y - 1, st_x:st_x + len_x - 1));
end

