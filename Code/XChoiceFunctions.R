
ExecuteXChoiceAnalysis.Batch<-function(parentFolder,fps,mmPerPixel,trackerType="Tracker",make.plots=FALSE,range=c(0,0)){
  thefolders<-list.dirs(parentFolder)
  thefolders<-thefolders[-1]
  index<-1
  for(f in thefolders){
    print(paste("Analyzing folder:",f,sep=""))
    tmp<-ExecuteXChoiceAnalysis(f,fps,mmPerPixel,trackerType,range)
    if(index==1){
      original.names<-names(tmp$Results)
      results<-data.frame(rep(f,nrow(tmp$Results)),tmp$Results)
      index<-2
    }
    else{
      tt<-data.frame(rep(f,nrow(tmp$Results)),tmp$Results)
      results<-rbind(results,tt)
    }
    if(make.plots==TRUE){
      Plot(tmp$Arena,range)
      PlotXY(tmp$Arena,range)
    }
  }
  if(index==2){
    names(results)<-c("File",original.names)
    return(results)
  }
}

ExecuteXChoiceAnalysis<-function(dirname,fps,mmPerPixel,trackingType="Tracker",range=c(0,0)){
  ## Always put this here to remove any old variables
  CleanTrackers()
  
  if(trackingType=="Tracker"){
    p<-ParametersClass.XChoiceTracker()  
  } else if(trackingType=="Counter"){
    p<-ParametersClass.XChoiceCounter()  
  }
  else {
    stop("Unclear tracking type!!")
  }
  
  p <- Parameters.SetParameter(p, FPS = fps, mmPerPixel = mmPerPixel)
  arena<-ArenaClass(p,dirname)
  
  
  if(length(range)>2){
    results<-Summarize(arena,range[c(1,2)])
    for(i in 2:(length(range)-1)){
      tmp<-Summarize(arena,range[c(i,i+1)])
      results<-rbind(results,tmp)
    }
  }
  else {
    ## Get the basic movement data and treatment frame counts
    ## Also outputs some simple barplots of movement.
    results<-Summarize(arena,range)
  }
  
  
  write.csv(results,file=paste(dirname,"/Results.csv",sep=""),row.names=FALSE)
  
  list(Arena=arena,Results=results)
}