function [bw,mask]=cell_segment_testC1(O3,f)
    bw_temp=im2bw(O3,graythresh(O3)*f);
    b = imsharpen(O3,'Radius',4,'Amount',3);
    J = imfilter(b, ones(3)/9);
    J = imfilter(J, ones(3)/9);
    %use triangle method or minerror
    hist=imhist(O3);
    level=triangle_th(hist,length(hist));
    bw=im2bw(O3,level);
    bw=imdilate(bw,strel('disk',3));
    icc=imfill(bw,'holes');
    ic=icc-bw;
    nc2=bwmorph(ic,'skel');
    
    bw_temp=imdilate(bw_temp,strel('disk',3));
    ic_temp=imcomplement(bw_temp);
    ic_temp=imclearborder(ic_temp);
    ic_temp = bwareaopen(ic_temp,400);
    ic = bwpropfilt(logical(ic_temp),'EulerNumber',[1 1]);
    ic = imerode(ic,strel('disk',3));
    ic = imdilate(ic,strel('disk',3));
    %ic = imerode(ic,strel('disk',3));
    ic = bwareaopen(ic,400);
    ic = bwpropfilt(logical(ic),'Eccentricity',[0.7 1]);
    nc=imerode(ic,strel('disk',7));
    regIC=regionprops(ic,'PixelIdxList');
    regNC=regionprops(nc,'PixelIdxList');

    ce=ic;
    
    for i = 1 : length(regNC)
        for j = 1 : length(regIC)
            temp=cat(1,regIC(j).PixelIdxList,regNC(i).PixelIdxList);
            [~,ind]=unique(temp);
            if size(ind,1) < size(temp,1)
                ce(regIC(j).PixelIdxList)=0;
            end
        end
    end


    ci=O3;
    ci=imcomplement(ci);
    %ce=imdilate(ce,strel('disk',5));
    ci(~logical(ce))=0;
    cii=imcomplement(ci);

    %watershed
    ce2=~bwareaopen(~ce,10);
    D=-bwdist(~ci);

    mask=imextendedmin(D,2);

    D2=imimposemin(D,mask);
    L=watershed(D2);
    ce3=ce;
    ce3(L==0)=0;

    bw=ce3;
    bw = bwareaopen(bw,350);
    mask=icc;
end