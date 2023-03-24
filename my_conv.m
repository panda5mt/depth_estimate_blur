function h = my_conv(f, g, conv_type)
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
    
    fft_len = 1;
    while (2 * fft_len) < (length(f) + length(g) - 1)
        fft_len = fft_len * 2;
    end
    fft_len = fft_len * 2;

    % フーリエ変換で実装する
    Ff = fft(f, fft_len);% Ff = real(Ff);
    Fg = fft(g, fft_len);% Fg = real(Fg);

    % 各点積
    Fh = Ff .* Fg;

    % フーリエ逆変換
    h = ifft(Fh, fft_len);
    
    % same, valid, fullで分ける    
    switch conv_type
        case 'same'
            len = length(f);      
        case 'valid'
            len = max(length(f)-length(g) + 1,0);
        case 'full'
            len = length(f) + length(g) - 1;
        otherwise
            len = length(f) + length(g) - 1;
    end

    st_idx = fix((length(h) - len + 1) / 2);  
    h = int32(h(st_idx:st_idx + len - 1));
end

