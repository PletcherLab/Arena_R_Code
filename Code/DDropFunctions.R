require(readr)
source("./Code/ParametersClass.R")
source("./Code/TrackerObject.R")
source("./Code/ArenaObject.R")
source("./Code/GeneralUtility.R")

RunDDropBatch<-function(dirname,p,make.plots=TRUE){
  thefolders<-list.dirs(dirname)
  thefolders<-thefolders[-1]
  for(f in thefolders){
    print(paste("Running DDrop analysis on folder: ",f,sep=""))
    ExecuteDDropAnalysis(f, p,make.plots)
  }
}

ExecuteDDropAnalysis<-function(f,p,make.plots=TRUE){
  ReadDDropFiles(p,f)
  ## This results object will have data for each run as well as average for each
  ## fly.
  results<-Summarize.All.DDropArenas()
  outputfile<- paste("./",f,"/DDropResultsPerRun.csv",sep="")
  write.csv(results$PerRun,file=outputfile,row.names=FALSE)
  outputfile<- paste("./",f,"/DDropResultsPerFly.csv",sep="")
  write.csv(results$PerFly,file=outputfile,row.names=FALSE)
  if(make.plots==TRUE){
  ## Plots can be useful as well
    PlotY(ARENA1)
  }
  results
}
