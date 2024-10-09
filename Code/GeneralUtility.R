
GetCountingRegions<-function(data){
  if("CountingRegion" %in% colnames(data)){
    tmp<-unique(data$CountingRegion)
    r<-tmp[tmp!="None"]
  }
  else {
    r<-NA
  }
  r
}

Get.Transitions.Tracker<-function(tracker,range){
  rd <- Tracker.GetRawData(tracker, range)
  tmp<-rle(as.character(rd$CountingRegion))
  tmp2<-data.frame(tmp$lengths,tmp$values)
  tmp3<-tmp2[tmp2$tmp.values!="None",]
  
  count<-0
  if(nrow(tmp3)>1){
    for(i in 2:nrow(tmp3)){
      if(tmp3$tmp.values[i-1]!=tmp3$tmp.values[i]){
        count<-count+1
      }
    }
  }
  count
}

Get.Transitions.Arena<-function(arena,range=c(0,0)){
  for(i in 1:nrow(arena$Trackers)){
    tt<-arena$Trackers[i,]
    t<-Arena.GetTracker(arena,tt)
    tmps<-Get.Transitions.Tracker(t,range)
    if(exists("result",inherits = FALSE)==TRUE){
      result<-rbind(result,tmps)       
    }
    else {
      result<-tmps     
    }
  }
  result<-data.frame(arena$Trackers,result)
  names(result)<-c(names(arena$Trackers),"Transitions")
  row.names(result)<-1:nrow(result)
  result
}



## Type specific functions
Plot<-function(tracker, ...) UseMethod("Plot",tracker)
Summarize<-function(tracker, ...) UseMethod("Summarize",tracker)
FinalPI<-function(tracker, ...) UseMethod("FinalPI",tracker)
CumulativePI<-function(tracker, ...) UseMethod("CumulativePI",tracker)
PIPlots<-function(tracker, ...) UseMethod("PIPlots",tracker)
TimeDependentPIPlots<-function(tracker, ...) UseMethod("TimeDependentPIPlots",tracker)
PlotXY<-function(tracker, ...) UseMethod("PlotXY",tracker)
PlotTotalDistance<-function(tracker, ...) UseMethod("PlotTotalDistance",tracker)
PlotDistanceFromCenter<-function(tracker, ...) UseMethod("PlotDistanceFromCenter",tracker)
PlotX<-function(tracker, ...) UseMethod("PlotX",tracker)
PlotY<-function(tracker, ...) UseMethod("PlotY",tracker)
GetPIData<-function(tracker, ...) UseMethod("GetPIData",tracker)
AnalyzeTransitions<-function(tracker, ...) UseMethod("AnalyzeTransitions",tracker)
SmoothTransitions<-function(tracker, ...) UseMethod("SmoothTransitions",tracker)
ReportDuration<-function(tracker, ...) UseMethod("ReportDuration",tracker)
UpdateDistanceCutoff<-function(tracker, ...) UseMethod("UpdateDistanceCutoff",tracker)
OutputAliData<-function(tracker, ...) UseMethod("OutputAliData",tracker)
QC<-function(tracker, ...) UseMethod("QC",tracker)