%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% 2022  Experiment Program by T.Ibaraki @NTTDIOMC,Inc.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
clc
clear
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% パスのセッティング
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
defaultpath=pwd;
mkdir([defaultpath '\data']);
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% EXPERIMENT PARAMETERS ここにある変数をいじると実験のプロトコルを調整できる。
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
RecDuration=30;%sec
FeedbackDuration=60;

%% default alpha
minfreq=8;
maxfreq=12;
MaxZ=3 ;%max zscore from baseline
timeWindow=1;
% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% subject parameter
% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
subName =strtrim( input('subject name is ', 's')); % 被験者名の入力
savefilename=[defaultpath '\data' '\' subName '-' datestr(now,30) 'RestingAlpha_VIE' ];

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% EEG SETTING (VIE ZONE)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
filename=[defaultpath '\VieOutput\' 'VieRawData.csv' ];%             filename=[filelist(1).folder '\' filelist(1).name ];%VieRawData.csv
opts = detectImportOptions(filename);
opts.SelectedVariableNames = [2 3];

SAMPLE_FREQ_VIE=600;

%% Filter Setting
[B1f,A1f] = butter(4,[3/(SAMPLE_FREQ_VIE/2) 40/(SAMPLE_FREQ_VIE/2)]);% 3~40Hzバタワースフィルタ設計
Zf1=[];

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% 実験初期設定
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
KbName('UnifyKeyNames');
%% 押されっぱなしのキーを無効化
tic;
while toc < 1; end;
DisableKeysForKbCheck([]);    % 無効にするキーの初期化
[keyIsDown, secs, keyCode ] = KbCheck;    % 常に押されるキー情報を取得する
% 常に押されている（と誤検知されている）キーがあったら、それを無効にする
if keyIsDown
    fprintf('無効にしたキーがあります\n');
    keys=find(keyCode) % keyCodeの表示
    KbName(keys) % キーの名前を表示
    DisableKeysForKbCheck(keys);
end

Screen('Preference', 'SkipSyncTests', 1);%　これを入れないと時々エラーが出る
Screen('Preference', 'TextRenderer', 1);
Screen('Preference', 'TextAntiAliasing', 1);
Screen('Preference', 'TextAlphaBlending', 0);
AssertOpenGL;
%     ListenChar(2)

%Screen setting
windowsize=[];
screenid = max(Screen('Screens'));

ScreenDevices = java.awt.GraphicsEnvironment.getLocalGraphicsEnvironment().getScreenDevices();
MainScreen = java.awt.GraphicsEnvironment.getLocalGraphicsEnvironment().getDefaultScreenDevice().getScreen()+1;
MainBounds = ScreenDevices(MainScreen).getDefaultConfiguration().getBounds();
MonitorPositions = zeros(numel(ScreenDevices),4);
for n = 1:numel(ScreenDevices)
    Bounds = ScreenDevices(n).getDefaultConfiguration().getBounds();
    MonitorPositions(n,:) = [Bounds.getLocation().getX() + 1,-Bounds.getLocation().getY() + 1 - Bounds.getHeight() + MainBounds.getHeight(),Bounds.getWidth(),Bounds.getHeight()];
end

windowsize=get(0,'MonitorPositions');
%     [w, rect] = Screen('OpenWindow',screenid, 0  , []); %2画面目に実験画面
[w, rect] = Screen('OpenWindow',screenid, 0  , [MonitorPositions(1,1)  MonitorPositions(1,2) MonitorPositions(1,1)+MonitorPositions(1,3) MonitorPositions(1,4)-250]); %test
h=figure('Position',[windowsize(1,1) windowsize(1,2) windowsize(1,3) 230],'Color','k');%alwaysontop(h)
h.MenuBar='none';h.ToolBar='none';

[centerX, centerY] = RectCenter(rect);%画面の中央の座標
HideCursor();

Screen('TextFont',w, 'Courier New');
Screen('TextSize',w, 25);
Screen('TextStyle', w, 0);
Screen('BlendFunction', w, 'GL_SRC_ALPHA', 'GL_ONE_MINUS_SRC_ALPHA');
Screen('TextFont', w, '-:lang=ja');

EXstart=GetSecs;
EndFlag=0;
TrialNo=1;

%% マーカーの設定
rectwidth=30;
rectcolor=[255 0 0];
rectContoursize=[rectwidth rect(4)/2];     %%
MarkerTop=centerY-rectContoursize(2)/2;
MarkerBottom=centerY+rectContoursize(2)/2;

%音声の作成
freq=44100;
cf = 440;                  % carrier frequency (Hz)
d = 0.2;                    % duration (s)
n = freq * d;                 % number of samples
s = (1:n) / freq;             % sound data preparation
S = sin(2 * pi * cf * s);   % sinusoidal modulation

InitializePsychSound;% Perform basic initialization of the sound driver:
pahandle = PsychPortAudio('Open', [], [], 0, freq, 1);% Fill the audio playback buffer with the audio data 'wavedata':

%store EEG data setting
opts.DataLines=[2 inf];
craw=size(readmatrix(filename,opts).*18.3./64,1);% Read Start row
alldataV=[];%empty data for EEG
%% EEG Monitor Window
mtimeWindow=4;
cplotdata=repmat(0,SAMPLE_FREQ_VIE*mtimeWindow,3);
cidx=1;
cbaseline=[0 0 0];

%% Experiment START
DrawFormattedText(w,double([ '脳波計測を開始します　目をあけて安静にしていてください\n\nキーを押してして計測スタート']), 'center', 'center',  WhiteIndex(w));
Screen('Flip', w);%上で指定された情報を画面に表示
WaitSecs(1);%     KbWait;%何かキーを押されるのを待つ
KbWait;

Recstart=GetSecs;
while GetSecs-Recstart<RecDuration
    WaitSecs(0.1);
    %% store EEG(VIE ZONE)
    opts.DataLines=[craw+1 inf];
    tempdataV=readmatrix(filename,opts).*18.3./64;
    if ~isempty(tempdataV)
        tempdataV=[tempdataV tempdataV(:,2)-tempdataV(:,1)];
        alldataV=[alldataV;tempdataV];
        craw=craw+size(tempdataV,1);

        [tempdata1,Zf1] = filter(B1f, A1f, tempdataV,Zf1);
        if cidx+size(tempdataV,1)-1<SAMPLE_FREQ_VIE*mtimeWindow
            cplotdata(cidx:cidx+size(tempdataV,1)-1,:)=tempdata1;
            cidx=cidx+size(tempdataV,1);
        else
            cplotdata(cidx:end,:)=tempdata1(end-(size(cplotdata,1)-cidx):end,:);
            cidx=1;
            cbaseline=nanmean(cplotdata);
        end
    end

    plot([1:SAMPLE_FREQ_VIE*mtimeWindow]/SAMPLE_FREQ_VIE,cplotdata-cbaseline,'LineWidth',1);
    ha1 = gca;ha1.GridColor=[1 1 1];
    set(gca,'Color','k')
    h_yaxis = ha1.YAxis; % 両 Y 軸の NumericRulerオブジェクト(2x1)を取得
    h_yaxis.Color = 'w'; % 軸の色を黒に変更
    h_yaxis.Label.Color = [1 1 1]; %  軸ラベルの色変更
    h_xaxis = ha1.XAxis; % 両 Y 軸の NumericRulerオブジェクト(2x1)を取得
    h_xaxis.Color = 'w'; % 軸の色を黒に変更
    h_xaxis.Label.Color = [1 1 1]; %  軸ラベルの色変更
    set(gca,'Color','k')
    xlim([0 4])
    title(['EEG (' num2str(round(GetSecs-Recstart,2)) 's)'],'Color' ,'w')
    xlabel('time (s)')
    ylabel('uV')
    lgd=legend({'L' 'R' 'diff'});
    lgd.TextColor=[1 1 1];
    yline(0,'w--');
    ylim([-75 75]);
    pause(0.5)

    DrawFormattedText(w,double(['計測中' num2str(round(GetSecs-Recstart)) 'sec']), 'center', 'center',  WhiteIndex(w));
    Screen('Flip', w);%上で指定された情報を画面に表示

    [ keyIsDown, keyTime, keyCode ] = KbCheck;
    if keyIsDown
        if keyCode(KbName('ESCAPE'))
            EndFlag=1;
            break; % while 文を抜けます。
        end
    end
end
PsychPortAudio('FillBuffer', pahandle, S );%
PsychPortAudio('Start', pahandle, 1);

%% Calc
y = bandpass(alldataV(end-SAMPLE_FREQ_VIE*RecDuration+1:end,:),[minfreq maxfreq],SAMPLE_FREQ_VIE) ;
y2 = hilbert(y);
env = abs(y2);
[z mu std]=zscore(env);
env(abs(z)>3)=NaN;
% figure
% plot(env)
M = movmean(env,SAMPLE_FREQ_VIE/2,'omitnan');
% figure
% plot(M)
[Mz Mmu Mstd]=zscore(M);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% NeuroFeedback
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%1st flip
y=centerY;
DrawFormattedText(w, double(['ニューロフィードバックを始めます。\n\nできるだけ赤いゲージを上にあげるように試行錯誤してみてください\n\nキーを押して開始']), 'center',50,[255 255 255]); %
DrawFormattedText(w,'0',centerX-rectContoursize(1)/2-40,'center', [255 255 255]); %

if y < MarkerTop
    y= MarkerTop;
elseif y > MarkerBottom
    y=MarkerBottom;
end
if y >centerY % カーソルが下段
    Screen('FillRect', w, [255 0 0], [centerX-rectContoursize(1)/2 centerY centerX+rectContoursize(1)/2 y]);
else% カーソルが上段
    Screen('FillRect', w, [255 0 0], [centerX-rectContoursize(1)/2 y centerX+rectContoursize(1)/2 centerY]);
end
Screen('FrameRect', w ,[255 255 255] ,[centerX-rectContoursize(1)/2 MarkerTop centerX+rectContoursize(1)/2 MarkerBottom],2);
Screen('DrawLines', w, [centerX-rectContoursize(1)/2 centerX+rectContoursize(1)/2 ; centerY centerY], 2,[255 255 255]);
Screen('Flip', w); %
%%%%%%%%%%%%
KbWait;

Recstart=GetSecs;decodedstate=[];
while GetSecs-Recstart<FeedbackDuration
    %% store EEG(VIE ZONE)
    opts.DataLines=[craw+1 inf];
    tempdataV=readmatrix(filename,opts).*18.3./64;
    if ~isempty(tempdataV)
        tempdataV=[tempdataV tempdataV(:,2)-tempdataV(:,1)];
        alldataV=[alldataV;tempdataV];
        craw=craw+size(tempdataV,1);

        [tempdata1,Zf1] = filter(B1f, A1f, tempdataV,Zf1);
        if cidx+size(tempdataV,1)-1<SAMPLE_FREQ_VIE*mtimeWindow
            cplotdata(cidx:cidx+size(tempdataV,1)-1,:)=tempdata1;
            cidx=cidx+size(tempdataV,1);
        else
            cplotdata(cidx:end,:)=tempdata1(end-(size(cplotdata,1)-cidx):end,:);
            cidx=1;
            cbaseline=nanmean(cplotdata);
        end
    end

    plot([1:SAMPLE_FREQ_VIE*mtimeWindow]/SAMPLE_FREQ_VIE,cplotdata-cbaseline,'LineWidth',1);
    ha1 = gca;ha1.GridColor=[1 1 1];
    set(gca,'Color','k')
    h_yaxis = ha1.YAxis; % 両 Y 軸の NumericRulerオブジェクト(2x1)を取得
    h_yaxis.Color = 'w'; % 軸の色を黒に変更
    h_yaxis.Label.Color = [1 1 1]; %  軸ラベルの色変更
    h_xaxis = ha1.XAxis; % 両 Y 軸の NumericRulerオブジェクト(2x1)を取得
    h_xaxis.Color = 'w'; % 軸の色を黒に変更
    h_xaxis.Label.Color = [1 1 1]; %  軸ラベルの色変更
    set(gca,'Color','k')
    xlim([0 4])
    title(['EEG (' num2str(round(GetSecs-Recstart,2)) 's)'],'Color' ,'w')
    xlabel('time (s)')
    ylabel('uV')
    lgd=legend({'L' 'R' 'diff'});
    lgd.TextColor=[1 1 1];
    yline(0,'w--');
    ylim([-75 75]);

    WaitSecs(0.5);%2Hzでサンプリング

    %% CalcAlpha
    %% bandpass % get power
    cdata=alldataV(end-(SAMPLE_FREQ_VIE*timeWindow)+1:end,:);
    y = bandpass(cdata,[minfreq maxfreq],SAMPLE_FREQ_VIE) ;
    y2 = hilbert(y);
    env = abs(y2);
    z=(env-mu)./std;
    env(abs(z)>3)=NaN;
    M = movmean(env,SAMPLE_FREQ_VIE/2,'omitnan');
    Mz=(M-Mmu)./Mstd;
    cAlphaZ=mean(nanmean(Mz));
    decodedstate=[ decodedstate ;cAlphaZ];
    y=centerY+(((rectContoursize(2)/2)*(cAlphaZ/MaxZ)));%Alphaを下げたときバーが上がるように　Zscorega高いほうがバーが下
    %% flip
    DrawFormattedText(w,'0',centerX-rectContoursize(1)/2-40,'center', [255 255 255]); %
    if y < MarkerTop
        y= MarkerTop;
    elseif y > MarkerBottom
        y=MarkerBottom;
    end
    if y >centerY % カーソルが下段
        Screen('FillRect', w, [255 0 0], [centerX-rectContoursize(1)/2 centerY centerX+rectContoursize(1)/2 y]);
    else% カーソルが上段
        Screen('FillRect', w, [255 0 0], [centerX-rectContoursize(1)/2 y centerX+rectContoursize(1)/2 centerY]);
    end
    Screen('FrameRect', w ,[255 255 255] ,[centerX-rectContoursize(1)/2 MarkerTop centerX+rectContoursize(1)/2 MarkerBottom],2);
    Screen('DrawLines', w, [centerX-rectContoursize(1)/2 centerX+rectContoursize(1)/2 ; centerY centerY], 2,[255 255 255]);

    DrawFormattedText(w,double(['計測中' num2str(round(GetSecs-Recstart)) 'sec']), 'center', 50,  WhiteIndex(w));
    Screen('Flip', w); %

    [ keyIsDown, keyTime, keyCode ] = KbCheck;
    if keyIsDown
        if keyCode(KbName('ESCAPE'))
            EndFlag=1;
            break; % while 文を抜けます。
        end
    end

end

DrawFormattedText(w, double(['トレーニング終了']), 'center', 'center');
Screen('Flip', w);
PsychPortAudio('FillBuffer', pahandle, S );%
PsychPortAudio('Start', pahandle, 1);
WaitSecs(3);

save([savefilename '_data.mat'],'alldataV','SAMPLE_FREQ_VIE','subName','decodedstate');
close all
ShowCursor();
ListenChar(0);
Screen('CloseAll');