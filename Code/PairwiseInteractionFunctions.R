
ExecutePairwiseInteractionAnalysis.Batch<-function(parentFolder,fps,mmPerPixel,trackerType="Tracker",Interaction.Distance.mm = c(2, 4, 6, 8, 10, 12),make.plots=FALSE){
  thefolders<-list.dirs(parentFolder)
  thefolders<-thefolders[-1]
  for(f in thefolders){
    print(paste("Analyzing folder:",f,sep=""))
    tmp<-ExecutePairwiseInteractionAnalysis(f,fps,mmPerPixel,trackerType,Interaction.Distance.mm)
    if(make.plots==TRUE){
      Plot(tmp$Arena)
    }
  }
}

ExecutePairwiseInteractionAnalysis<-function(dirname,fps,mmPerPixel,trackingType="Tracker",Interaction.Distance.mm = c(2, 4, 6, 8, 10, 12)){
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
  data.summary<-Summarize(arena)
  IDist <- rep(Interaction.Distance.mm[1], nrow(data.summary))
  data.summary <- data.frame(IDist, data.summary)
  results<-data.summary
  
  if(length(Interaction.Distance.mm)>1){
    for(i in 2:length(Interaction.Distance.mm)){
      arena<-UpdateDistanceCutoff.Arena(arena,Interaction.Distance.mm[i])  
      data.summary<-Summarize(arena)
      IDist <- rep(Interaction.Distance.mm[i], nrow(data.summary))
      data.summary <- data.frame(IDist, data.summary)
      results<-rbind(results,data.summary)
    }
  }
  #or Copy to a clipboard to enter directly into Excel
  write.table(results, "clipboard", sep = "\t", row.names = FALSE)
  list(Arena=arena,Results=results)
}