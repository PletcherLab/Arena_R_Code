## Note, high density and PI plots require ImageMagik to be installed for 
## simpler PDF outputs.
## Get it here: https://imagemagick.org/script/download.php#windows
## Also required are the following packages: ggplot2, markovchain, Gmisc, 
##  data.table, reshape2, readxl, tibble, stringr, readr


rm(list=ls())
## Do one of the following two
source("./Code/XChoiceFunctions.R")
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
tType = "Tracker"
## NOTE THAT X TRACKER CURRENTLY DOES NOT HAVE A COUNTER OPTION (8/15/2023)
#tType = "Counter"

dirname = "./Data/XChoiceTrackingData"
## NOTE THAT X TRACKER CURRENTLY DOES NOT HAVE A COUNTER OPTION (8/15/2023)
#dirname = "./Data/XChoiceCountingData"

## Execute the analysis and result the arena and results as a list.  The results will also be saved to the data directory as
## as CVS file
results<-ExecuteXChoiceAnalysis(dirname,fps,mm.per.pixel,tType)

## If you want to limit the analysis to a specific time frame, specify the range in minutes.
results<-ExecuteXChoiceAnalysis(dirname,fps,mm.per.pixel,tType,range=c(0,10))

## Or if you want to break it up into several time slices include the breakpoints as part of
## the range parameter.
results<-ExecuteXChoiceAnalysis(dirname,fps,mm.per.pixel,tType,range=c(0,10,40,50))

## To get plots 
Plot(results$Arena)

## If you would like to iterate through a series of subFolders and 
## save the results in each, run the batch analysis here

#parentDirectory = "./Data/XChoiceTrackingData"
parentDirectory = "./Data/XChoiceCountingData"
## IF you want plots, set this to true.  Make sure ImageMagik is installed if so.  Plots take some time.
make.plots = TRUE
batch.results<-ExecuteXChoiceAnalysis.Batch(parentDirectory,fps,mm.per.pixel,tType,make.plots)
## Copy results to clipboard to paste into excel
write.table(batch.results,"clipboard",sep="\t",row.names=FALSE)

###############################################################################################
## Plot the relevant data.  Plots will be output to PDF, note the ImageMagik requirement above.
##PlotX(arena)
##PlotY(arena)
PlotX(results$Arena)
PIPlots(arena)
