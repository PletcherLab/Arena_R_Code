
## Note, high density and PI plots require ImageMagik to be installed for 
## simpler PDF outputs.
## Get it here: https://imagemagick.org/script/download.php#windows
## Also required are the following packages: ggplot2, markovchain, Gmisc, 
##  data.table, reshape2, readxl, tibble, stringr, readr
##if (!require("BiocManager", quietly = TRUE))
##  install.packages("BiocManager")

#install.packages('markovchain')
#install.packages('Gmisc')
#install.packages('data.table')
#install.packages('reshape2')
#install.packages('readxl')
#install.packages('gtools')

#setwd("/Users/longhuag/Dropbox (Personal)/0aging_data/2023/behavior/Arena_R_Code-main/")

rm(list=ls())
## Do one of the following two
source("./Code/ArenaObject.R")

## Always put this here to remove any old variables
CleanTrackers()

## First make a parameter class
## You can define a generic tracker
p<-ParametersClass()

## If you are analyzing a movie, then you need to specify the FPS
## that was used when the movie was recorded!
## If your data were collected with a live (i.e., FLIR) camera,
## then FPS should remain NA because the interframe time is 
## saved in the output file by DTrack.
p<-Parameters.SetParameter(p,FPS=NA)

## This value is good for the Obscura Box
mm.per.pixel<-0.161

## Check out the parameters and ensure that they are appropriate.
## Notably, make sure the mmPerPixel value is correct for your setup.
## Note that sleep is not currently implemented.

## change parameters as you need
##p<-SetParameter(p,Filter.Sleep=1)
##p<-SetParameter(p,Filter.Tracker.Error=`1)

## Place your tracking data and the experiment file in a subdirectory.
## If you name it something other than 'Long' you need to change
## the parameter to the ArenaClass function

arena<-ArenaClass(p,dirname="./Long")


########### Some code for mean movement
results<-data.frame(matrix(c("a",1,1,1,1),nrow=1))
names(results)<-c("TrackingRegion","Mean","Median","Cutoff")
for(i in 1:nrow(arena$Trackers)){
  cutoff1<-.95
  cutoff2<-.999
  tracker<-Arena.GetTracker(arena,arena$Trackers[i,])
  tmp<-tracker$RawData$Speed_mm_s
  tmp<-sort(tmp)
  index1<-length(tmp)*cutoff1
  index2<-length(tmp)*cutoff2
  tmp<-tmp[index1:index2]
  #plot(tmp,ylim=c(0,5))
  #plot(tmp)
  m<-mean(tmp)
  md<-median(tmp)
  name<-arena$Trackers$TrackingRegion[i]
  results<-rbind(results,c(name,m,md,cutoff1,cutoff2))
}
results<-results[-1,]
results$TrackingRegion<-substr(results$TrackingRegion, 1, nchar(results$TrackingRegion)-1)

model<-aov(Mean~TrackingRegion,results)
summary(model)


########### Some code for cutoff movement
results<-data.frame(matrix(c("a",1,1,1),nrow=1))
names(results)<-c("TrackingRegion","FramesMoved","FrachMoved","Cutoff")
for(i in 1:nrow(arena$Trackers)){
  cutoff1<-5
  tracker<-Arena.GetTracker(arena,arena$Trackers[i,])
  tmp<-tracker$RawData$Speed_mm_s
  tmp<-tmp>cutoff1
  m<-sum(tmp)
  md<-m/length(tmp)
  name<-arena$Trackers$TrackingRegion[i]
  results<-rbind(results,c(name,m,md,cutoff1))
}
results<-results[-1,]
results$TrackingRegion<-substr(results$TrackingRegion, 1, nchar(results$TrackingRegion)-1)

model<-aov(FramesMoved~TrackingRegion,results)
summary(model)







## First QC
## Run these two lines then paste results to excel
qc<-QC(arena)
write.table(qc,file = "qc.txt",sep="\t",row.names=FALSE, quote = FALSE)

## Get results for different periods by defining the start
## and end hours
start.hours<-0
end.hours<-0
results<-Summarize(arena,range<-c(60*start.hours,60*end.hours))
write.table(results,file = "0_480h.txt",sep="\t",row.names=FALSE, quote = FALSE)

start.hours<-0
end.hours<-6
results<-Summarize(arena,range<-c(60*start.hours,60*end.hours))
write.table(results,file = "0_6h.txt",sep="\t",row.names=FALSE, quote = FALSE)

start.hours<-6
end.hours<-12
results<-Summarize(arena,range<-c(60*start.hours,60*end.hours))
write.table(results,file = "6_12h.txt",sep="\t",row.names=FALSE, quote = FALSE)

start.hours<-12
end.hours<-18
## Basic movement information and region summaries can be obtained from
results<-Summarize(arena,range<-c(60*start.hours,60*end.hours))
write.table(results,file = "12_18h.txt",sep="\t",row.names=FALSE, quote = FALSE)

## To plot position information use PlotX for either 
## the arena or a specific tracker. If you pass an arena object
## the output is sent to a pdf file by default (can be changed)
## but if you send a tracker it is not.
PlotXY(arena)


write.table(arena$Tracker_old1_0$RawData,file = "old1_rawdata.txt",sep="\t",row.names=FALSE, quote = FALSE)


old1 <- arena$Tracker_old1_0$RawData$Speed_mm_s
old2 <- arena$Tracker_old2_0$RawData$Speed_mm_s
old3 <- arena$Tracker_old3_0$RawData$Speed_mm_s
young1 <- arena$Tracker_young1_0$RawData$Speed_mm_s
young2 <- arena$Tracker_young2_0$RawData$Speed_mm_s
young3 <- arena$Tracker_young3_0$RawData$Speed_mm_s
speed_mm_s <- cbind(old4,old5,old6,young4,young5,young6)
cov <- melt(speed_mm_s)

write.table(speed_mm_s,file = "Speed_mm_s.txt",sep="\t",row.names=FALSE, quote = FALSE)

colnames(cov) <- c("time","age","speed")
ggplot(cov, aes(x=time, y=speed,group=age)) + 
  #geom_line(aes(color=containers)) + 
  geom_point(aes(color=age)) +
  theme(panel.grid.minor= element_line(colour = "white"), panel.grid.major=element_line(colour = "white"))+
  theme(panel.background = element_rect(fill = "white",colour = "black"),plot.background = element_rect(fill = "transparent",colour = "white"))+
  theme(text = element_text(size=12)) +
  theme(axis.text.x = element_text(angle = 45, vjust = 1, hjust=1))
