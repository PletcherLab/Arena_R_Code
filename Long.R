
## Note, high density and PI plots require ImageMagik to be installed for 
## simpler PDF outputs.
## Get it here: https://imagemagick.org/script/download.php#windows
## Also required are the following packages: ggplot2, markovchain, Gmisc, 
##  data.table, reshape2, readxl, tibble, stringr, readr


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

## First QC
## Run these two lines then paste results to excel
qc<-QC(arena)
write.table(qc,"clipboard",sep="\t",row.names=FALSE)

## Get results for different periods by defining the start
## and end hours
start.hours<-0
end.hours<-24
results<-Summarize(arena,range<-c(60*start.hours,60*end.hours))
write.table(results,"clipboard",sep="\t",row.names=FALSE)

start.hours<-0
end.hours<-6
results<-Summarize(arena,range<-c(60*start.hours,60*end.hours))
write.table(results,"clipboard",sep="\t",row.names=FALSE)

start.hours<-6
end.hours<-12
results<-Summarize(arena,range<-c(60*start.hours,60*end.hours))
write.table(results,"clipboard",sep="\t",row.names=FALSE)

start.hours<-12
end.hours<-24
## Basic movement information and region summaries can be obtained from
results<-Summarize(arena,range<-c(60*start.hours,60*end.hours))
write.table(results,"clipboard",sep="\t",row.names=FALSE)

## To plot position information use PlotX for either 
## the arena or a specific tracker. If you pass an arena object
## the output is sent to a pdf file by default (can be changed)
## but if you send a tracker it is not.
PlotXY(arena)

