%% 弱いストラクチャ部分を検出し、強いストラクチャからの深度情報を反映させるプログラム
% Cited paper:"Blind Photograph Watermarking with Robust Defocus-Based JND Model"
% https://www.hindawi.com/journals/wcmc/2020/8892349/

clear;
clc; 

img = imread('./img/c1cam_room.jpg');
img = imresize(img, [960 1280]);
img = im2double(im2gray(img)); 

T = dctmtx(8);
dct = @(block_struct) T * block_struct.data * T';
B = blockproc(img,[8 8],dct);

mask = [
    1 1 1 0 0 0 0 0
    1 1 0 0 0 0 0 0
    1 0 1 0 0 0 0 0
    0 0 0 0 0 0 0 0
    0 0 0 0 0 0 0 0
    0 0 0 0 0 0 0 0
    0 0 0 0 0 0 0 0
    0 0 0 0 0 0 0 0
];

B2 = blockproc(B,[8 8],@(block_struct) mask .* block_struct.data);

ETM = []; % Matrix of ET
ELM = []; % Matrix of EL
EMM = []; % Matrix of EM
ACM = []; % Matrix of AC Coeff

for xx=1:8:size(B2,2)
    for yy=1:8:size(B2,1)
        A = B2(yy:yy+7,xx:xx+7);
        
        ETM(yy:yy+7,xx:xx+7) = 0.0;        
        if A(1,1) > 0
            ET = A(2,1)^2 + A(3,1)^2 + ...
                    A(1,2)^2 + A(1,3)^2 + ... 
                    A(2,2)^2 + A(3,3)^2;
            ET = ET / A(1,1)^2;
            ETM(yy:yy+7,xx:xx+7) = ET;
        end
        EL = max([A(1,2) A(2,1) A(2,2)]);
        EM = max([A(1,3) A(3,1) A(3,3)]);
        ELM(yy:yy+7,xx:xx+7) = EL;
        EMM(yy:yy+7,xx:xx+7) = EM;
    end
end

%% ETが0.02よりも大きい場合、強いテクスチャブロック
% Strongly textured block
STB = (ETM > 0.02);
% Weakly textured block
WTB = (ETM <= 0.02);

% Cに関しては詳細が不明なもののpoolingと言っているので
% 特定ブロックに区切った際の最大・平均・ストライドの
% いずれかを指しているものと思われる
%C = mean(ETM,'all');
C = max(ETM,[],'all');
%C = medfilt2(ETM,[5 5]);

C0 = 16;

ELM_copy = ELM;
EMM_copy = EMM;

%% パラメータを変えてループ
% restore ELM and EMM
ELM = ELM_copy;
EMM = EMM_copy;

%% Calc DM on STB
S_ELM = ELM;
S_EMM = EMM;

S_ELM(~STB) = 0;
S_EMM(~STB) = 0;

S_ELM = (S_ELM < (C0 .* C.^0.40)) .* S_ELM; 
S_EMM = (S_EMM < (C0 .* C.^0.25)) .* S_EMM; 
EE = (S_ELM + S_EMM) ;  % Equation (14)

%% Calc DM on WTB
ELM(~WTB) = 0;
EMM(~WTB) = 0;
 
% Equation(15)
S = (log10(abs(ELM)) - log10(abs(EMM))) / ((log10(0.85)-log10(1.))); % TODO: fix S
%S = (abs(S) > 1) .* S .* 1.4  + (abs(S) <= 1) .* S .* 0; 

% % ↓弱いストラクチャの認識
%S(abs(S) < 10) = 0;

% 合成
%DM = (EE > 0) .* EE + (EE <= 0).* S;
DM  = S;

DMAP = f_blur(DM,20,1);
DMAP = log10(abs(DMAP));
%DMAP(DMAP < 1.05) = 0;
% 表示
figure(4);
cl = [0.5 3]; % clim
tiledlayout(1,2)
nexttile
imagesc(EE);colormap(jet);title('sparse by DCT');
nexttile
imagesc(DMAP);colormap(jet);clim(cl);colorbar;title('dense by DCT');
drawnow;


%DM = get_dfm(img,DM,5);
%figure(1);imagesc(SX);colorbar;
%figure(2);imagesc(S);clim([0 2.5]);colorbar;
%figure(3);imagesc(DMX);colorbar;
% invdct = @(block_struct) T' * block_struct.data * T;
% K = blockproc(B2,[8 8],invdct);

%figure(3);colormap('jet');imagesc(K);colorbar;clim([0 .5])

% dct = @(block_struct) T * block_struct.data * T';
% B = blockproc(img,[8 8],dct);
% B2 = blockproc(B,[8 8],@(block_struct) mask .* block_struct.data);
% invdct = @(block_struct) T' * block_struct.data * T;
% K = blockproc(B2,[8 8],invdct);
% 
% im = ind2rgb(255-(im2uint8(img) - im2uint8(K)));
% figure(3);imshow(im);
% drawnow


