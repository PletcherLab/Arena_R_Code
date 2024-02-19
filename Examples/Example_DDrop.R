rm(list=ls())
source("./Code/DDropFunctions.R")
## In the output directory make sure to include the Experiment .xlxs file as well
## as the tacking csv files for each run. The original xlxs file is used to define
## the lanes. An experimental design file is optional (ExpDesign.csv) but helps
## simply downstream organization.
dirname<-"./Data/DDropData"
p<-ParametersClass.DDrop()

## Depending on your FPS, you might consider an appropriate window size for speed calculations.
## This value is in sec and specifies the period over which speed is determined.
## The default is 1 sec, which should be okay for most cases, except maybe for very high or 
## very low frame rates.
#speed.window.sec<-2
#p<-Parameters.SetParameter(p,Speed.Window.sec=speed.window.sec)

## Set this to the total time observed for each run
p<-Parameters.SetParameter(p,ObservationTime.sec=15)
## Set this to the divisions to analyze y distance moved
p<-Parameters.SetParameter(p,DDropDivision.sec=3)
## Set this to proper conversion for the camera
## Pletcher lab = 0.087
p<-Parameters.SetParameter(p,mmPerPixel=0.087)

results<-ExecuteDDropAnalysis(dirname,p,make.plots=TRUE)
## Copy results to clipboard to paste into excel
write.table(results,"clipboard",sep="\t",row.names=FALSE)

## Batch results are written into individual directories
RunDDropBatch(dirname,p,make.plots=TRUE)