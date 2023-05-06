ExecuteSocialDistanceAnalysis.Batch<-function(parentFolder,fps,mmPerPixel,trackerType="Tracker",interacting.entities=10,make.plots=FALSE,range=c(0,0)){
  thefolders<-list.dirs(parentFolder)
  thefolders<-thefolders[-1]
  index<-1
  for(f in thefolders){
    print(paste("Analyzing folder:",f,sep=""))
    tmp<-ExecuteSocialDistanceAnalysis(f,fps,mmPerPixel,trackerType,interacting.entities,range)
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
    }
  }
  if(index==2){
    names(results)<-c("File",original.names)
    return(results)
  }
}


ExecuteSocialDistanceAnalysis<-function(dirname,fps,mmPerPixel,trackingType="Tracker",interacting.entities=10,range=c(0,0)){

  if(trackingType=="Tracker"){
    stop("Unsupported tracking type!!")
  }
  
  ## Always put this here to remove any old variables
  CleanTrackers()
  
  Interacting.Entities<-interacting.entities
  p<-ParametersClass.SocialDistanceCounter(Interacting.Entities)

  p<-Parameters.SetParameter(p,FPS=fps)
  p<-Parameters.SetParameter(p,mmPerPixel=mmPerPixel)
  
  dirname<-dirname
  arena<-ArenaClass(p,dirname)
  
  data.summary<-Summarize(arena,range)
  
  
  ## You can write the data to a file
  write.csv(
    data.summary,
    file = paste(dirname, "/DataSummary.csv", sep = ""),
    row.names = FALSE
  )
  
  write.csv(data.summary,file=paste(dirname,"/Results.csv",sep=""),row.names=FALSE)
  list(Arena=arena,Results=data.summary)
}

