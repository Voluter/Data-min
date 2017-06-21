function plotECEdatas(shot,time1,time2,A,chans,Frequencys)
%默认绘制23道信号的剖面图
%必需参数shot,time1,time2,A
%可选参数channels,Frequencys
%channels绘制图形的通道号，传入数据为数组形式，如[1:23],[1:15,17:23];
%标定系数A和通道号chans必须一一对应
%Frequencys每道信号的频率，当ECE本阵频率没有改变时，不需要填

Fre=[3.5 5.5 7.5 9.5 11.5 13.5 15.5 17.5];
LoF=[91+Fre,107+Fre,77+Fre];%每道的频率

channels=[1:23];%通道号

if nargin==6
    LoF=Frequencys;
    channels=chans;
elseif nargin==5
    channels=chans;
elseif nargin==4
else
    error('plotECEdatas:不合法的输入');
end

%读取数据
[ECEdatas,t]=get_ece_datas(shot,channels);

%去掉底噪
tt_index=find(t<0);
for i=1:length(channels)
    ECEdatas{1,channels(i)}=ECEdatas{1,channels(i)}-mean(ECEdatas{1,channels(i)}(tt_index));
end

%获得time时刻每道的值
if time1<1%当输入的时间单位为s时，将其转换为ms
    time1=time1*1000;
    time2=time2*1000;
end

t_index=find(t>time1 & t<time2);%获取索引

ECEvalues=[];
for i=1:length(channels)
    ECEvalues(i)=abs(mean(ECEdatas{1,channels(i)}(t_index)))/A(i);%实际相对值
end

%计算ECE位置
[B,B_t]=getdata('\bt',shot);
B_t_index=find(B_t>time1 & B_t<time2);
B0=mean(B(B_t_index)); %获取B0的值

X1=B0*56./LoF*105-105;%计算位置

 %将值稍作调整，，因为ECE通道不是按照顺序安装的，将最终值存放在X,Y中
%  X=[X1(17:23) X1(1:16)];
%  Y=[ECEvalues(17:23) ECEvalues(1:16)];
%对数据重新排序
[X,Y]=sortdatas(X1,ECEvalues,channels);
 
plot(X,Y,'o',X,Y,'.-','LineWidth',2);
hold on;
title(['shot=',num2str(shot),', B=',num2str(B0)]);
xlabel('r/cm','Fontname', 'Times New Roman','FontSize',12);
ylabel('a.u','Fontname', 'Times New Roman','FontSize',12);
set(gca, 'Fontname', 'Times New Roman','FontSize',12);
end

function [datas,t]=get_ece_datas(shot,chans)
%使用二维数组存放数据
%如果获取第15道的ECE信号，使用datas{1,15}即可
%返回时间单位为ms

if nargin==2
    channels=chans;
elseif nargin==1
    channels=(1:24);
else
    error('get_ece_datas:无效输入');
end
datas=cell(1,24);
mdsopen('115.156.252.12::jtext',shot);
t=mdsvalue('dim_of(\ece_ch01_raw)-0.2',shot)*1000;

for i=1:length(channels)
    if channels(i)<10
    datas{1,channels(i)}=mdsvalue(['\ece_ch0',num2str(channels(i)),'_raw'],shot);
    else
        datas{1,channels(i)}=mdsvalue(['\ece_ch',num2str(channels(i)),'_raw'],shot);
    end
end

end

function [a,t]=getdata(channel,shot)
%wroten in 2017-6-7
%返回时间ms
mdsopen('115.156.252.12::jtext',shot);
a=mdsvalue(channel,shot);
t=mdsvalue(['dim_of(',channel,')'],shot)*1000;
end

function [x,Y]=sortdatas(X1,ECEvalues,channels)
%获取顺序索引
%提取对应的位置
x=[];
for i=1:length(channels)
    x(i)=X1(channels(i));
end
Y=ECEvalues;
%根据x的位置对ECEvalues进行排序，插入排序
for i=2:length(x)
   if x(i)<x(i-1)
       j=i-1;
       k=x(i);
       my=Y(i);
       x(i)=x(i-1);%每移动一次x的值，相应的y值也要变化，x,y一一对应
       Y(i)=Y(i-1);
       while j>0 && k<x(j)
           x(j+1)=x(j);
           Y(j+1)=Y(j);
           j=j-1;
       end
       x(j+1)=k;
       Y(j+1)=my;
   end
end
end
