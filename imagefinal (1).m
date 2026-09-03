%% ========================================================================

clear; clc; close all;

gray_img = imread('cameraman.tif');
if size(gray_img, 3) == 3
    gray_img = rgb2gray(gray_img);
end

try
    rgb_img = imread('peppers.png'); 
catch
    rgb_img = imread('onion.png');
end

%% ========================================================================
%% Part 1 & 2: Butterworth Low-Pass & High-Pass Filters Definition & Verification
%% ========================================================================
[M, N] = size(gray_img);
[u, v] = meshgrid(-floor(N/2):floor((N-1)/2), -floor(M/2):floor((M-1)/2));
D = sqrt(u.^2 + v.^2);

D0 = 50; % Cutoff frequency
orders = [1, 2, 4];

figure('Name', 'Part 1 & 2: Butterworth Filter Shapes');
for k = 1:length(orders)
    n = orders(k);
    
    % Butterworth Low-Pass Filter
    H_BLPF = 1 ./ (1 + (D ./ D0).^(2*n));
    
    % Butterworth High-Pass Filter (Method 1: 1 - H_BLPF)
    H_BHPF_1 = 1 - H_BLPF;
    
    % Butterworth High-Pass Filter (Method 2: Direct formula)
    % لتجنب القسمة على صفر عند المنتصف:
    D_temp = D; D_temp(D_temp == 0) = eps;
    H_BHPF_2 = 1 ./ (1 + (D0 ./ D_temp).^(2*n));
    
    
    subplot(3, 3, (k-1)*3 + 1); imshow(H_BLPF, []); title(sprintf('BLPF (n=%d, D0=%d)', n, D0));
    subplot(3, 3, (k-1)*3 + 2); imshow(H_BHPF_1, []); title(sprintf('BHPF Method 1 (n=%d)', n));
    subplot(3, 3, (k-1)*3 + 3); imshow(H_BHPF_2, []); title(sprintf('BHPF Method 2 (n=%d)', n));
    
    
    diff_val = max(abs(H_BHPF_1(:) - H_BHPF_2(:)));
    fprintf('Butterworth n=%d Max Difference between Method 1 & 2: %e\n', n, diff_val);
end

%% ========================================================================
%% Part 3 & 4: Gaussian Low-Pass & High-Pass Filters
%% ========================================================================
D0_list = [20, 50, 100];

figure('Name', 'Part 3 & 4: Gaussian Filters');
for k = 1:length(D0_list)
    d0_val = D0_list(k);
    
    % Gaussian Low-Pass Filter
    H_GLPF = exp(-(D.^2) / (2 * d0_val^2));
    
    % Gaussian High-Pass Filter
    H_GHPF = 1 - H_GLPF;
    
    subplot(2, 3, k); imshow(H_GLPF, []); title(sprintf('GLPF (D0 = %d)', d0_val));
    subplot(2, 3, k+3); imshow(H_GHPF, []); title(sprintf('GHPF (D0 = %d)', d0_val));
end

%% ========================================================================
%% Part 5: Visualize and Compare 2D Filters & Profiles
%% ========================================================================
figure('Name', 'Part 5: Filter Profile Comparison');
plot(D(floor(M/2)+1, :), H_BLPF(floor(M/2)+1, :), 'r-', 'LineWidth', 1.5); hold on;
plot(D(floor(M/2)+1, :), exp(-(D(floor(M/2)+1, :).^2) / (2 * 50^2)), 'b--', 'LineWidth', 1.5);
grid on; xlabel('Distance D(u,v)'); ylabel('H(u,v)');
legend('Butterworth (n=4, D0=50)', 'Gaussian (D0=50)');
title('Cross-section Comparison at D0 = 50');

%% ========================================================================
%% Part 6: Apply Filters to Grayscale Image
%% ========================================================================
% 1. Fourier Transform & Shift
F_gray = fftshift(fft2(double(gray_img)));

% Construct Filters
n_val = 2; D0_val = 50;
H_BLP = 1 ./ (1 + (D ./ D0_val).^(2*n_val));
H_BHP = 1 - H_BLP;
H_GLP = exp(-(D.^2) / (2 * D0_val^2));
H_GHP = 1 - H_GLP;

% Apply & Inverse Fourier
img_BLP = real(ifft2(ifftshift(F_gray .* H_BLP)));
img_BHP = real(ifft2(ifftshift(F_gray .* H_BHP)));
img_GLP = real(ifft2(ifftshift(F_gray .* H_GLP)));
img_GHP = real(ifft2(ifftshift(F_gray .* H_GHP)));

figure('Name', 'Part 6: Grayscale Filtering Results');
subplot(2,3,1); imshow(gray_img, []); title('Original Grayscale');
subplot(2,3,2); imshow(img_BLP, []); title('Butterworth LPF (n=2, D0=50)');
subplot(2,3,3); imshow(img_GLP, []); title('Gaussian LPF (D0=50)');
subplot(2,3,5); imshow(img_BHP, []); title('Butterworth HPF (n=2, D0=50)');
subplot(2,3,6); imshow(img_GHP, []); title('Gaussian HPF (D0=50)');

%% ========================================================================
%% Part 7: Apply Filters to RGB Color Image
%% ========================================================================
[Mr, Nr, ~] = size(rgb_img);
[ur, vr] = meshgrid(-floor(Nr/2):floor((Nr-1)/2), -floor(Mr/2):floor((Mr-1)/2));
Dr = sqrt(ur.^2 + vr.^2);

% Build RGB Filters
D0_rgb = 50; n_rgb = 2;
H_BLP_rgb = 1 ./ (1 + (Dr ./ D0_rgb).^(2*n_rgb));
H_BHP_rgb = 1 - H_BLP_rgb;

% Process RGB Channels
filtered_rgb_BLP = zeros(size(rgb_img));
filtered_rgb_BHP = zeros(size(rgb_img));

for c = 1:3
    F_ch = fftshift(fft2(double(rgb_img(:,:,c))));
    
    % LPF
    ch_blp = real(ifft2(ifftshift(F_ch .* H_BLP_rgb)));
    filtered_rgb_BLP(:,:,c) = ch_blp;
    
    % HPF
    ch_bhp = real(ifft2(ifftshift(F_ch .* H_BHP_rgb)));
    filtered_rgb_BHP(:,:,c) = ch_bhp;
end

figure('Name', 'Part 7: RGB Color Image Filtering');
subplot(1,3,1); imshow(rgb_img); title('Original RGB');
subplot(1,3,2); imshow(uint8(filtered_rgb_BLP)); title('RGB Butterworth LPF');
subplot(1,3,3); imshow(uint8(filtered_rgb_BHP + 128)); title('RGB Butterworth HPF (+128 Offset)');

%% ========================================================================
%% Part 8: Investigate Effect of Cutoff Frequency D0 (20, 50, 100)
%% ========================================================================
figure('Name', 'Part 8: Investigating D0 on Grayscale Image');
subplot(2,4,1); imshow(gray_img, []); title('Original');

for k = 1:length(D0_list)
    d0_val = D0_list(k);
    
    % BLPF
    H_blp_var = 1 ./ (1 + (D ./ d0_val).^(2*2));
    res_blp = real(ifft2(ifftshift(F_gray .* H_blp_var)));
    
    % BHPF
    H_bhp_var = 1 - H_blp_var;
    res_bhp = real(ifft2(ifftshift(F_gray .* H_bhp_var)));
    
    subplot(2,4,k+1); imshow(res_blp, []); title(sprintf('BLPF D0=%d', d0_val));
    subplot(2,4,k+5); imshow(res_bhp, []); title(sprintf('BHPF D0=%d', d0_val));
end

%% ========================================================================
%% Part 11: Advanced Challenge - Interactive Application
%% ========================================================================
interactive_filtering_tool(gray_img, rgb_img);

%% ========================================================================
%% Interactive Tool Function (Part 11)
%% ========================================================================
function interactive_filtering_tool(gray_img, rgb_img)
    fig = figure('Name', 'Part 11: Interactive Frequency Filter Tool', 'Position', [100, 100, 1000, 600]);
    
    % Controls Layout
    uicontrol('Style', 'text', 'Position', [20, 540, 100, 20], 'String', 'Image Type:');
    popup_img = uicontrol('Style', 'popup', 'String', {'Grayscale', 'RGB Color'}, 'Position', [120, 540, 100, 20]);
    
    uicontrol('Style', 'text', 'Position', [20, 500, 100, 20], 'String', 'Filter Family:');
    popup_family = uicontrol('Style', 'popup', 'String', {'Butterworth', 'Gaussian'}, 'Position', [120, 500, 100, 20]);
    
    uicontrol('Style', 'text', 'Position', [20, 460, 100, 20], 'String', 'Filter Type:');
    popup_type = uicontrol('Style', 'popup', 'String', {'Low-Pass', 'High-Pass'}, 'Position', [120, 460, 100, 20]);
    
    uicontrol('Style', 'text', 'Position', [20, 420, 100, 20], 'String', 'Order (n):');
    edit_n = uicontrol('Style', 'edit', 'String', '2', 'Position', [120, 420, 100, 20]);
    
    uicontrol('Style', 'text', 'Position', [20, 380, 100, 20], 'String', 'Cutoff (D0):');
    edit_d0 = uicontrol('Style', 'edit', 'String', '50', 'Position', [120, 380, 100, 20]);
    
    btn_run = uicontrol('Style', 'pushbutton', 'String', 'Apply Filter', 'Position', [50, 320, 120, 35], ...
        'Callback', @(src, event) process_image());
    
    function process_image()
        img_choice = popup_img.Value;
        family_choice = popup_family.Value; % 1: Butterworth, 2: Gaussian
        type_choice = popup_type.Value;     % 1: Low-Pass, 2: High-Pass
        n = str2double(edit_n.String);
        D0 = str2double(edit_d0.String);
        
        if img_choice == 1
            src_img = gray_img;
        else
            src_img = rgb_img;
        end
        
        [M, N, C] = size(src_img);
        [u, v] = meshgrid(-floor(N/2):floor((N-1)/2), -floor(M/2):floor((M-1)/2));
        D = sqrt(u.^2 + v.^2);
        
        % Build Filter
        if family_choice == 1 % Butterworth
            if type_choice == 1
                H = 1 ./ (1 + (D ./ D0).^(2*n));
            else
                H = 1 - (1 ./ (1 + (D ./ D0).^(2*n)));
            end
        else % Gaussian
            if type_choice == 1
                H = exp(-(D.^2) / (2 * D0^2));
            else
                H = 1 - exp(-(D.^2) / (2 * D0^2));
            end
        end
        
        % Filter Application
        out_img = zeros(size(src_img));
        for c = 1:C
            F = fftshift(fft2(double(src_img(:,:,c))));
            out_img(:,:,c) = real(ifft2(ifftshift(F .* H)));
        end
        
        % Display Results
        subplot(1, 3, 1); imshow(src_img); title('Original Image');
        subplot(1, 3, 2); imshow(H, []); title('2D Frequency Filter');
        subplot(1, 3, 3); imshow(uint8(out_img)); title('Filtered Output');
    end
end