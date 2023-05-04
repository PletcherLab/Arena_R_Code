## Private Functions
TwoChoiceCounter.ProcessTwoChoiceCounter <- function(tracker) {
  if(is.null(tracker$ExpDesign)){
    stop("Two choice tracker requires experimental design.")
  }
  
  a<-"ObjectID" %in% colnames(tracker$ExpDesign)
  b<-"TrackingRegion" %in% colnames(tracker$ExpDesign)   
  c<-"CountingRegion" %in% colnames(tracker$ExpDesign)   
  d<-"Treatment" %in% colnames(tracker$ExpDesign)   
  e<-c(a,b,c,d)
  if(sum(e)<4){
    stop("Experimental design file requires ObjectID, TrackingRegion, CountingRegion, and Treatments columns.")
  }
  
  if(length(unique(tracker$ExpDesign$Treatment))!=2){
    stop("Two choice tracker requires exactly two treatments.")
  }  
  tracker <- TwoChoiceCounter.SetPIData(tracker)
  class(tracker) <- c("TwoChoiceCounter", class(tracker))
  tracker
}


TwoChoiceCounter.SetPIData<-function(tracker){
  rd<-Counter.GetRawData(tracker)
  nm<-names(rd)  
  treatments<-unique(tracker$ExpDesign$Treatment)  
  
  if(length(treatments)!=2) {    
    stop("Wrong number of treatments!") 
  }
  
  tmp<-tracker$ExpDesign
  a<-rd$CountingRegion==tmp$CountingRegion[tmp$Treatment==treatments[1]]
  b<-rd$CountingRegion==tmp$CountingRegion[tmp$Treatment==treatments[2]]  
  regionCount = (a-b)
  
  rd<-data.frame(rd$Minutes,rd$Frame,a,b,regionCount,rd$NObjects,rd$Indicator)
  names(rd)<-c("Minutes","Frame","a","b","RegionCount","Flies","Indicator")
  row.names(rd)<-NULL  
  
  tmp<-rd %>% group_by(Minutes) %>% summarise(A=sum(a), B=sum(b), RegionCount = sum(RegionCount), Flies = sum(Flies), Frame=mean(Frame),Indicator=mean(Indicator))
  names(tmp)<-c("Minutes",treatments[1],treatments[2],"RegionCount","Flies","Frame","Indicator")
  PI <- tmp$RegionCount/tmp$Flies
  
  tmp<-data.frame(tmp,PI)
  
  tracker$PIData<-tmp
  tracker
}

Summarize.TwoChoiceCounter<-function(tracker,range=c(0,0),ShowPlot=TRUE){  
  rd<-Counter.GetRawData(tracker,range)  
  
  treatments<-unique(tracker$ExpDesign$Treatment)    
  if(length(treatments)!=2) {    
    stop("Wrong number of treatments!") 
  }
  
  treatments<-c(treatments,"None")
  tmp<-tracker$ExpDesign
  a<-sum(rd$CountingRegion==tmp$CountingRegion[tmp$Treatment==treatments[1]])
  b<-sum(rd$CountingRegion==tmp$CountingRegion[tmp$Treatment==treatments[2]])
  c<-sum(rd$CountingRegion==treatments[3])
  
  d<-sum()
  
  r.tmp<-matrix(c(a,b,c,d),nrow=1)
  results<-data.frame(tracker$ID,r.tmp,range[1],range[2])
  names(results)<-c("ObjectID","TrackingRegion",treatments,"StartMin","EndMin")
  
  if(ShowPlot){
    tmp<-data.frame(c(results[,3],results[,4],results[,5]),rep("one",3), factor(c(treatments[1],treatments[2],treatments[3])))
    names(tmp)<-c("a","b","Movement")
    print(qplot(x=b,y=a,data=tmp, fill=(Movement)) + geom_bar(stat="identity")+ xlab("Treatment") + ylab("Percentage")) 
  }
  
  results
}

## Public Functions

GetPIData.TwoChoiceCounter<-function(counter,range=c(0,0)){
  pd<-counter$PIData
  if(sum(range)!=0) {    
    pd<- pd[(pd$Minutes>range[1]) & (pd$Minutes<range[2]),]
  }
  pd
}


FinalPI.TwoChoiceCounter<-function(counter,range=c(0,0)) {
  tmp<-GetPIData(counter,range)
  n<-sum(tmp$PI*tmp$Flies)/sum(tmp$Flies)
  d<-sum(tmp$Flies)    
  if(d==0)
    result<-0
  else
    result<-n
  result
}

CumulativePI.TwoChoiceCounter<-function(counter,range=c(0,0)){
  tmp<-GetPIData(counter,range)
  a<-(tmp$PI*tmp$Flies)
  b<-(tmp$Flies)
  
  aa<-cumsum(a)
  bb<-cumsum(b)
  
  cc<-aa/bb
  
  cumRegion1<-cumsum(tmp[,2])
  cumRegion2<-cumsum(tmp[,3])
  cumRegionDiff<-cumsum(tmp[,4])
  cumFlies<-cumsum(tmp[,5])
  
  result<-data.frame(tmp$Minutes,cc,cumRegion1,cumRegion2,cumRegionDiff,cumFlies,tmp$Indicator)
  regionNames<-paste("Cum",names(tmp)[2:3],sep="")
  names(result)<-c("Minutes","CumPI",regionNames,"CumRegionCount","CumFlies","Indicator")
  result
}

Plot.TwoChoiceCounter<-function(counter,range=c(0,0)){
  PIPlots.TwoChoiceCounter(counter,range)
}

PIPlots.TwoChoiceCounter<-function(counter,range=c(0,0)){
  piData<-GetPIData(counter,range)
  pd<-CumulativePI(counter,range)
  nms<-names(pd)
  
  cumsums<-data.frame(c(pd[,1],pd[,1]),c(pd[,3],pd[,4]),rep(c(nms[3],nms[4]),c(length(pd[,1]),length(pd[,1]))),c(pd[,7],pd[,7]))
  names(cumsums)<-c("Minutes","CumSum","Treatment","Indicator")
  
  ymax<-max(pd[c(3,4)])
  x<-ggplot(cumsums) + 
    geom_rect(aes(xmin = Minutes, xmax = dplyr::lead(Minutes,default=0), ymin = -Inf, ymax = Inf, fill = factor(Indicator)), show.legend=F)+
    scale_fill_manual(values = alpha(c("gray","red", "green"), .07)) +
    geom_point(aes(Minutes,CumSum,color=Treatment)) +
    geom_line(aes(Minutes,CumSum,color=Treatment)) +
    ggtitle(paste("Counter:",counter$Name, "   Treatment Counts",sep="")) +
    xlab("Minutes") + ylab("Cumulative Fly Counts") + ylim(0,ymax)
  
  y<-ggplot(pd) + 
    geom_rect(aes(xmin = Minutes, xmax = dplyr::lead(Minutes,default=0), ymin = -Inf, ymax = Inf, fill = factor(Indicator)), show.legend=F)+  
    scale_fill_manual(values = alpha(c("gray", "red","green"), .07)) +
    geom_point(aes(Minutes,CumPI)) +
    geom_line(aes(Minutes,CumPI)) +
    ggtitle(paste("Counter:",counter$Name, "   Cumulative PI",sep="")) +
    xlab("Minutes") + ylab("PI") + ylim(-1,1)
  
  print(x)
  print(y)
}

TimeDependentPIPlots.TwoChoiceCounter<-function(counter,window.size.min=10,step.size.min=3,symbol.mult=5){
  
  ## Get earliest minute possible to avoid edge effects
  low<-floor(Tracker.FirstSampleData(counter)$Minutes)+window.size.min
  ## Get latest minute possible
  high<-floor(Tracker.LastSampleData(counter)$Minutes)
  tmp<-seq(low,high,by=step.size.min)
  results<-data.frame(matrix(rep(-99,(length(tmp)*5)),ncol=5))
  
  
  
  for(i in 1:length(tmp)){
    results[i,1]<-tmp[i]
    
    
    pp<-CumulativePI(counter,c(tmp[i]-window.size.min,tmp[i]))        
    ii<-nrow(pp)
    
    tmp.names<-colnames(pp)
    
    results[i,3]<-pp[ii,3]
    results[i,4]<-pp[ii,4]
    results[i,2]<-pp[ii,2]
    results[i,5]<-mean(pp[,7])
  }  
  
  names(results)<-c("Minutes","PI",tmp.names[3],tmp.names[4],"Indicator")
  
  tmp<-results[,3]+results[,4]
  max.tmp<-max(tmp)
  min.tmp<-min(tmp)
  Size<-tmp/max.tmp*symbol.mult  
  NObs<-tmp
  
  results<-data.frame(results,Size,NObs)
  
  x<-ggplot(results, aes(Minutes,PI,label=NObs))+
    geom_rect(aes(xmin = Minutes, xmax = dplyr::lead(Minutes,default=0), ymin = -Inf, ymax = Inf, fill = Indicator), alpha=0.1)+  
    scale_fill_continuous(name="Light",type = "viridis")+
    geom_line() +
    geom_point(size=Size,color=Size) +
    scale_colour_gradient2(name="Test") +
    geom_text(check_overlap = TRUE, vjust="inward",hjust="inward", color="red")+
    xlim(Tracker.FirstSampleData(counter)$Minutes,Tracker.LastSampleData(counter)$Minutes) +
    ylim(-1,1) +
    ggtitle(paste("ID:",counter$Name,"    Time-Dependent PI"))
  
  print(x)
  results  
}

