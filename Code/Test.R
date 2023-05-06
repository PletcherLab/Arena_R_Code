
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

p<-ParametersClass.PairwiseInteractionCounter(8)
## saved in the output file by DTrack.
p<-Parameters.SetParameter(p,FPS=10)

## The next value is for the old CCD cameras
## mm.per.pixel<-0.2156
## The next value is for the new CCD camera setup
## mm.per.pixel<-0.131
## The next value is roughly good for the Arenas
 mm.per.pixel<-0.056
p<-Parameters.SetParameter(p,mmPerPixel=0.131)

dirname<-"./Data/InteractionCountingData"
arena <- ArenaClass(p, dirname)

SubFunction<-function(a,n){
  result<-NA
  if(sum(a$NObjects)==n){
    if(length(a$RelX)<n){
      result<-0
    }
    else if(length(a$RelX)>n){
      a<-a[a$NObjects>0,]
      diffx <- diff(a$RelX)
      diffy <- diff(a$RelY)
      d <- sqrt(diffx * diffx + diffy * diffy)
      result<-min(d)
    }
    else {
      diffx <- diff(a$RelX)
      diffy <- diff(a$RelY)
      d <- sqrt(diffx * diffx + diffy * diffy)
      print(mean(d))
      result<-min(d)
    }
  }
  result
}


counter<-arena$Tracker_Trach
theData<-counter$RawData
theData<-theData[1:10,]
p<-counter$Parameters
entities<-p$Interacting.Entities


counts<-theData %>% group_by(Frame) %>% mutate(AverageNeighborDistance=SubFunction(cur_data(),entities)) %>% summarise(AverageNeighborDistance = mean(AverageNeighborDistance), Objects = sum(NObjects))
