close all; clear all; clc
addpath(genpath("C:\Users\Carson\Documents\Git\SIOCameraRectification"));
addpath("C:\Users\Carson\Documents\Git\cmcrameri\cmcrameri\cmaps") %Scientific color maps

%% Import iG8 data
GPSpoints=importGPSpoints("20241023_SeacliffcamCGPIG81_2024-10-23-12-09-00");

%% Clean up data import based on comments in file:
% Be careful that index numbers change once you start deleting points!
% This code uses comments to group out sets of GCPs.  Add the comments in
% the field or you can manually add set# in the second column of the data.

GPSpoints(1,:)=[];
GPSpoints(8,:)=[]; %same as point 9
GPSpoints(43,:)=[];

GPSpoints{5,2}="set1"; %rename the reshoot
GPSpoints{6,2}="set2"; %rename the mislabel
GPSpoints{45,2}="set9"; %rename the reshoot

%% Plot options
NUM_IMGsets=10;

%% Plot GPS points on a Map
close all;

load("hawaiiS.txt"); %load color map

plt=geoscatter(GPSpoints.Latitude(1),GPSpoints.Longitude(1),36,hawaiiS(1), "filled");
geobasemap satellite
hold on
for i=1:NUM_IMGsets+1
    setname="set"+i;
    mask=strcmp(GPSpoints{:,2},setname);
    plt=geoscatter(GPSpoints.Latitude(mask,:),GPSpoints.Longitude(mask,:),36,hawaiiS(i,:),"filled");
end    
hold off

% Single out 1 point
% pointofintrest=13;
% geoscatter(GPSpoints.Latitude(pointofintrest),GPSpoints.Longitude(pointofintrest),250,[0,0,0],"filled","p")

% Set figure size
scr_siz = get(0,'ScreenSize') ;
set(gcf,'Position',[floor([10 50 scr_siz(3)*0.8 scr_siz(4)*0.5])]);


% Add labels
a=GPSpoints.Name;
b=num2str(a); c=cellstr(b);
% Randomize the label direction by creating a unit vector.
vec=-1+(1+1)*rand(length(GPSpoints.Name),2);
dir=vec./(((vec(:,1).^2)+(vec(:,2).^2)).^(1/2));
scale=0.000002; % offset text from point
% dir(:)=0; % turn ON randomization by commenting out this line
offsetx=-0.0000004+dir(:,1)*scale; % offset text on the point
offsety=-0.00000008+dir(:,2)*scale; % offset text on the point
text(GPSpoints.Latitude+offsety,GPSpoints.Longitude+offsetx,c)

%% Scratch paper

generateLeviUTC(10,5, '20241023', 'C:\Users\Carson\Documents\Git\SIOCameraRectification\data');