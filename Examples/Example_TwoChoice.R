## Note, high density and PI plots require ImageMagik to be installed for 
## simpler PDF outputs.
## Get it here: https://imagemagick.org/script/download.php#windows
## Also required are the following packages: ggplot2, markovchain, Gmisc, 
##  data.table, reshape2, readxl, tibble, stringr, readr


rm(list=ls())
## Do one of the following two
source("./Code/TwoChoiceFunctions.R")
source("./Code/ArenaObject.R")
## or
##attach("ARENAFUNCTIONS")

## Set distance unit conversion
## This value is for the old CCD cameras
## mm.per.pixel<-0.2156
## This value is for the new CCD camera setup
## mm.per.pixel<-0.131
## This value is good for the Arenas
mm.per.pixel<-0.056

## Set fps=NA if using the live tracking in the arenas.
## Set fps equal to the actual recorded frames per second if you tracked movies.
fps=NA

## Set tracking type
## If you used predictive tracking in DTrack set this as "Tracker"
## If not use "Counter"
#tType = "Tracker"
tType = "Counter"

#dirname = "./Data/TwoChoiceTrackingData"
dirname = "./Data/TwoChoiceCountingData"

## Execute the analysis and result the arena and results as a list.  The results will also be saved to the data directory as
## as CVS file
results<-ExecuteTwoChoiceAnalysis(dirname,fps,mm.per.pixel,tType,range=c(0,10))

## To get plots 
Plot(results$Arena)

## If you would like to iterate through a series of subFolders and 
## save the results in each, run the batch analysis here

#parentDirectory = "./Data/TwoChoiceTrackingData"
parentDirectory = "./Data/TwoChoiceCountingData"
## IF you want plots, set this to true.  Make sure ImageMagik is installed if so.  Plots take some time.
make.plots = TRUE
ExecuteTwoChoiceAnalysis.Batch(parentDirectory,fps,mm.per.pixel,tType,make.plots)

###############################################################################################
## Plot the relevant data.  Plots will be output to PDF, not the ImageMagik requirement above.
##PlotX(arena)
##PlotY(arena)
PlotXY(arena)
PIPlots(arena)

## Additional plots and outputs are available for individual trackers, such as
TimeDependentPIPlots.TwoChoiceTracker(arena$Tracker_T6_0)



