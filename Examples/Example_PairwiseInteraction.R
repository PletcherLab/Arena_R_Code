###################################
## Run this part first
## If no errors, then move on....
rm(list=ls())
## Do one of the following two
source("./Code/PairwiseInteractionFunctions.R")
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
#tType = "Counter"

## Set the interactions distances for which you want to analyze
interaction.distances.mm<-c(2,5,8,10,12)

dirname = "./Data/InteractionTrackingData"
#dirname = "./Data/InteractionCountingData"

## Execute the analysis and result the arena and results as a list.  The results will also be saved to the data directory as
## as CVS file
results<-ExecutePairwiseInteractionAnalysis(dirname,fps,mm.per.pixel,tType,interaction.distances.mm)

## To get plots 
Plot(results$Arena)

## If you would like to iterate through a series of subFolders and 
## save the results in each, run the batch analysis here

parentDirectory = "./Data/InteractionTrackingData"
#parentDirectory = "./Data/InteractionCountingData"
## IF you want plots, set this to true.  Make sure ImageMagik is installed if so.  Plots take some time.
make.plots = TRUE
batch.results<-ExecutePairwiseInteractionAnalysis.Batch(parentDirectory,fps,mm.per.pixel,tType,interaction.distances.mm,make.plots)

## Copy results to clipboard to paste into excel
write.table(batch.results,"clipboard",sep="\t",row.names=FALSE)


## To output the Arena data in a form that we can send to Ali do the following
OutputAliData(results$Arena,dirname)


