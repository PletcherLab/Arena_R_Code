rm(list=ls())
## Do one of the following two
source("./Code/ArenaObject.R")

## Always put this here to remove any old variables
CleanTrackers()

## First make a parameter class
## You can define a generic tracker
p<-ParametersClass()

p<-ParametersClass.CentrophobismTracker()

## If you are analyzing a movie, then you need to specify the FPS
## that was used when the movie was recorded!
## If your data were collected with a live (i.e., FLIR) camera,
## then FPS should remain NA because the interframe time is 
## saved in the output file by DTrack.
p<-Parameters.SetParameter(p,FPS=NA)


## Depending on your FPS, you might consider an appropriate window size for speed calculations.
## This value is in sec and specifies the period over which speed is determined.
## The default is 1 sec, which should be okay for most cases, except maybe for very high or 
## very low frame rates.
#speed.window.sec<-2
#p<-Parameters.SetParameter(p,Speed.Window.sec=speed.window.sec)

## This value is good for the Arenas
mm.per.pixel<-0.17

p<-Parameters.SetParameter(p,mmPerPixel=mm.per.pixel)

## Check out the parameters and ensure that they are appropriate.
## Notably, make sure the mmPerPixel value is correct for your setup.
## Note that sleep is not currently implemented.

## change parameters as you need
##p<-SetParameter(p,Filter.Sleep=1)
##p<-SetParameter(p,Filter.Tracker.Error=`1)

## Place your tracking data and the experiment file in a subdirectory.
## If you name it something other than 'Data' you need to supply it as
## a parameter to the ArenaClass function
## ArenaClass<-function(parameters,dirname="Data")

dirname = "./Data/GeneralTrackingData"


arena<-ArenaClass(p,dirname=dirname)
summaries<-Summarize(arena)

## Check for lots of not found or indescernible frames.
QC.ArenaTracker(arena)

## Maybe as a function of time
QC.ArenaTracker(arena, range=c(100,2000))


## Because it takes a long time to read in and analyze data.
## Save the RFile.  This will allow you to avoid running the above lines again
## if you come back to the project to do more. 
save.file<-paste(dirname,"/.RData",sep="")
save.image(save.file)

summaries
write.table(summaries, "clipboard", sep="\t", row.names=FALSE)

## Plotting will take some time!
## Can use this to evaluate movement and death time estimates.
PlotTotalDistance(arena)

PlotDistanceFromCenter(arena)

## Beta attempt at estimating death times.
deathtimes<-EstimateTimesOfDeath(arena)
write.table(deathtimes, "clipboard", sep="\t", row.names=FALSE)

