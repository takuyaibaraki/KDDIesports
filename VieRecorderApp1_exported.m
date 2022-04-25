classdef VieRecorderApp1_exported < matlab.apps.AppBase
    
    % Properties that correspond to app components
    properties (Access = public)
        UIFigure           matlab.ui.Figure
        GridLayout         matlab.ui.container.GridLayout
        LeftPanel          matlab.ui.container.Panel
        SAVEButton         matlab.ui.control.Button
        STOPButton         matlab.ui.control.Button
        HighPassKnob       matlab.ui.control.Knob
        HighPassKnobLabel  matlab.ui.control.Label
        LowPassKnob        matlab.ui.control.Knob
        LowPassKnobLabel   matlab.ui.control.Label
        STARTButton        matlab.ui.control.Button
        RightPanel         matlab.ui.container.Panel
        UIAxes             matlab.ui.control.UIAxes
    end
    
    % Properties that correspond to apps with auto-reflow
    properties (Access = private)
        onePanelWidth = 576;
    end
    
    
    properties (Access = private)
        Property % Description
    end
    
    properties (Access = public)
        SAMPLE_FREQ=600;
        rec_time=120;
        cidx=1;cir=1;
        cbaseline=[0 0 0];
    end
    
    
    methods (Access = public)
        function    [B1,A1]  = FilterData(app)
            lowpass = app.LowPassKnob.Value;
            highpass = app.HighPassKnob.Value;
            SAMPLE_FREQ=600;
            [B1,A1] = butter(4,[highpass/(SAMPLE_FREQ/2) lowpass/(SAMPLE_FREQ/2)]);%1-40Hz BandPass
        end
    end
    
    
    % Callbacks that handle component events
    methods (Access = private)
        
        % Code that executes after component creation
        function startupFcn(app)
            %VIE Recorderの起動
            %             !C:\Users\ibarakit\OneDrive - 株式会社エヌ・ティ・ティ・データ経営研究所\VIE STYLE\script\VieRecorder\VieRecorder.exe &
        end
        
        % Changes arrangement of the app based on UIFigure width
        function updateAppLayout(app, event)
            currentFigureWidth = app.UIFigure.Position(3);
            if(currentFigureWidth <= app.onePanelWidth)
                % Change to a 2x1 grid
                app.GridLayout.RowHeight = {573, 573};
                app.GridLayout.ColumnWidth = {'1x'};
                app.RightPanel.Layout.Row = 2;
                app.RightPanel.Layout.Column = 1;
            else
                % Change to a 1x2 grid
                app.GridLayout.RowHeight = {'1x'};
                app.GridLayout.ColumnWidth = {220, '1x'};
                app.RightPanel.Layout.Row = 1;
                app.RightPanel.Layout.Column = 2;
            end
        end
        
        % Callback function
        function UIAxesButtonDown(app, event)
            
        end
        
        % Callback function: STARTButton, UIAxes
        function ButtonPushed(app, event)
            global STOPButtonFlag SAVEButtonFlag deleteFlag
            Zf1=[]; STOPButtonFlag=0;SAVEButtonFlag=0;deleteFlag=0;
            cidx=app.cidx;cbaseline=app.cbaseline;
            
            %% 以下Vie Recorderのあるフォルダを設定してください
            defaultpath=pwd;
            %             defaultpath=mfilename('fullpath');
            %             defaultpath=defaultpath(1:max(strfind(defaultpath,'\'))-1)
            %             %             defaultpath='C:\Users\ibarakit\OneDrive - 株式会社エヌ・ティ・ティ・データ経営研究所\VIE STYLE\script\VieRecorder';%             filelist=dir(['C:\Users\ibarakit\OneDrive - 株式会社エヌ・ティ・ティ・データ経営研究所\VIE STYLE\script\VieRecorder\VieOutput\*.csv'])
            mkdir([defaultpath '\EEGdata']);
            filename=[defaultpath '\VieOutput\' 'VieRawData.csv' ];%             filename=[filelist(1).folder '\' filelist(1).name ];%VieRawData.csv
            alldata=[];
            opts = detectImportOptions(filename);
            opts.SelectedVariableNames = [2 3];
            opts.DataLines=[2 inf];
            
            alldata=[alldata;readmatrix(filename,opts).*18.3./64];
            alldata=[alldata alldata(:,2)-alldata(:,1)];
            craw=size(alldata,1);
            SAMPLE_FREQ=600;
            
            cplotdata=repmat(0,SAMPLE_FREQ*4,3);%initial data
            
            tsstart = tic;
            alldata=[];%flash before recorded data
            while 1
                if STOPButtonFlag
                    title(app.UIAxes,['EEG (' num2str(round(telapsed,2)) 's)' ' STOP'])
                    break
                elseif deleteFlag
                    delete(app)
                    return
                    break
                end
                pause(0.2)%5Hz sampling 120data sample
                % read csv
                [B1,A1]  = FilterData(app);
                opts.DataLines=[craw+1 inf];
                tempdata=readmatrix(filename,opts).*18.3./64;
                if ~isempty(tempdata)
                    tempdata=[tempdata tempdata(:,2)-tempdata(:,1)];
                    alldata=[alldata;tempdata];
                    craw=craw+size(tempdata,1);
                    
                    [tempdata1,Zf1] = filter(B1, A1, tempdata,Zf1); % Fillter Application
                    
                    if cidx+size(tempdata,1)-1<SAMPLE_FREQ*4 %4秒以下の場合
                        cplotdata(cidx:cidx+size(tempdata,1)-1,:)=tempdata1;
                        cidx=cidx+size(tempdata,1);
                    else %４秒を超えた場合
                        cplotdata(cidx:end,:)=tempdata1(end-(size(cplotdata,1)-cidx):end,:);
                        cidx=1;% reset
                        cbaseline=nanmean(cplotdata);
                    end
                    
                end
                %経過時間のチェック
                telapsed = toc(tsstart);
                
                plot(app.UIAxes,[1:SAMPLE_FREQ*4]/SAMPLE_FREQ,cplotdata(:,[1 2])-cbaseline([ 1 2]));
                ylim(app.UIAxes,[-150 150])
                xlim(app.UIAxes,[0 4])
                title(app.UIAxes,['EEG (' num2str(round(telapsed,2)) 's)'])
                xlabel(app.UIAxes,'time (s)')
                ylabel(app.UIAxes,'uV')
                legend(app.UIAxes,{'L' 'R'})
                %                 yline(app.UIAxes,0,'--')
            end
            
            if STOPButtonFlag
                while 1
                    pause(0.2)%5Hz sampling 120data sample
                    if  SAVEButtonFlag
                        title(app.UIAxes,['EEG (' num2str(round(telapsed,2)) 's)' ' SAVE'])
                        save( [defaultpath '\EEGdata\' datestr(now,30) '_EEGdata.mat'], 'alldata','SAMPLE_FREQ');
                        break
                        SAVEButtonFlag=0;
                    end
                    if deleteFlag
                        delete(app)
                        return
                        break
                    end
                end
            end
            
        end
        % Value changed function: HighPassKnob
        function HighPassKnobValueChanged(app, event)
            value = app.HighPassKnob.Value;
            if value==0
                app.HighPassKnob.Value=0.1;
            end
        end
        
        % Value changed function: LowPassKnob
        function LowPassKnobValueChanged(app, event)
            value = app.LowPassKnob.Value;
            if value==0
                app.LowPassKnob.Value=0.1;
            end
        end
        
        % Button pushed function: STOPButton
        function STOPButtonPushed(app, event)
            global STOPButtonFlag
            STOPButtonFlag=1
        end
        
        % Button pushed function: SAVEButton
        function SAVEButtonPushed(app, event)
            global SAVEButtonFlag
            SAVEButtonFlag=1
        end
        
        % Close request function: UIFigure
        function UIFigureCloseRequest(app, event)
            global deleteFlag
            YN = uiconfirm(app.UIFigure,'Do you want to close the app?', 'Close request');
            if strcmpi(YN,'OK')
                deleteFlag=1
            end
        end
    end
    
    % Component initialization
    methods (Access = private)
        
        % Create UIFigure and components
        function createComponents(app)
            % Create UIFigure and hide until all components are created
            app.UIFigure = uifigure('Visible', 'off');
            app.UIFigure.AutoResizeChildren = 'off';
            app.UIFigure.Position = [100 100 1422 573];
            app.UIFigure.Name = 'MATLAB App';
            app.UIFigure.CloseRequestFcn = createCallbackFcn(app, @UIFigureCloseRequest, true);
            app.UIFigure.SizeChangedFcn = createCallbackFcn(app, @updateAppLayout, true);
            
            % Create GridLayout
            app.GridLayout = uigridlayout(app.UIFigure);
            app.GridLayout.ColumnWidth = {220, '1x'};
            app.GridLayout.RowHeight = {'1x'};
            app.GridLayout.ColumnSpacing = 0;
            app.GridLayout.RowSpacing = 0;
            app.GridLayout.Padding = [0 0 0 0];
            app.GridLayout.Scrollable = 'on';
            
            % Create LeftPanel
            app.LeftPanel = uipanel(app.GridLayout);
            app.LeftPanel.Layout.Row = 1;
            app.LeftPanel.Layout.Column = 1;
            
            % Create STARTButton
            app.STARTButton = uibutton(app.LeftPanel, 'push');
            app.STARTButton.ButtonPushedFcn = createCallbackFcn(app, @ButtonPushed, true);
            app.STARTButton.Position = [43 496 138 22];
            app.STARTButton.Text = 'START';
            
            % Create LowPassKnobLabel
            app.LowPassKnobLabel = uilabel(app.LeftPanel);
            app.LowPassKnobLabel.HorizontalAlignment = 'center';
            app.LowPassKnobLabel.Position = [83 27 58 22];
            app.LowPassKnobLabel.Text = 'Low Pass';
            
            % Create LowPassKnob
            app.LowPassKnob = uiknob(app.LeftPanel, 'continuous');
            app.LowPassKnob.Limits = [0 60];
            app.LowPassKnob.ValueChangedFcn = createCallbackFcn(app, @LowPassKnobValueChanged, true);
            app.LowPassKnob.Position = [81 83 60 60];
            app.LowPassKnob.Value = 30;
            
            % Create HighPassKnobLabel
            app.HighPassKnobLabel = uilabel(app.LeftPanel);
            app.HighPassKnobLabel.HorizontalAlignment = 'center';
            app.HighPassKnobLabel.Position = [83 193 60 22];
            app.HighPassKnobLabel.Text = 'High Pass';
            
            % Create HighPassKnob
            app.HighPassKnob = uiknob(app.LeftPanel, 'continuous');
            app.HighPassKnob.Limits = [0 20];
            app.HighPassKnob.ValueChangedFcn = createCallbackFcn(app, @HighPassKnobValueChanged, true);
            app.HighPassKnob.Position = [82 249 60 60];
            app.HighPassKnob.Value = 3;
            
            % Create STOPButton
            app.STOPButton = uibutton(app.LeftPanel, 'push');
            app.STOPButton.ButtonPushedFcn = createCallbackFcn(app, @STOPButtonPushed, true);
            app.STOPButton.Position = [43 448 138 22];
            app.STOPButton.Text = 'STOP';
            
            % Create SAVEButton
            app.SAVEButton = uibutton(app.LeftPanel, 'push');
            app.SAVEButton.ButtonPushedFcn = createCallbackFcn(app, @SAVEButtonPushed, true);
            app.SAVEButton.Position = [44 394 138 22];
            app.SAVEButton.Text = 'SAVE';
            
            % Create RightPanel
            app.RightPanel = uipanel(app.GridLayout);
            app.RightPanel.Layout.Row = 1;
            app.RightPanel.Layout.Column = 2;
            
            % Create UIAxes
            app.UIAxes = uiaxes(app.RightPanel);
            title(app.UIAxes, 'In-Ear EEG')
            xlabel(app.UIAxes, 'sec')
            ylabel(app.UIAxes, 'uV')
            zlabel(app.UIAxes, 'Z')
            app.UIAxes.ButtonDownFcn = createCallbackFcn(app, @ButtonPushed, true);
            app.UIAxes.Position = [26 77 1099 434];
            
            % Show the figure after all components are created
            app.UIFigure.Visible = 'on';
        end
    end
    
    % App creation and deletion
    methods (Access = public)
        
        % Construct app
        function app = VieRecorderApp1_exported
            
            % Create UIFigure and components
            createComponents(app)
            
            % Register the app with App Designer
            registerApp(app, app.UIFigure)
            
            % Execute the startup function
            runStartupFcn(app, @startupFcn)
            
            if nargout == 0
                clear app
            end
        end
        
        % Code that executes before app deletion
        function delete(app)
            % Delete UIFigure when app is deleted
            delete(app.UIFigure)
        end
    end
end