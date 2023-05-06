ExecutePairwiseInteractionAnalysis.Batch<-function(parentFolder,fps,mmPerPixel,trackerType="Tracker",Interaction.Distance.mm = c(2, 4, 6, 8, 10, 12),make.plots=FALSE,range=c(0,0)){
  thefolders<-list.dirs(parentFolder)
  thefolders<-thefolders[-1]
  index<-1
  for(f in thefolders){
    print(paste("Analyzing folder:",f,sep=""))
    tmp<-ExecutePairwiseInteractionAnalysis(f,fps,mmPerPixel,trackerType,Interaction.Distance.mm,range)
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

ExecutePairwiseInteractionAnalysis<-function(dirname,fps,mmPerPixel,trackingType="Tracker",Interaction.Distance.mm = c(2, 4, 6, 8, 10, 12),range=c(0,0)){
  ## Always put this here to remove any old variables
  CleanTrackers()
  
  if(trackingType=="Tracker"){
    p<-ParametersClass.PairwiseInteractionTracker(Interaction.Distance.mm[1])  
  } else if(trackingType=="Counter"){
    p<-ParametersClass.PairwiseInteractionCounter(Interaction.Distance.mm[1])  
  }
  else {
    stop("Unclear tracking type!!")
  }
  
  p <- Parameters.SetParameter(p, FPS = fps, mmPerPixel = mmPerPixel)
  
  arena <- ArenaClass(p, dirname)
  data.summary<-Summarize(arena,range)
  IDist <- rep(Interaction.Distance.mm[1], nrow(data.summary))
  data.summary <- data.frame(IDist, data.summary)
  results<-data.summary
  
  if(length(Interaction.Distance.mm)>1){
    for(i in 2:length(Interaction.Distance.mm)){
      arena<-UpdateDistanceCutoff.Arena(arena,Interaction.Distance.mm[i])  
      data.summary<-Summarize(arena,range)
      IDist <- rep(Interaction.Distance.mm[i], nrow(data.summary))
      data.summary <- data.frame(IDist, data.summary)
      results<-rbind(results,data.summary)
    }
  }
  
  write.csv(results,file=paste(dirname,"/Results.csv",sep=""),row.names=FALSE)
  list(Arena=arena,Results=results)
}