require(plyr)

XChoiceTracker.ProcessXTracker <- function(tracker) {
  if (!is.null(tracker$ExpDesign)) {
    a <- "ObjectID" %in% colnames(tracker$ExpDesign)
    b <- "TrackingRegion" %in% colnames(tracker$ExpDesign)
    c <- "CountingRegion" %in% colnames(tracker$ExpDesign)
    d <- "Treatment" %in% colnames(tracker$ExpDesign)
    e <- "PIMult" %in% colnames(tracker$ExpDesign)
    f <- c(a, b, c, d, e)
    if (sum(f) < 5) {
      stop(
        "Experimental design file requires ObjectID,TrackingRegion, CountingRegion, PiMult, and Treatments columns."
      )
    }
  }
  tracker <- XChoiceTracker.SetXData(tracker)
  class(tracker) <- c("XChoiceTracker", class(tracker))
  tracker
}

XChoiceTracker.SetXData<-function(tracker){
  ## This will use the PI-Multiplier to adjust all X values.
  tmp.id<-tracker$ID
  tmp<-tracker$ExpDesign[tmp.id$ObjectID == tracker$ExpDesign$ObjectID,]
  tmp<-tmp[tmp$TrackingRegion == tracker$ExpDesign$TrackingRegion,]
  if(nrow(tmp)<1){
    stop("Problem in ExpDesign in XChoice Tracker!")
  }
  pimult <- tmp$PIMult[1]
  tracker$RawData$RelX <- tracker$RawData$RelX * pimult
  tracker
}

Summarize.XChoiceTracker<-function(tracker,range=c(0,0),ShowPlot=TRUE){  
  rd<-Tracker.GetRawData(tracker,range)  
  
  ## Now get the summary on the rest
  total.min<-rd$Minutes[nrow(rd)]-rd$Minutes[1]
  total.dist<-(rd$TotalDistance[nrow(rd)]-rd$TotalDistance[1])*tracker$Parameters$mmPerPixel  
  perc.Sleeping<-sum(rd$Sleeping)/length(rd$Sleeping)
  perc.Walking<-sum(rd$Walking)/length(rd$Walking)
  perc.MicroMoving<-sum(rd$MicroMoving)/length(rd$MicroMoving)
  perc.Resting<-sum(rd$Resting)/length(rd$Resting)
  
  avg.speed<-mean(rd$Speed_mm_s)
  
  #treatments<-unique(tracker$ExpDesign$Treatment)    
  #if(length(treatments)!=2) {    
  #  stop("Wrong number of treatments!") 
  #}

  #treatments<-c(treatments,"None")
  #tmp<-tracker$ExpDesign
  ##a<-sum(rd$CountingRegion==tmp$CountingRegion[tmp$Treatment==treatments[1]])
  #b<-sum(rd$CountingRegion==tmp$CountingRegion[tmp$Treatment==treatments[2]])
  #c<-sum(rd$CountingRegion==treatments[3])
  
  #r.tmp<-matrix(c(a,b,c),nrow=1)
  
  avg.x<-mean(rd$Xpos_mm)
  var.x<-var(rd$Xpos_mm)
  
  results<-data.frame(tracker$ID,total.min,total.dist,avg.x,var.x,perc.Sleeping,perc.Walking,perc.MicroMoving,perc.Resting,avg.speed,range[1],range[2])
  names(results)<-c( "ObjectID","TrackingRegion","ObsMinutes","TotalDist_mm","AvgXPosmm","VarXPosmm","PercSleeping","PercWalking","PercMicroMoving","PercResting","AvgSpeed_mm_s","StartMin","EndMin")
  
  if(ShowPlot){
    tmp<-data.frame(c(results$PercWalking,results$PercMicroMoving,results$PercResting,results$PercSleeping),rep("one",4), factor(c("Walking","MicroMoving","Resting","Sleeping")))
    names(tmp)<-c("a","b","Movement")
    print(qplot(x=b,y=a,data=tmp, fill=(Movement)) + geom_bar(stat="identity")+ xlab("Treatment") + ylab("Percentage")) 
  }
  
  results
}

Plot.XChoiceTracker<-function(tracker,range = c(0,0)){  
 PlotX.XChoiceTracker(tracker,range) 
}

PlotX.XChoiceTracker<-function(tracker,range = c(0,0)){  
  PlotX.Tracker(tracker,range)
}

PlotX.XChoiceTracker.Old<-function(tracker,range = c(0,0)){  
  rd<-Tracker.GetRawData(tracker,range)
  tmp2<-rep("Moving",length(rd$X))
  tmp2[rd$Sleeping]<-"Sleeping"
  tmp2[rd$Resting]<-"Resting"
  tmp2[rd$MicroMoving]<-"Micromoving"
  Movement<-tmp2
  rd<-data.frame(rd,Movement)
  
  means <- ddply(rd, "Movement", summarise, Movement.mean = mean(RelX))
  xlims<-c(tracker$ROI[1]/-2,tracker$ROI[1]/2)*tracker$Parameters$mmPerPixel
  x<-ggplot(rd, aes(x = Xpos_mm,fill=Movement)) + xlab("XPos (mm)")+
    geom_density(alpha = .3) + #alpha used for filling the density
    ggtitle(paste(" Tracker:",tracker$Name,sep="")) +
    geom_vline(data = means, aes(xintercept = Movement.mean,color=Movement),
               linetype = "longdash", linewidth=1) + xlim(xlims)
  print(x)
}

## Functions that just catch misapplied higher functions
FinalPI.XChoiceTracker<-function(tracker){
  cat("This function not available for this type of tracker")
}
CumulativePI.XChoiceTracker<-function(tracker){
  cat("This function not available for this type of tracker")
}
GetPIData.XChoiceTracker<-function(tracker,range=c(0,0)){
  cat("This function not available for this type of tracker")
}
PIPlots.XChoiceTracker<-function(tracker,range=c(0,0)){
  cat("This function not available for this type of tracker")
}
TimeDependentPIPlots.XChoiceTracker<-function(tracker,range=c(0,0)){
  cat("This function not available for this type of tracker")
}

PlotDistanceFromCenter.XChoiceTracker <- function(tracker) {
  cat("This function not available for this type of tracker")
}