%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% 202112 NTTe-motor sports Experiment Program by T.Ibaraki @NTTDIOMC,Inc.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
clear
%% パスのセッティング
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% defaultpath='D:\HONDA\201912HG';
defaultpath=pwd;
mkdir([defaultpath '\data'])
addpath(defaultpath)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%% EXPERIMENT PARAMETERS ここにある変数をいじると実験のプロトコルを調整できる。
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
trialsPerBlock=40;%
nblock =2;
TimeLimit=2.5;%time limit of 1 trial %
Cond={'Cong' 'InCong'};
stimlist={'あか' 'みどり' 'あお' 'きいろ'};
Key=[86 66 78 77];%KbName('V') B N M;
%% 色の設定
wordcolorlist=  [1 0 0;0 1 0;0 0 1;1 1 0]*255;% r g b y

% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% subject parameter
% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
TaskName='Stroop';
subName =strtrim(input('subject name is ', 's')); % 被験者名の入力
savefilename=[defaultpath '\data\sub_' subName '_' datestr(now,30) '_' TaskName];% '_session' SessionNo]

if exist(savefilename) > 0
    disp('Already exist shut down ')
    return;
else
    %     mkdir(savefilename);
    data = cell(length(nblock*trialsPerBlock)+1, 8);
    data{1, 1} = 'block';
    data{1, 2} = 'trial';
    data{1, 3} = 'condition1(Cong/InCong)';
    data{1, 4} = 'ColorWord';
    data{1, 5} = 'Color';
    data{1, 6} = 'Response';
    data{1, 7} = 'Result';
    data{1, 8} = 'RT';
    save([savefilename 'data.mat'], 'data');
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% START EXPERIMENT
try
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %% 実験初期設定
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    KbName('UnifyKeyNames');% "ESC"で途中終了するため
    myKeyCheck; % 外部ファイル
    Screen('Preference', 'SkipSyncTests', 1);%　これを入れないと時々エラーが出る
    Screen('Preference', 'TextRenderer', 1);
    Screen('Preference', 'TextAntiAliasing', 1);
    Screen('Preference', 'TextAlphaBlending', 0);
    AssertOpenGL;
    ListenChar(2)
    KbReleaseWait;
    
    % setting
    windowsize=[];
    screenid = max(Screen('Screens'));
    %          [w, rect] = Screen('OpenWindow', 2, 125, windowsize);
    [w, rect] = Screen('OpenWindow', screenid, 125, windowsize);
    %     [w, rect] = Screen('OpenWindow', screenid, 0, [10 30 450 300]); %test用
    [centerX, centerY] = RectCenter(rect);%画面の中央の座標
    HideCursor();
    
    Screen('TextFont',w, 'Courier New');
    Screen('TextSize',w, 25);
    Screen('TextStyle', w, 0);
    Screen('BlendFunction', w, 'GL_SRC_ALPHA', 'GL_ONE_MINUS_SRC_ALPHA');
    Screen('TextFont', w, '-:lang=ja');
    
    
    %%  instruction
    EXstart=GetSecs;
    EndFlag=0;
    TrialNo=1;
    for b=1:nblock
        %% ブロック内の実験条件のアサイン
        CondMat=[repmat(1,1,trialsPerBlock/2) repmat(2,1,trialsPerBlock/2)];%1cong 2incong
        rng('shuffle')
        CondMat=[CondMat(randperm(trialsPerBlock))];% ;
    
        DrawFormattedText(w,double('提示された文字の”色”を2.5秒以内に答えてください\n\n\n\nあかV   みどりB   あおN   きいろM\n\n\n\nPress SPACE KEY'), 'center', 'center',  WhiteIndex(w));
        Screen('Flip', w);%上で指定された情報を画面に表示
        WaitSecs(1);%     KbWait;%何かキーを押されるのを待つ
        KbWait;
        
        for t=1:trialsPerBlock
            C=CondMat(1,t);%実験条件
            TrialEndFlag=0;
            StopedTime=[];duration=[];trialEndTime=[];
            
            %% fixation
            DrawFormattedText(w,double('+'), 'center', 'center',  WhiteIndex(w));
            Screen('Flip', w);%上で指定された情報を画面に表示
            WaitSecs(0.5)
            
            %% Stim on
            cword=randi(4);
            stimword=stimlist{cword};
            if C==1%cong
                ccolor=wordcolorlist(cword,:);
                ccoloridx=cword;
            elseif C==2
                ccolorlist=find(not(ismember(1:4,cword)));
                ccoloridx=ccolorlist(randi(3));
                ccolor= wordcolorlist(ccoloridx,:);
            end
            
            DrawFormattedText(w,double(stimword), 'center', 'center',  ccolor);
            DrawFormattedText(w,double('あかV      みどりB      あおN      きいろM'), 'center', rect(4)*0.75,  WhiteIndex(w));
            trialStartTime=Screen('Flip', w);%上で指定された情報を画面に表示
            
            while 1
                ctime=GetSecs-trialStartTime;
                [ keyIsDown, keyTime, keyCode ] = KbCheck;
                if keyIsDown
                    cKeyPress=find(keyCode(Key));
                    RT=GetSecs-trialStartTime;
                    if keyCode(KbName('ESCAPE'))
                        EndFlag=1;
                    elseif isempty(cKeyPress)
                        cResult='Key Error';
                        DrawFormattedText(w,double('Incorect Key!!'), 'center','center',  WhiteIndex(w));
                        cAnswer='Incorect Key!!';
                        trialStartTime=Screen('Flip', w);%上で指定された情報を画面に表示
                        WaitSecs(2);
                    elseif ccoloridx==cKeyPress
                        cAnswer=stimlist{cKeyPress};
                        cResult='Correct';
                    elseif ccoloridx~=cKeyPress
                        cAnswer=stimlist{cKeyPress};
                        cResult='InCorrect';
                    end
                    break
                end
                
                if ctime>TimeLimit % time over
                    cAnswer='TimeOver';
                    cResult='TimeOver';
                    RT=NaN;
                    break
                end
            end
            
            DrawFormattedText(w,double('+'), 'center', 'center',  WhiteIndex(w));
            Screen('Flip', w);
            while 1
                ctime=GetSecs-trialStartTime;
                if ctime>TimeLimit %
                    break
                end
            end
            if EndFlag
                break
            end
            
            %% save data
            data{TrialNo+1,1} = b;
            data{TrialNo+1,2} = t;
            data{TrialNo+1,3} = Cond{C};
            data{TrialNo+1,4} = stimword;
            data{TrialNo+1,5} = stimlist{ccoloridx};
            data{TrialNo+1,6} = cAnswer;
            data{TrialNo+1,7} = cResult;
            data{TrialNo+1,8} = RT;
            
            TrialNo=TrialNo+1;%次のトライアルへ
            
        end
        if EndFlag
            break
        end
        
    end
    save([savefilename 'data.mat'], 'data','subName');
    writecell(data,[savefilename 'data.xlsx'],'AutoFitWidth',1)
    
    DrawFormattedText(w, double(['実験終了！\n\n Press Any Key' ]), 'center', 'center');
    Screen('Flip', w);
    WaitSecs(2)
    KbWait;
    
    ShowCursor()
    ListenChar(0)
    %     xlswrite([savefilename 'log.xlsx'],data)
    Screen('CloseAll');
    
    %% Stat
    [MU pred GRPname No] = grpstats(cell2mat(data(2:end,8)).*1000,{data(2:end,3)},{'mean' 'meanci' 'gname' 'numel'},'Alpha',0.05);
    [B,I]=sort(strcat(GRPname(:,1)));
    GRPname=GRPname(I,:);
    MU=MU(I);pred=pred(I,:);
    
    h=figure
    subplot(2,1,1)
    bar(diag([MU]),'stack','LineWidth',2);hold on
    
    e=errorbar([1:length(MU)],[MU],[pred(:,2)-MU],'k','LineWidth',2,'CapSize',10);hold on
    e.Color = [0 0 0]; % make the errorbars black
    e.LineStyle = 'none';
    e.YNegativeDelta  =zeros(0,length(MU),1);
    xticklabels(strcat(GRPname(:,1)))
    
    ylabel('RT(msec)')
    set(gca, 'FontSize', 12)
    set(gca, 'LineWidth', 2)
    box off
    
    congdaata=cell2mat(data(find(strcmp(data(:,3),'Cong')),8));
    incongdaata=cell2mat(data(find(strcmp(data(:,3),'InCong')),8));
    [~,p,ci,stats] = ttest(congdaata,incongdaata)
    
    ctitle=['sub=' subName ' RT(msec) StroopScore(Incong/Cong)' num2str(MU(2)/MU(1))  'Effect t(' num2str(stats.df) ') = ' num2str(round(stats.tstat,2)) ', P='  num2str(p,4)]
    title([ctitle] , 'FontSize', 10)
    
    %#2 SuccessRate
    subplot(2,1,2)
    congidx=find(strcmp(data(:,3),'Cong'));
    incongidx=find(strcmp(data(:,3),'InCong'));
    
    MU=[length(find(strcmp('Correct',data(congidx,7))))./length(congidx) length(find(strcmp('Correct',data(incongidx,7))))./length(incongidx)];
    
    bar(diag([MU]),'stack','LineWidth',2);hold on
    xticklabels(strcat(GRPname(:,1)))
    ylabel('Success Rate')
    set(gca, 'FontSize', 12)
    set(gca, 'LineWidth', 2)
    box off
    
    ctitle=['sub=' subName ' Success Rate(Cong=' num2str(MU(1)) ' Incong=' num2str(MU(2)) ')' ];
    title([ctitle] , 'FontSize', 10)
    
    h.Position=[1.0000   41.0000  676.6667  748.8000];
    print('-r0','-djpeg',[savefilename 'fig.jpg']);
    
    
    
catch
    %% ERROR PROCESS.
    %     xlswrite([savefilename 'log.xlsx'],data)
    %% Close the audio device:
    %     PsychPortAudio('Close', pahandle);
    ShowCursor()
    sca;
    psychrethrow(psychlasterror);
    ListenChar(0)
end