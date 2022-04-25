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
nblock =3;
TargetDuration=0.25;%time limit of 1 trial %sec
ITI=0.9;
SPACEKey=32;%KbName('SPACE');

stimlist={'red' 'yellow' 'black'};
Key=[86 66 78 77];%KbName('V') B N M;
%% 色の設定
wordcolorlist=  [1 0 0;1 1 0;0 0 0]*255;% r y k

% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% subject parameter
% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
TaskName='GoNoGo';
subName =strtrim(input('subject name is ', 's')); % 被験者名の入力
% subName = input('subject name is ', 's'); % 被験者名の入力
% SessionNo = input('SessionNo is ', 's'); % 被験者名の入力
% savefilename=[defaultpath '\data\sub' subName];% '_session' SessionNo]
savefilename=[defaultpath '\data\sub_' subName '_' datestr(now,30) '_' TaskName];% '_session' SessionNo]

if exist(savefilename) > 0
    disp('Already exist shut down ')
    return;
else
    %     mkdir(savefilename);
    data = cell(length(nblock*trialsPerBlock)+1, 8);
    data{1, 1} = 'block';
    data{1, 2} = 'trial';
    data{1, 3} = 'condition1(Target/NoTarget)';
    data{1, 4} = 'ColorL';
    data{1, 5} = 'ColorR';
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
    if length( Screen('Screens'))==3
        screenid=1;
    end
    [w, rect] = Screen('OpenWindow', screenid, 125, windowsize);
    %     [w, rect] = Screen('OpenWindow', screenid, 0, [10 30 450 300]); %test用
    [centerX, centerY] = RectCenter(rect);%画面の中央の座標
    HideCursor();
    
    Screen('TextFont',w, 'Courier New');
    Screen('TextSize',w, 55);
    Screen('TextStyle', w, 0);
    Screen('BlendFunction', w, 'GL_SRC_ALPHA', 'GL_ONE_MINUS_SRC_ALPHA');
    Screen('TextFont', w, '-:lang=ja');
    
    
    %%  instruction
    
    EXstart=GetSecs;
    EndFlag=0;
    TrialNo=1;
    for b=1:nblock
        DrawFormattedText(w,double('提示される円の色の組み合わせが\n\n\n\n黄色と赤\n\n\n\nの時"以外"にスペースキーを押してください\n\n\nPress SPACE KEY'), 'center', 'center',  WhiteIndex(w));
        Screen('Flip', w);%上で指定された情報を画面に表示
        WaitSecs(0.5);%     KbWait;%何かキーを押されるのを待つ
        KbWait;
        
        %% fixation
        DrawFormattedText(w,double('+'), 'center', 'center',  WhiteIndex(w));
        Screen('Flip', w);%上で指定された情報を画面に表示
        WaitSecs(ITI)
        for t=1:trialsPerBlock
            CL=randperm(length(stimlist),1);
            CR=randperm(length(stimlist),1);
            if CL==1 && CR==2
                cCond='NonTarget';
            elseif CL==2 && CR==1
                cCond='NonTarget';
            else
                cCond='Target';
            end
            
            ResponseFlag=0;
            StopedTime=[];duration=[];trialEndTime=[];
            
            DrawFormattedText(w,double('●'), centerX-100, 'center',  wordcolorlist(CL,:));
            DrawFormattedText(w,double('●'), centerX+100, 'center',  wordcolorlist(CR,:));
            trialStartTime=Screen('Flip', w);%上で指定された情報を画面に表示
            
            while 1
                ctime=GetSecs-trialStartTime;
                [ keyIsDown, keyTime, keyCode ] = KbCheck;
                if keyIsDown
                    cKeyPress=find(keyCode(Key));
                    RT=GetSecs-trialStartTime;
                    if keyCode(KbName('ESCAPE'))
                        EndFlag=1;
                        break
                    else
                        cAnswer='Press';
                        ResponseFlag=1;
                        if strcmp(cCond,'Target')
                            cResult='Correct';
                        else
                            cResult='Miss';
                        end
                    end
                end
                if ctime> TargetDuration
                    break
                end
            end
            
            %%ITI
            DrawFormattedText(w,double('+'), 'center', 'center',  WhiteIndex(w));
            ITIStartTime=Screen('Flip', w);%上で指定された情報を画面に表示
            
            while 1
                ctime=GetSecs-ITIStartTime;
                DrawFormattedText(w,double('+'), 'center', 'center',  WhiteIndex(w));
                Screen('Flip', w);%上で指定された情報を画面に表示
                
                [ keyIsDown, keyTime, keyCode ] = KbCheck;
                
                if keyIsDown
                    RT=GetSecs-trialStartTime;
                    if keyCode(SPACEKey) && ~ResponseFlag
                        cAnswer='Press';
                        ResponseFlag=1;
                        if strcmp(cCond,'Target')
                            cResult='Correct';
                        else
                            cResult='Miss';
                        end
                    elseif keyCode(KbName('ESCAPE'))
                        EndFlag=1;
                    end
                end
                
                if ctime>ITI
                    if ~ResponseFlag
                        cAnswer='NotPress';
                        RT=NaN;
                        
                        if strcmp(cCond,'Target')
                            cResult='Miss';
                        else
                            cResult='Correct';
                        end
                    end
                    break
                end
            end
            
            if EndFlag
                break
            end
            
            %% save data
            data{TrialNo+1,1} = b;
            data{TrialNo+1,2} = t;
            data{TrialNo+1,3} = cCond;
            data{TrialNo+1,4} = stimlist{CL};
            data{TrialNo+1,5} = stimlist{CR};
            data{TrialNo+1,6} = cAnswer;
            data{TrialNo+1,7} = cResult;
            data{TrialNo+1,8} = RT;
            
            TrialNo=TrialNo+1;%次のトライアルへ
            
        end
        if EndFlag
            break
        end
        
    end
    writecell(data,[savefilename 'data.xlsx'],'AutoFitWidth',1)
    
    DrawFormattedText(w, double(['実験終了！\n\n Press Any Key' ]), 'center', 'center');
    Screen('Flip', w);
    WaitSecs(0.5)
    KbWait;
    
    ShowCursor()
    ListenChar(0)
    %     xlswrite([savefilename 'log.xlsx'],data)
    Screen('CloseAll');
    %
    %     %% Stat
    data2=data(2:end,:);
    TargetFlag=find(strcmp(data2(:,3),'Target'));
    NoNTargetFlag=find(strcmp(data2(:,3),'NonTarget'));
    hr=sum(strcmp(data2(TargetFlag,7),'Correct'))./ length(TargetFlag)
    fA = sum(strcmp(data2(NoNTargetFlag,7),'Miss'))./ length(NoNTargetFlag);
    if hr==1;hr=0.99999;end;
    if fA==0;fA=0.00001;end;
    if fA==1;fA=0.99999;end;
    
    dp = norminv(hr)-norminv(fA);
    c = -0.5*(norminv(hr)+ norminv(fA));
    save([savefilename 'data.mat'], 'data','hr','fA','dp','c','subName');
    
    
    h=figure
    subplot(2,1,1)
    bar(diag([hr fA]),'stack','LineWidth',2);hold on
    xticklabels({'HitRate' 'False Alarm'})
    %     ylabel('Success Rate')
    box off
    ctitle=['sub=' subName ' HitRate=' num2str(hr) ' FA=' num2str(fA) 'dprime=' num2str(dp)];
    title([ctitle] , 'FontSize', 10)
    %     %#2 SuccessRate
    subplot(2,1,2)
    bar(nanmean(cell2mat(data2(:,8))),'stack','LineWidth',2);hold on
    box off
    
    ctitle=['sub=' subName ' RT='  num2str(nanmean(cell2mat(data2(:,8)))) 'Sec'];
    title([ctitle] , 'FontSize', 10)
    ylabel('RT(Sec)')
    h.Position=[1.0000   41.0000  676.6667  748.8000];
    print('-r0','-djpeg',[savefilename '_fig.jpg']);
    %
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