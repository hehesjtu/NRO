function NRO_UI

    hFig = [];
    img_origin = [];         % Original Image I
    img_NRO_Enhanced = [];   % NRO Result 
    SCALE_FACTOR = 1.25; 
  
    createInterface();

    function createInterface()
        hFig = figure('Name', 'NRO Image Enhancement System', ...
                      'NumberTitle', 'off', ...
                      'MenuBar', 'none', ...
                      'ToolBar', 'none', ...
                      'Position', [100, 100, 1100, 600], ... 
                      'Color', [0.94 0.94 0.94]);

        hPanel = uipanel('Parent', hFig, 'Position', [0, 0.88, 1, 0.12], ...
                         'BackgroundColor', [0.94 0.94 0.94], 'BorderType', 'none');

        uicontrol('Parent', hPanel, 'Style', 'pushbutton', 'String', 'Load Image', ...
                  'FontSize', 11, 'FontWeight', 'bold', ...
                  'Position', [20, 20, 120, 40], ...
                  'Callback', @cb_LoadImage, 'BackgroundColor', [1 1 1]);

        uicontrol('Parent', hPanel, 'Style', 'pushbutton', 'String', 'Launch NRO', ...
                            'FontSize', 11, 'FontWeight', 'bold', ...
                            'Position', [160, 20, 120, 40], ...
                            'Callback', @cb_RunNRO, 'Enable', 'off', 'Tag', 'BtnRun', ...
                            'BackgroundColor', [0.2 0.6 1], 'ForegroundColor', [1 1 1]);
        
        uicontrol('Parent', hPanel, 'Style', 'text', 'String', 'Enhancement Factor:', ...
                  'FontSize', 11, 'Position', [300, 30, 150, 20], ... 
                  'BackgroundColor', [0.94 0.94 0.94], 'HorizontalAlignment', 'right');
        
        uicontrol('Parent', hPanel, 'Style', 'edit', 'String', '4.0', ...
                  'FontSize', 11, 'Position', [460, 28, 60, 28], ...
                  'Tag', 'EditFactor', 'BackgroundColor', [1 1 1]);

        uicontrol('Parent', hPanel, 'Style', 'text', 'String', 'Ready - Please load an image.', ...
                  'FontSize', 10, 'Position', [540, 28, 500, 25], ...
                  'BackgroundColor', [0.94 0.94 0.94], 'HorizontalAlignment', 'left', ...
                  'Tag', 'StatusText', 'ForegroundColor', [0.4 0.4 0.4]);

        % === Image Display Area ===
        hAx1 = axes('Parent', hFig, 'Position', [0.02, 0.15, 0.47, 0.68]);
        title(hAx1, 'Input Image', 'FontSize', 12, 'FontWeight', 'bold');
        axis(hAx1, 'off'); set(hAx1, 'Tag', 'AxOrigin');

        hAx2 = axes('Parent', hFig, 'Position', [0.51, 0.15, 0.47, 0.68]);
        title(hAx2, 'NRO Enhanced Result', 'FontSize', 12, 'FontWeight', 'bold', 'Color', [0 0.4 0.8]);
        axis(hAx2, 'off'); set(hAx2, 'Tag', 'AxNRO');

        uicontrol('Parent', hFig, 'Style', 'pushbutton', 'String', 'Save Result', ...
                  'FontSize', 10, 'Position', [900, 20, 120, 35], ...
                  'Callback', @cb_SaveNRO, 'Enable', 'off', 'Tag', 'BtnSaveNRO');

        uicontrol('Parent', hFig, 'Style', 'text', 'String', '', ...
                  'FontSize', 12, 'FontWeight', 'bold', ...
                  'Position', [500, 25, 380, 30], ...
                  'BackgroundColor', [0.94 0.94 0.94], 'HorizontalAlignment', 'center', ...
                  'Tag', 'TextMetrics', 'ForegroundColor', [0.8 0 0]);
    end

    % --- Callback: Load Image ---
    function cb_LoadImage(~, ~)
        [filename, pathname] = uigetfile({'*.png;*.jpg;*.bmp;*.tif', 'Images'}, 'Select Image');
        if isequal(filename, 0), return; end
        
        filepath = fullfile(pathname, filename);
        setStatus('Loading image...');
        
        try
            raw_img = imread(filepath);
            img_origin = double(raw_img); % 与 main.m 保持一致，存储为 double (0-255)
            
            hAx = findobj(hFig, 'Tag', 'AxOrigin');
            imshow(uint8(img_origin), 'Parent', hAx);
            title(hAx, sprintf('Input Image (%dx%d)', size(img_origin, 2), size(img_origin, 1)));
            
            cla(findobj(hFig, 'Tag', 'AxNRO'));
            img_NRO_Enhanced = [];
            set(findobj(hFig, 'Tag', 'TextMetrics'), 'String', '');
            set(findobj(hFig, 'Tag', 'BtnRun'), 'Enable', 'on');
            set(findobj(hFig, 'Tag', 'BtnSaveNRO'), 'Enable', 'off');
            setStatus(['Loaded: ' filename]);
        catch ME
            errordlg(ME.message);
        end
    end

    % --- Callback: Execute NRO ---
    function cb_RunNRO(~, ~)
        if isempty(img_origin), return; end
        
        % Get Parameters
        factor_str = get(findobj(hFig, 'Tag', 'EditFactor'), 'String');
        enhance_factor = str2double(factor_str);
        if isnan(enhance_factor), enhance_factor = 4.0; end
        
        setStatus('Processing NRO, please wait...'); drawnow;
        
        try
            tic;
            [rows, cols, channels] = size(img_origin);
           
            raw_uint8 = uint8(img_origin);
            
            if channels == 1
                img_process = cat(3, raw_uint8, raw_uint8, raw_uint8);
            else
                img_process = raw_uint8;
            end

            I_ycbcr = rgb2ycbcr(img_process);
            I_y = double(I_ycbcr(:,:,1)); 
            
      
            L1_slice   = imresize(I_y, SCALE_FACTOR, 'bilinear');
            L0_blurred = imresize(L1_slice, size(I_y), 'bilinear');
            H0_slice   = I_y - L0_blurred;
            
            
            Res_Large = NRO(I_y, L1_slice, H0_slice);
            
            
            Details_NRO = imresize(Res_Large, [rows, cols], 'bilinear');
            
            I_y_enh = I_y + Details_NRO * enhance_factor;
            I_y_enh = max(0, min(255, I_y_enh)); 
            
            
            I_ycbcr_enh = I_ycbcr;
            I_ycbcr_enh(:,:,1) = uint8(I_y_enh);
            Out_NRO = ycbcr2rgb(I_ycbcr_enh);
            
            if channels == 1
                Out_NRO = Out_NRO(:, :, 1);
            end

            img_NRO_Enhanced = Out_NRO;
            ref_img_uint8 = uint8(img_origin);
            
           
            val_psnr = psnr(Out_NRO, ref_img_uint8);
            val_ssim = ssim(Out_NRO, ref_img_uint8);
            
            metrics_str = sprintf('PSNR: %.2f dB  |  SSIM: %.4f', val_psnr, val_ssim);
            set(findobj(hFig, 'Tag', 'TextMetrics'), 'String', metrics_str);

            % --- Refresh Display ---
            hAxNRO = findobj(hFig, 'Tag', 'AxNRO');
            imshow(img_NRO_Enhanced, 'Parent', hAxNRO);
            title(hAxNRO, sprintf('NRO Enhanced Result (Factor=%.1f)', enhance_factor));
            
            set(findobj(hFig, 'Tag', 'BtnSaveNRO'), 'Enable', 'on');
            setStatus(sprintf('Done! Time: %.2f s', toc));
            
        catch ME
            setStatus('Execution Error');
            errordlg(ME.message);
        end
    end

    
    function cb_SaveNRO(~, ~)
        if isempty(img_NRO_Enhanced), return; end
        
        default_name = sprintf('NRO_Result_%s.png', datestr(now, 'HHMMSS'));
        [f, p] = uiputfile('*.png', 'Save Result', default_name);
        
        if f
            imwrite(img_NRO_Enhanced, fullfile(p, f));
            setStatus(['Saved: ' f]);
        end
    end

    function setStatus(str)
        set(findobj(hFig, 'Tag', 'StatusText'), 'String', str);
    end
end