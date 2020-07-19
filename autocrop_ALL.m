close all;
clear all;
clc;

source_path = uigetdir(pwd,'Choose source directory');
dest_path = uigetdir(pwd,'Choose destination directory');

input_filename = dir(source_path);
input_filename = input_filename(3:end,1);

if mod(size(input_filename,1),3)~=0
    warningMessage = sprintf('Error: Missing channels. Check that all images contain 3 channels');
	uiwait(warndlg(warningMessage));
    fprintf(1, 'Finished running autocrop.m.\n');
	return;
end

groupings = strings(size(input_filename,1)/3,3);
count = 1;

for i = 1 : size(input_filename,1)
    if contains(string(input_filename(i).name(1:3)),"C1-")
        groupings(count,1)=string(input_filename(i).name);
        groupings(count,2)=strcat("C2",string(input_filename(i).name(3:end)));
        groupings(count,3)=strcat("C3",string(input_filename(i).name(3:end)));
        count = count+1;
    end
end

if count~=size(input_filename,1)/3+1
    message = sprintf('Error: Directory contains non-image files. Continue anyway?');
	reply = questdlg(message, 'Warning', 'Yes', 'No', 'Yes');
	if strcmpi(reply, 'No') || strcmpi(reply,'')
		% User said No, so exit.
		return;
	end
end

for i = 1 : count-1
    filename_c1 = [source_path,'\',char(groupings(i,1))];
    filename_c2 = [source_path,'\',char(groupings(i,2))];
    filename_c3 = [source_path,'\',char(groupings(i,3))];
    info = imfinfo(filename_c1);
    numFramesStr = regexp(info(1).ImageDescription, 'images=(\d*)', 'tokens');
    numFrames = str2double(numFramesStr{1}{1});
    
    
    for j = 1 : numFrames
        C1=imread(filename_c1,j);
        %O1=i_adjust(C1);
        hist=C1;
        hist(hist>0)=1;
        for m = 2 : size(hist,1)
            for n = 1 : size(hist,2)
                if hist(m,n)
                    hist(m,n)=hist(m,n)+hist(m-1,n);
                end
            end
        end
        if j==1
            L_border=1;
            R_border=size(hist,2);
            T_border=1;
            B_border=size(hist,1); 
        end
        maxArea=-inf;
        for m = 1 : size(hist,1)
            [x,width,height,area] = findLargestRectangle(hist(m,:));
            if area>maxArea
                maxArea=area;
                xPos=x;
                maxWidth=width;
                maxHeight=height;
                yPos=m-height+1;
            end
        end
        L=xPos;
        R=xPos+maxWidth-1;
        T=yPos;
        B=yPos+maxHeight-1;
        if L > L_border
            L_border=L;
        end
        if R < R_border
            R_border=R;
        end
        if T > T_border
            T_border=T;
        end
        if B < B_border
            B_border=B;
        end
    end
    for j = 1 : numFrames
        C1=imread(filename_c1,j);
        C2=imread(filename_c2,j);
        C3=imread(filename_c3,j);
        
        C1_cropped=C1(T_border:B_border,L_border:R_border);
        C2_cropped=C2(T_border:B_border,L_border:R_border);
        C3_cropped=C3(T_border:B_border,L_border:R_border);
        
        if ~isempty(C1_cropped)
            if j == 1
                imwrite(C1_cropped, [dest_path,'\',char(groupings(i,1))])
                imwrite(C2_cropped, [dest_path,'\',char(groupings(i,2))])
                imwrite(C3_cropped, [dest_path,'\',char(groupings(i,3))])
            else
                imwrite(C1_cropped, [dest_path,'\',char(groupings(i,1))], 'writemode', 'append')
                imwrite(C2_cropped, [dest_path,'\',char(groupings(i,2))], 'writemode', 'append')
                imwrite(C3_cropped, [dest_path,'\',char(groupings(i,3))], 'writemode', 'append')
            end
        end
    end
    sprintf('%d / %d',i,count-1)
end

function [x,width,height,area] = findLargestRectangle(hist)
    h=0;
    tempI=0;
    maxSize=-inf;
    hStack=[];
    iStack=[];
    x=0;
    
    for i = 1 : 1 : length(hist)
        h=hist(i);
        if isempty(hStack) || h>hStack(end)
            hStack(end+1)=h;
            iStack(end+1)=i;
        elseif h<hStack(end)
            while ~isempty(hStack) && h<hStack(end)
                tempH=hStack(end);
                hStack=hStack(1:end-1);
                tempI=iStack(end);
                iStack=iStack(1:end-1);
                tempSize=tempH*(i-tempI);
                if tempSize>maxSize
                    maxSize=tempSize;
                    x=tempI;
                    width=(i-tempI);
                    height=tempH;
                    area=tempSize;
                end
            end
            hStack(end+1)=h;
            iStack(end+1)=tempI;
        end
    end
    i=i+1;
    while(~isempty(hStack))
        tempH=hStack(end);
        hStack=hStack(1:end-1);
        tempI=iStack(end);
        iStack=iStack(1:end-1);
        tempSize=tempH*(i-tempI);
        if tempSize>maxSize
            maxSize=tempSize;
            x=tempI;
            width=(i-tempI);
            height=tempH;
            area=tempSize;
        end
    end
        
end