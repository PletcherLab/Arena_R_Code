
ExecuteTwoChoiceAnalysis.Batch<-function(parentFolder,fps,mmPerPixel,trackerType="Tracker",make.plots=FALSE,range=c(0,0)){
  thefolders<-list.dirs(parentFolder)
  thefolders<-thefolders[-1]
  for(f in thefolders){
    print(paste("Analyzing folder:",f,sep=""))
    tmp<-ExecuteTwoChoiceAnalysis(f,fps,mmPerPixel,trackerType,range)
    if(make.plots==TRUE){
      Plot(tmp$Arena,range)
    }
  }
}

ExecuteTwoChoiceAnalysis<-function(dirname,fps,mmPerPixel,trackingType="Tracker",range=c(0,0)){
  ## Always put this here to remove any old variables
  CleanTrackers()
  
  if(trackingType=="Tracker"){
    p<-ParametersClass.TwoChoiceTracker()  
  } else if(trackingType=="Counter"){
    p<-ParametersClass.TwoChoiceCounter()  
  }
  else {
    stop("Unclear tracking type!!")
  }
  
  p <- Parameters.SetParameter(p, FPS = fps, mmPerPixel = mmPerPixel)
  
  arena<-ArenaClass(p,dirname)
  
  ## Get the basic movement data and treatment frame counts
  ## Also outputs some simple barplots of movement.
  results<-Summarize(arena,range)
  write.csv(results,file=paste(dirname,"/Results.csv",sep=""),row.names=FALSE)
  
  list(Arena=arena,Results=results)
}