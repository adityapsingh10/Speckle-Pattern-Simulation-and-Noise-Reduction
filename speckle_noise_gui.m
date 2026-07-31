function speckle_noise_gui
    % Create dynamic UI window with adjustable size
    fig = figure('Name', 'Speckle Noise Simulation GUI', 'NumberTitle', 'off', ...
                 'Units', 'normalized', 'Position', [0.1, 0.1, 0.8, 0.7], ...
                 'Color', [1 1 1], 'Resize', 'on');

    % Default image
    img = imread('cameraman.tif');
    if size(img, 3) == 1
        img = cat(3, img, img, img);  % Convert to RGB
    end
    img = im2double(img);

    % Initialization
    noisy_img = [];
    filtered_img = [];
    speckle_pattern = [];

    %% UI CONTROLS (Left Panel)
    uicontrol('Style', 'pushbutton', 'String', 'Upload Image', ...
              'Units', 'normalized', 'Position', [0.02, 0.85, 0.12, 0.05], ...
              'Callback', @uploadImage);

    uicontrol('Style', 'text', 'String', 'Noise Strength (0-1):', ...
              'Units', 'normalized', 'Position', [0.02, 0.80, 0.12, 0.03], ...
              'BackgroundColor', [1 1 1]);

    noiseSlider = uicontrol('Style', 'slider', ...
              'Min', 0, 'Max', 1, 'Value', 0.5, ...
              'SliderStep', [0.05 0.1], ...
              'Units', 'normalized', 'Position', [0.02, 0.77, 0.12, 0.03]);

    noiseLabel = uicontrol('Style', 'text', ...
              'Units', 'normalized', 'Position', [0.02, 0.74, 0.12, 0.03], ...
              'String', 'Strength: 0.5', 'BackgroundColor', [1 1 1]);

    addlistener(noiseSlider, 'ContinuousValueChange', @(src, event) ...
        set(noiseLabel, 'String', sprintf('Strength: %.2f', get(src, 'Value'))));

    uicontrol('Style', 'pushbutton', 'String', 'Add Speckle Noise', ...
              'Units', 'normalized', 'Position', [0.02, 0.70, 0.12, 0.05], ...
              'Callback', @addNoise);

    uicontrol('Style', 'text', 'String', 'Filter Size:', ...
              'Units', 'normalized', 'Position', [0.02, 0.63, 0.12, 0.03], ...
              'BackgroundColor', [1 1 1]);

    filterSlider = uicontrol('Style', 'slider', ...
              'Min', 1, 'Max', 15, 'Value', 3, ...
              'SliderStep', [1/14 1/14], ...
              'Units', 'normalized', 'Position', [0.02, 0.60, 0.12, 0.03]);

    filterLabel = uicontrol('Style', 'text', ...
              'Units', 'normalized', 'Position', [0.02, 0.57, 0.12, 0.03], ...
              'String', 'Current: 3', 'BackgroundColor', [1 1 1]);

    addlistener(filterSlider, 'ContinuousValueChange', @(src, event) ...
        set(filterLabel, 'String', sprintf('Current: %d', 2*floor(get(src,'Value')/2)+1)));

    uicontrol('Style', 'pushbutton', 'String', 'Remove Noise', ...
              'Units', 'normalized', 'Position', [0.02, 0.52, 0.12, 0.05], ...
              'Callback', @removeNoise);

    uicontrol('Style', 'pushbutton', 'String', 'Save Filtered Image', ...
              'Units', 'normalized', 'Position', [0.02, 0.46, 0.12, 0.05], ...
              'Callback', @saveImage);


    %% IMAGE DISPLAY (4 images in the grid)
    ax1 = axes('Parent', fig, 'Units', 'normalized', 'Position', [0.2, 0.55, 0.2, 0.35], 'Visible', 'off');
    ax2 = axes('Parent', fig, 'Units', 'normalized', 'Position', [0.5, 0.55, 0.2, 0.35], 'Visible', 'off');
    ax3 = axes('Parent', fig, 'Units', 'normalized', 'Position', [0.2, 0.1, 0.2, 0.35], 'Visible', 'off');
    ax4 = axes('Parent', fig, 'Units', 'normalized', 'Position', [0.5, 0.1, 0.2, 0.35], 'Visible', 'off');

    % Titles
makeLabel(0.2, 0.50, 'Original Image');     % Below ax1
makeLabel(0.5, 0.50, 'Speckle Noise');      % Below ax2
makeLabel(0.2, 0.05, 'Noisy Image');        % Below ax3
makeLabel(0.5, 0.05, 'Filtered Image');     % Below ax4


    imshow(img, 'Parent', ax1);


    %% CALLBACKS
    function uploadImage(~, ~)
        [file, path] = uigetfile({'*.jpg;*.png;*.tif;*.bmp'}, 'Select Image');
        if isequal(file, 0), return; end
        temp_img = imread(fullfile(path, file));
        if size(temp_img, 3) == 1
            temp_img = cat(3, temp_img, temp_img, temp_img);
        end
        img = im2double(temp_img);
        noisy_img = []; speckle_pattern = []; filtered_img = [];
        imshow(img, 'Parent', ax1);
        cla(ax2); cla(ax3); cla(ax4);
    end

    function addNoise(~, ~)
        [rows, cols, ch] = size(img);
        speckle_pattern = zeros(rows, cols, ch);
        noisy_img = zeros(size(img));
        strength = get(noiseSlider, 'Value');

        for c = 1:ch
            phase = rand(rows, cols) * 2 * pi;
            amplitude = zeros(rows, cols);
            regionSize = 100;
            centerR = floor(rows / 2); centerC = floor(cols / 2);
            amplitude(centerR - regionSize/2 : centerR + regionSize/2, ...
                      centerC - regionSize/2 : centerC + regionSize/2) = 1;
            complex_field = amplitude .* exp(1i * phase);
            speckle = abs(ifft2(complex_field)).^strength;
            speckle_pattern(:, :, c) = mat2gray(speckle);
            noisy_img(:, :, c) = img(:, :, c) .* speckle_pattern(:, :, c);
        end

        noisy_img = mat2gray(noisy_img);
        imshow(speckle_pattern(:,:,1), 'Parent', ax2);  % Speckle Pattern
        imshow(noisy_img, 'Parent', ax3);  % Noisy Image
    end

    function removeNoise(~, ~)
        if isempty(noisy_img) || isempty(speckle_pattern)
            errordlg('Add speckle noise first!');
            return;
        end
        fsize = 2 * floor(get(filterSlider, 'Value') / 2) + 1;
        filtered_img = zeros(size(noisy_img));
        for c = 1:size(noisy_img, 3)
            norm_chan = noisy_img(:, :, c) ./ (speckle_pattern(:, :, c) + eps);
            norm_chan = mat2gray(norm_chan + 0.02*randn(size(norm_chan)));  % Add slight variation
            filtered_img(:, :, c) = medfilt2(norm_chan, [fsize fsize]);
        end
        filtered_img = mat2gray(filtered_img);
        imshow(filtered_img, 'Parent', ax4);  % Filtered Image
    end

    function saveImage(~, ~)
        if isempty(filtered_img)
            errordlg('No filtered image to save!');
            return;
        end
        [file, path] = uiputfile({'*.png'; '*.jpg'; '*.bmp'}, 'Save Filtered Image');
        if isequal(file, 0), return; end
        imwrite(filtered_img, fullfile(path, file));
        msgbox('Image saved successfully!');
    end

 function makeLabel(x, y, textStr)
    uicontrol('Style', 'text', 'Units', 'normalized', ...
              'Position', [x, y, 0.2, 0.04], ...
              'String', textStr, 'BackgroundColor', [1 1 1], ...
              'FontWeight', 'bold', 'FontSize', 11, ...
              'HorizontalAlignment', 'center');
end

end
