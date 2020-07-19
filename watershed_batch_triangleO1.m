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
count_i = 1;

for i = 1 : size(input_filename,1)
    if contains(string(input_filename(i).name(1:3)),"C1-")
        groupings(count_i,1)=string(input_filename(i).name);
        groupings(count_i,2)=strcat("C2",string(input_filename(i).name(3:end)));
        groupings(count_i,3)=strcat("C3",string(input_filename(i).name(3:end)));
        count_i = count_i+1;
    end
end

if count_i~=size(input_filename,1)/3+1
    message = sprintf('Error: Directory contains non-image files. Continue anyway?');
	reply = questdlg(message, 'Warning', 'Yes', 'No', 'Yes');
	if strcmpi(reply, 'No') || strcmpi(reply,'')
		return;
	end
end

for i = 1 : count_i-1
    filename = [source_path,'\',char(groupings(i,1))];
    filename2 = [source_path,'\',char(groupings(i,2))];
    filename3 = [source_path,'\',char(groupings(i,3))];
    t_file = char(groupings(i,1));
    t_file = t_file(4:end-4);
    f_file = [dest_path, '\', t_file, '.fig'];
    r_file = [dest_path, '\', t_file, '_raw.xls'];
    rr_file = [dest_path, '\', t_file, '_raw_red.xls'];
    rp_file = [dest_path, '\', t_file, '_raw_pp.xls'];
    rc_file = [dest_path, '\', t_file, '_raw_cp.xls'];
    p_file = [dest_path, '\', t_file, '.png'];
    t_file = [dest_path, '\', t_file, '.txt'];
    info = imfinfo(filename);
    numFrames = numel(info);
    prev_reg=[];
    cell_area=nan(1000,numFrames);
    cell_perimeter=nan(1000,numFrames);
    cell_maj_axis=nan(1000,numFrames);
    cell_min_axis=nan(1000,numFrames);
    cell_int=nan(1000,numFrames);
    cell_int_red=nan(1000,numFrames);
    cell_int_pp=nan(1000,numFrames);
    cell_int_cp=nan(1000,numFrames);
    cell_idx=zeros(1000,10000);
    count=1;
    picf0=sprintf('image%d',i);
    fname=[dest_path,'\', picf0];
    mkdir(fname)
    for j = 1 : numFrames
        C1=imread(filename,j);
        C2=imread(filename2,j);
        C3=imread(filename3,j);
        O1=i_adjust(C1);
        O3=i_adjust(C3);
        [bw,icc]=cell_segment_testC1(O1,0.7);
        picf=sprintf('image%dframe%d.png',i,j);
        
        pic_filename = [dest_path, '\', picf0, '\', picf];
        imwrite(bw+O1,pic_filename)
        cp_bw=imerode(bw,strel('disk',1));
        pp_bw=bwlabel(bw-cp_bw);
        background = mean(mean(C2(icc)));
        background_red = mean(mean(C3(icc)));
        curr_reg=regionprops(bw,'Area','PixelIdxList','Perimeter','MajorAxisLength','MinorAxisLength');


        for m = 1 : length(curr_reg)
            cell_idx(m,1:length(curr_reg(m).PixelIdxList))=curr_reg(m).PixelIdxList';
            cell_area(m,j)=curr_reg(m).Area;
            cell_perimeter(m,j)=curr_reg(m).Perimeter;
            cell_maj_axis(m,j)=curr_reg(m).MajorAxisLength;
            cell_min_axis(m,j)=curr_reg(m).MinorAxisLength;
            cell_int(m,j)=mean(C2(curr_reg(m).PixelIdxList))-background;
            count = count+1;
        end

        for m = 1 : size(cell_area,1)
            if isnan(cell_area(m,j))
                cell_idx(m,:)=0;
            end
        end
        
    end
    time = 5 : 5 : 5*numFrames;
    clear('used');

    for ii = 1 : size(cell_area,1)
        used(ii)=nansum(cell_area(ii,:));
    end

    bin_used=used>0;
    if ~isempty(cell_int(bin_used,:))
        xlswrite(r_file,cell_int(bin_used,:),'cell_int')
        xlswrite(r_file,cell_area(bin_used,:),'cell_area')
        xlswrite(r_file,cell_perimeter(bin_used,:),'cell_perimeter')
        xlswrite(r_file,cell_maj_axis(bin_used,:),'cell_maj_axis')
        xlswrite(r_file,cell_min_axis(bin_used,:),'cell_min_axis')
    end
    sprintf('%d / %d',i,count_i-1)
end






function O=i_adjust(I)
    I=double(I);

    mi=min(min(min(I)));
    ma=max(max(max(I)));

    I=I-mi;
    O=I/(ma-mi);
end