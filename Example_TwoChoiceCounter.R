###################################
## Run this part first
## If no errors, then move on....
rm(list=ls())
## Do one of the following two
source("ArenaObject.R")

## Always put this here to remove any old variables
CleanTrackers()

## First make a parameter class
## You can define a generic tracker
## You must exactly two counting regions in the experiment (not including "None")
p<-ParametersClass.TwoChoiceCounter()
## saved in the output file by DTrack.
p<-Parameters.SetParameter(p,FPS=NA)

## The next value is for the old CCD cameras
## mm.per.pixel<-0.2156
## The next value is for the new CCD camera setup
## mm.per.pixel<-0.131
## The next value is roughly good for the Arenas
mm.per.pixel<-0.056
##p<-Parameters.SetParameter(p,mmPerPixel=0.056)
##mm.per.pixel<-0.184

#dirname<-"InteractionData"
#arena<-ArenaClass(p,dirname)

dirname<-"TwoChoiceCounterData"

arena<-ArenaClass(p,dirname)

## Get the basic movement data and treatment frame counts
## Also outputs some simple barplots of movement.
results<-Summarize(arena)
write.csv(results,file=paste(dirname,"/Results.csv",sep=""),row.names=FALSE)

## Plot the relevant data.  Plots will be output to PDF, not the ImageMagik requirement above.
##PlotX(arena)
##PlotY(arena)
PlotXY(arena)
PIPlots(arena)

## Additional plots and outputs are available for individual trackers, such as
TimeDependentPIPlots.TwoChoiceTracker(arena$Tracker_T6_0)
