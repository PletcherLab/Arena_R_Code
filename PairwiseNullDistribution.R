rm(list=ls())
## Do one of the following two
source("./Code/PairwiseInteractionFunctions.R")
source("./Code/ArenaObject.R")

Interaction.Distance.mm<-c(8,12)
parentFolder<-"./Data/InteractionCountingData"
parameters<-ParametersClass() 


GetAllFlies<-function(parentFolder,parameters){
  thefolders<-list.dirs(parentFolder)
  thefolders<-thefolders[-1]
  index<-1
  for(f in thefolders){
    print(paste("Getting folder:",f,sep=""))
    arena <- ArenaClass(parameters, f)
    if(index==1){
      
    }
    else{
      
    }
  }
  if(index==2){
    
  }
}
