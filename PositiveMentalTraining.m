clear;close all;
defaultpath=pwd;

subName =strtrim( input('subject name is ', 's')); % 被験者名の入力
savefilename=[defaultpath '\data\' subName  datestr(now,30)  ];

addpath([defaultpath '\function']);
outputpath=[defaultpath '\' 'output'];mkdir(outputpath);

timeWindow=4; %Decoder time windowsca
decint=4 ;%EEG analysis interval
FreqWindow=[4:0.25:40];
KbName('UnifyKeyNames')

%% VIE ZONE EEG setting
mkdir([defaultpath '\EEGdata']);
filename=[defaultpath '\VieOutput\' 'VieRawData.csv' ];%             filename=[filelist(1).folder '\' filelist(1).name ];%VieRawData.csv
opts = detectImportOptions(filename);
opts.SelectedVariableNames = [2 3];

SAMPLE_FREQ=600;
chLabel={'L' 'R' 'Diff'};
plotFreq=[4:20];%Analysis EEG Freq Rage

a =SAMPLE_FREQ*timeWindow;
f = (0:a-1)*(SAMPLE_FREQ/a);%FFT freq
freqVIE=f;
plotFreqidx=find(ismember(freqVIE,plotFreq));

%% Filter Setting
[B1f,A1f] = butter(4,[3/(SAMPLE_FREQ/2) 40/(SAMPLE_FREQ/2)]);% 3~40Hzバタワースフィルタ設計
Zf1=[];

%% window seting
ScreenDevices = java.awt.GraphicsEnvironment.getLocalGraphicsEnvironment().getScreenDevices();
MainScreen = java.awt.GraphicsEnvironment.getLocalGraphicsEnvironment().getDefaultScreenDevice().getScreen()+1;
MainBounds = ScreenDevices(MainScreen).getDefaultConfiguration().getBounds();
MonitorPositions = zeros(numel(ScreenDevices),4);
for n = 1:numel(ScreenDevices)
    Bounds = ScreenDevices(n).getDefaultConfiguration().getBounds();
    MonitorPositions(n,:) = [Bounds.getLocation().getX() + 1,-Bounds.getLocation().getY() + 1 - Bounds.getHeight() + MainBounds.getHeight(),Bounds.getWidth(),Bounds.getHeight()];
end
windowsize=get(0,'MonitorPositions');
h=figure('Position',[windowsize(1,1) windowsize(1,2) windowsize(1,3) 240]);%alwaysontop(h)
h.MenuBar='none';h.ToolBar='none';

%% EEG Monitor Window
cplotdata=repmat(0,SAMPLE_FREQ*timeWindow,3);
cidx=1;
cbaseline=[0 0 0];

%% feedback用の窓を作る→これでマウスによる怒りも記録していく

fig_nft = figure('Position',[windowsize(1,1) 280 windowsize(1,3) windowsize(1,4)-280]);
fig_nft.MenuBar='none';fig_nft.ToolBar='none';
scsize=get(0, 'screensize');
hold on;
title('Anger Recording','FontSize',16);
graycol = [120,120,120]/255;
rect = rectangle('Position',[0,0,20,20],'FaceColor',graycol);
angertext = text(10,1,'Anger','FontSize',12,'HorizontalAlignment','center','Color','white'); % 実験時にはVisibleをoffにしておく・テスト時にはonにしておけば脳波による怒り度合いを見られる
timetext = text(10,19,'Time : 0 [s]','FontSize',12,'HorizontalAlignment','center','Color','white'); % 計測開始からの時間を表示
maintext = text(10,18,'自分の気分をマウスを使って入力して下さい','FontSize',16,'HorizontalAlignment','center','Color','white');
axis off
RedBox = rectangle('Position',[9.75,10,0.5,0],'FaceColor',[1,0,0],'EdgeColor','none');
innerRect = rectangle('Position',[9.75,5,0.5,10],'FaceColor','none','EdgeColor','white','LineWidth',2); % yの上下端5-15
centerLine = plot([9.75,10.25],[10,10],'LineWidth',2,'Color','white');
zeroText = text(9.25,10,'0','Color','white','FontSize',16);
TextAngry = text(10,16,'とてもポジティブな気分','FontSize',16,'HorizontalAlignment','center','Color','white');
TextRelax = text(10,4,'とてもネガティブな気分','FontSize',16,'HorizontalAlignment','center','Color','white');
% マウスカーソルを非表示に
set(gcf, 'Pointer', 'custom', 'PointerShapeCData', NaN(16,16));

figpos = get(fig_nft,'position'); % figureの座標→フィードバックプログラム中でも適宜取得したほうがいい（途中で全画面にしたりしても対応できる）
FigYmax = figpos(4)+figpos(2); % figureの上端y座標
FigYmin = figpos(2); % figureの下端ｙ座標
FigYlength = FigYmax-FigYmin;

Ycenter = (FigYmax + FigYmin)/2; % yの中心に設定
%
robot = java.awt.Robot;
for i=1:10
    robot.mouseMove(scsize(3)/2,Ycenter-110);%微妙にずれるのを調整
end
% SetMouse(scsize(3)/2,Ycenter);
% [~,y1]=GetMouse;
% y1-Ycenter


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% ここから計測・フィードバック
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%store EEG data setting
opts.DataLines=[2 inf];
craw=size(readmatrix(filename,opts).*18.3./64,1);% Read Start row
alldata=[];
data2=[];
%% EEG Monitor Window
cplotdata=repmat(0,SAMPLE_FREQ*timeWindow,3);
cidx=1;
cbaseline=[0 0 0];

%% start
StartTime=GetSecs;

tsstart=tic;
textswitch=30;
condmat=repmat([1 2],1,20);condtext={'可能な限り最低の未来の自分（心配事・苦悩・いら立ちなど）を想像してください' '可能な限り最高の未来の自分（強き・ワクワク・熱狂など）を想像してください'};T=1;
set(timetext,'String',['Time : ' num2str(floor(GetSecs-StartTime)) ' [s] ' condtext{condmat(T)}]);
while (1) % この内部で脳波計測→フィードバックする
    WaitSecs(0.1);%10Hzでサンプリング
    [ keyIsDown, keyTime, keyCode ] = KbCheck;
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%
    %% 表示を更新
    %%%%%%%%%%%%%%%%%%%%%%%%%%
    ctime=floor(GetSecs-StartTime);
    if textswitch < ctime
        T=T+1;
        textswitch=textswitch+30;
    end
    if condmat(T)==1
        set(timetext,'String',['Time : ' num2str(floor(GetSecs-StartTime)) ' [s] ' condtext{condmat(T)}],'Color','white');
    else
        set(timetext,'String',['Time : ' num2str(floor(GetSecs-StartTime)) ' [s] ' condtext{condmat(T)}],'Color','red');
    end
    figure(fig_nft)
    figpos = get(fig_nft,'position'); % figureの座標→フィードバックプログラム中でも適宜取得したほうがいい（途中で全画面にしたりしても対応できる）
    FigYmax = figpos(4)+figpos(2); % figureの上端y座標
    FigYmin = figpos(2); % figureの下端ｙ座標
    FigYlength = FigYmax-FigYmin;
    
    Ycenter = (FigYmax + FigYmin)/2; % yの中心に設定
    Ymax = Ycenter + 0.7 * FigYlength/2; % ｙの可動域上端
    Ymin = Ycenter - 0.7 * FigYlength/2; % 下端
    Ylength = Ymax-Ymin;
    
    xy = get(0,'PointerLocation'); % これと、軸の上下端のｙ座標がわかれば割り出せる。
    yy = xy(2);
    if yy > Ymax
        yy = Ymax;
    elseif yy < Ymin
        yy = Ymin;
    end
    
    if yy > Ycenter % 中心より上の時
        set(RedBox,'Position',[9.75,10,0.5,5*((yy-Ycenter)/(Ymax-Ycenter))]);
    else
        set(RedBox,'Position',[9.75,10-5*((yy-Ycenter)/(Ymin-Ycenter)),0.5,5*((yy-Ycenter)/(Ymin-Ycenter))]);
    end
    
    drawnow;
    PercentAns=(yy-Ycenter)./(Ymax-Ycenter).*100;
    
    %% EEG Store
    opts.DataLines=[craw+1 inf];
    tempdata=readmatrix(filename,opts).*18.3./64;
    if ~isempty(tempdata)
        tempdata=[tempdata tempdata(:,2)-tempdata(:,1)];
        alldata=[alldata;tempdata];
        craw=craw+size(tempdata,1);
    end
    
    [tempdata1,Zf1] = filter(B1f, A1f, tempdata,Zf1);
    if cidx+size(tempdata,1)-1<SAMPLE_FREQ*4
        cplotdata(cidx:cidx+size(tempdata,1)-1,:)=tempdata1;
        cidx=cidx+size(tempdata,1);
    else
        cplotdata(cidx:end,:)=tempdata1(end-(size(cplotdata,1)-cidx):end,:);
        cidx=1;
        cbaseline=nanmean(cplotdata);
    end
    figure(h)
    plot([1:SAMPLE_FREQ*4]/SAMPLE_FREQ,cplotdata-cbaseline);
    xlim([0 4])
    title(['EEG (' num2str(round(toc(tsstart),2)) 's)'])
    xlabel('time (s)')
    ylabel('uV')
    legend({'L' 'R' 'diff'})
    yline(0,'--')
    ylim([-150 150])
    
    %% Annotation data
    data2= [data2;repmat([PercentAns GetSecs-StartTime],size(tempdata,1),1)];% 1PercentAns 2TimeStamp
    
    %% ESACPEで終了
    if keyIsDown
        if keyCode(KbName('ESCAPE'))
            break; % while 文を抜けます。
        end
    end
end

save(savefilename,'alldata','data2','SAMPLE_FREQ','subName','chLabel')
WaitSecs(2)
ListenChar(0)

figure
plot(data2(:,2),data2(:,1))
xlabel('time(sec)')
ylabel('Anger')
