rm(list=ls())
## Do one of the following two
source("./Code/PairwiseInteractionFunctions.R")
source("./Code/ArenaObject.R")

parentFolder<-"./Data/InteractionCountingData"
parameters<-ParametersClass() 


GetAllFlies<-function(parentFolder,parameters){
  thefolders<-list.dirs(parentFolder)
  thefolders<-thefolders[-1]
  index<-1
  theFlies<-list()
  for(f in thefolders){
    print(paste("Getting folder:",f,sep=""))
    arena <- ArenaClass(parameters, f)
    for(g in 1:nrow(arena$Trackers)){
      tmp<-Arena.GetTracker(arena,arena$Trackers[g,])
      theFlies[[index]]<-tmp
      index<-index+1
    }
  }
  theFlies
}

AnalyzeTwoFlies<-function(theFlies,Interaction.Distance.mm=8){
  tmp<-sample(1:length(theFlies),2,replace=FALSE)
  
  fly1<-theFlies[[tmp[1]]]
  fly1$Parameters$TType<-"PairwiseInteractionCounter"
  fly1$RawData$TrackingRegion<-"Test"
  fly1$RawData$ObjectID<-0
  fly2<-theFlies[[tmp[2]]]
  fly2$Parameters$TType<-"PairwiseInteractionCounter"
  fly2$RawData$TrackingRegion<-"Test"
  fly2$RawData$ObjectID<-1
  
  tmp.rawdata<-rbind(fly1$RawData,fly2$RawData)
  write.csv(tmp.rawdata,file="./Null/Test_Data_1.csv",row.names=FALSE)
  
  mmPerPixel<-0.056
  fps=NA
  tType = "Counter"
  dirname = "./Null"
  Fly1<-tmp[1]
  Fly2<-tmp[2]
  results<-ExecutePairwiseInteractionAnalysis(dirname,fps,mmPerPixel,tType,Interaction.Distance.mm)
  tmp<-data.frame(Fly1,Fly2,results$Results)
  tmp
}

theFlies<-GetAllFlies(parentFolder,parameters)
for(i in 1:50){
  print(paste("Running sample: ",i,sep=""))
  flush.console()
  if(i==1){
    results<-AnalyzeTwoFlies(theFlies)
  }
  else{
    results<-rbind(results,AnalyzeTwoFlies(theFlies))
  }
}

save.image()