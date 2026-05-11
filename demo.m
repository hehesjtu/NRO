function NRO_UI

    % ── 共享状态 ──────────────────────────────────────────────────────────
    hFig             = [];
    img_origin       = [];        % 原始图像 (double, 0-255)
    img_NRO_Enhanced = [];        % NRO 结果
    SCALE_FACTOR     = 1.25;

    % ── UI 句柄 ──────────────────────────────────────────────────────────
    hAx1        = [];   % 左侧轴 – 输入图像
    hAx2        = [];   % 右侧轴 – NRO 结果
    hBtnRun     = [];
    hBtnSave    = [];
    hStatus     = [];
    hMetrics    = [];
    hEditFactor = [];

    createInterface();

    % ═════════════════════════════════════════════════════════════════════════
    function createInterface()
        hFig = figure('Name',        'NRO Image Enhancement System (OpenMP Engine)', ...
                      'NumberTitle', 'off', ...
                      'MenuBar',     'none', ...
                      'ToolBar',     'none', ...
                      'Position',    [100, 100, 1100, 600], ...
                      'Color',       [0.94 0.94 0.94]);

        hPanel = uipanel('Parent', hFig, ...
                         'Position',        [0, 0.88, 1, 0.12], ...
                         'BackgroundColor', [0.94 0.94 0.94], ...
                         'BorderType',      'none');

        % 加载图像按钮
        uicontrol('Parent', hPanel, 'Style', 'pushbutton', ...
                  'String',          'Load Image', ...
                  'FontSize',        11, 'FontWeight', 'bold', ...
                  'Position',        [20, 20, 120, 40], ...
                  'Callback',        @cb_LoadImage, ...
                  'BackgroundColor', [1 1 1]);

        % 运行 NRO 按钮
        hBtnRun = uicontrol('Parent', hPanel, 'Style', 'pushbutton', ...
                            'String',          'Launch NRO', ...
                            'FontSize',        11, 'FontWeight', 'bold', ...
                            'Position',        [160, 20, 120, 40], ...
                            'Callback',        @cb_RunNRO, ...
                            'Enable',          'off', ...
                            'BackgroundColor', [0.2 0.6 1], ...
                            'ForegroundColor', [1 1 1]);

        uicontrol('Parent', hPanel, 'Style', 'text', ...
                  'String',             'Enhancement Factor:', ...
                  'FontSize',           11, ...
                  'Position',           [300, 30, 150, 20], ...
                  'BackgroundColor',    [0.94 0.94 0.94], ...
                  'HorizontalAlignment','right');

        % 增强因子输入框
        hEditFactor = uicontrol('Parent', hPanel, 'Style', 'edit', ...
                                'String',          '4.0', ...
                                'FontSize',        11, ...
                                'Position',        [460, 28, 60, 28], ...
                                'BackgroundColor', [1 1 1]);

        % 状态标签
        hStatus = uicontrol('Parent', hPanel, 'Style', 'text', ...
                            'String',             'Ready - Please load an image.', ...
                            'FontSize',           10, ...
                            'Position',           [540, 28, 500, 25], ...
                            'BackgroundColor',    [0.94 0.94 0.94], ...
                            'HorizontalAlignment','left', ...
                            'ForegroundColor',    [0.4 0.4 0.4]);

        % ── 图像显示区域 ──────────────────────────────────────────────────────
        hAx1 = axes('Parent', hFig, 'Position', [0.02, 0.15, 0.47, 0.68]);
        title(hAx1, 'Input Image', 'FontSize', 12, 'FontWeight', 'bold');
        axis(hAx1, 'off');

        hAx2 = axes('Parent', hFig, 'Position', [0.51, 0.15, 0.47, 0.68]);
        title(hAx2, 'NRO Enhanced Result', ...
              'FontSize', 12, 'FontWeight', 'bold', 'Color', [0 0.4 0.8]);
        axis(hAx2, 'off');

        % 保存结果按钮
        hBtnSave = uicontrol('Parent', hFig, 'Style', 'pushbutton', ...
                             'String',   'Save Result', ...
                             'FontSize', 10, ...
                             'Position', [900, 20, 120, 35], ...
                             'Callback', @cb_SaveNRO, ...
                             'Enable',   'off');

        % 指标显示
        hMetrics = uicontrol('Parent', hFig, 'Style', 'text', ...
                             'String',             '', ...
                             'FontSize',           12, 'FontWeight', 'bold', ...
                             'Position',           [500, 25, 380, 30], ...
                             'BackgroundColor',    [0.94 0.94 0.94], ...
                             'HorizontalAlignment','center', ...
                             'ForegroundColor',    [0.8 0 0]);
    end

    % ═════════════════════════════════════════════════════════════════════════
    % 回调：加载图像
    % ═════════════════════════════════════════════════════════════════════════
    function cb_LoadImage(~, ~)
        [filename, pathname] = uigetfile( ...
            {'*.png;*.jpg;*.bmp;*.tif', 'Images'}, 'Select Image');
        if isequal(filename, 0), return; end

        setStatus('Loading image...');
        try
            raw_img    = imread(fullfile(pathname, filename));
            img_origin = double(raw_img); 

            imshow(uint8(img_origin), 'Parent', hAx1);
            title(hAx1, sprintf('Input Image (%dx%d)', ...
                  size(img_origin,2), size(img_origin,1)), ...
                  'FontSize', 12, 'FontWeight', 'bold');

            cla(hAx2);                               
            title(hAx2, 'NRO Enhanced Result', ...   
                  'FontSize', 12, 'FontWeight', 'bold', 'Color', [0 0.4 0.8]);
            axis(hAx2, 'off');

            img_NRO_Enhanced = [];
            set(hMetrics,  'String', '');
            set(hBtnRun,   'Enable', 'on');
            set(hBtnSave,  'Enable', 'off');
            setStatus(['Loaded: ' filename]);
        catch ME
            errordlg(ME.message, 'Load Error');
        end
    end

    % ═════════════════════════════════════════════════════════════════════════
    % 回调：运行 NRO
    % ═════════════════════════════════════════════════════════════════════════
    function cb_RunNRO(~, ~)
        if isempty(img_origin), return; end

        enhance_factor = str2double(get(hEditFactor, 'String'));
        if isnan(enhance_factor) || enhance_factor <= 0
            enhance_factor = 4.0;
            set(hEditFactor, 'String', '4.0');
        end

        % ── 核心依赖检测 (专为 .p 文件发布优化) ─────────────────────────────
        % 检测 NRO.p 或 NRO.m 是否存在
        if exist('NRO', 'file') == 0
            errordlg('Missing algorithm file: NRO.p or NRO.m is not found in the current directory.', 'Dependency Error');
            return;
        end
        
        % 检测 C++ MEX 引擎是否已编译 (返回值 3 代表 MEX 文件)
        if exist('nro_solver', 'file') ~= 3
            errordlg('Missing MEX Engine: nro_solver has not been compiled for this platform. Please run compilation first.', 'Dependency Error');
            return;
        end
        % ──────────────────────────────────────────────────────────────────

        set(hBtnRun,  'Enable', 'off');
        set(hBtnSave, 'Enable', 'off');

        try
            setStatus('[ Processing ] Calling NRO Core...');
            drawnow;
            total_tic = tic;

            % ── 预处理 ────────────────────────────────────────────────────────
            [rows, cols, channels] = size(img_origin);
            raw_uint8 = uint8(img_origin);

            if channels == 1
                img_process = cat(3, raw_uint8, raw_uint8, raw_uint8);
            else
                img_process = raw_uint8;
            end

            I_ycbcr = rgb2ycbcr(img_process);
            I_y     = double(I_ycbcr(:,:,1));

            L1_slice   = imresize(I_y, SCALE_FACTOR, 'bilinear');
            L0_blurred = imresize(L1_slice, size(I_y), 'bilinear');
            H0_slice   = I_y - L0_blurred;

            % ── 核心算法计时 (调用 NRO.p 和 C++ 引擎) ──────────────────────────
            core_tic = tic;
            Res_Large   = NRO(I_y, L1_slice, H0_slice);
            core_time   = toc(core_tic);
            % ──────────────────────────────────────────────────────────────────

            % ── 后处理 ────────────────────────────────────────────────────────
            Details_NRO = imresize(Res_Large, [rows, cols], 'bilinear');

            I_y_enh = I_y + Details_NRO * enhance_factor;
            I_y_enh = max(0, min(255, I_y_enh));

            I_ycbcr_enh         = I_ycbcr;
            I_ycbcr_enh(:,:,1)  = uint8(I_y_enh);
            Out_NRO             = ycbcr2rgb(I_ycbcr_enh);

            if channels == 1
                Out_NRO = Out_NRO(:,:,1);
            end

            % ── 指标计算 (PSNR/SSIM) ──────────────────────────────────────────
            img_NRO_Enhanced = Out_NRO;
            ref_uint8        = uint8(img_origin);

            val_psnr = psnr(Out_NRO, ref_uint8);
            val_ssim = ssim(Out_NRO, ref_uint8);
            set(hMetrics, 'String', ...
                sprintf('PSNR: %.2f dB  |  SSIM: %.4f', val_psnr, val_ssim));

            % ── 渲染结果 ──────────────────────────────────────────────────────
            imshow(img_NRO_Enhanced, 'Parent', hAx2);
            title(hAx2, sprintf('NRO Enhanced Result (Factor=%.1f)', enhance_factor), ...
                  'FontSize', 12, 'FontWeight', 'bold', 'Color', [0 0.4 0.8]);

            set(hBtnSave, 'Enable', 'on');

            total_time = toc(total_tic);

            % ── 更新状态栏 ────────────────────────────────────────────────────
            setStatus(sprintf( ...
                'Done! Core Algorithm: %.2f s | Total Pipeline (UI+Metrics): %.2f s', ...
                core_time, total_time));

        catch ME
            setStatus('Execution Error');
            errordlg(ME.message, 'NRO Error');
        end

        set(hBtnRun, 'Enable', 'on');   
    end

    % ═════════════════════════════════════════════════════════════════════════
    % 回调：保存结果
    % ═════════════════════════════════════════════════════════════════════════
    function cb_SaveNRO(~, ~)
        if isempty(img_NRO_Enhanced), return; end

        default_name = sprintf('NRO_Result_%s.png', datestr(now, 'HHMMSS'));
        [f, p] = uiputfile('*.png', 'Save Result', default_name);
        if f
            imwrite(img_NRO_Enhanced, fullfile(p, f));
            setStatus(['Saved: ' f]);
        end
    end

    % ─────────────────────────────────────────────────────────────────────────
    function setStatus(str)
        set(hStatus, 'String', str);
        drawnow;
    end
end