source("./Code/TrackerObject.R")
source("./Code/CounterObject.R")
source("./Code/GeneralUtility.R")
require(data.table)
require(reshape2)
require(readxl)
require(tibble)
require(plyr)
require(dplyr)
require(ggplot2)
require(gtools)
require(zoo)


ArenaClass<-function(parameters,dirname="Data"){
 if(grepl(".*Counter",parameters$TType)==TRUE){
   arena<-ArenaCounterClass(parameters,dirname)
 } 
  else if(grepl(".*Tracker",parameters$TType)==TRUE){
    arena<-ArenaTrackerClass(parameters,dirname)
  }
  else {
    stop("Parameters don't indicate tracker or counter!")
  }
  arena
}


## Public Functions ##
ArenaCounterClass<-function(parameters,dirname="Data"){
  datadir<-paste("./",dirname,"/",sep="")
  files <- list.files(path=datadir,pattern = "*Data_[0-9]*.csv")    
  if(length(files)<1) {
    cat("No tracking files found.")
    flush.console()      
  }
  files<-mixedsort(files)
  files<-paste(datadir,files,sep="")

  theData<-rbindlist(lapply(files, function(x){read.csv(x, header=TRUE)}))
  
  ## Try to correct previous version files.
  if(!("TrackingRegion" %in% names(theData))){
    names(theData)[names(theData) == "Region"] <- "CountingRegion"
    names(theData)[names(theData) == "Name"] <- "TrackingRegion"
  }
  
  tmp<-unique(theData[,c("TrackingRegion")])
  
  cf<-tmp$TrackingRegion
  
  trackers<-data.frame(str_sort(cf,numeric=TRUE))
  trackers<-data.frame(rep("NA",nrow(trackers)),trackers)
  
  names(trackers)<-c("ObjectID","TrackingRegion")
  #trackers<-tmp %>% slice(match(tmp2,TrackingRegion))
  
  ## Get the tracking ROI and the Counting ROI
  ## This reg expression tries to avoid temporary files that begin with '~'
  file <- list.files(datadir, pattern = "^[^~].*xlsx")
  if(length(file)>1)
    stop("Only allowed one experiment file in the directory")
  if(length(file)<1)
    stop("Original experiment file is missing")
  file<-paste(datadir,file,sep="")
  roi <- read_excel(file, sheet = "ROI")
  roi<-subset(roi,roi$Name!="AutoGenerateAntiMask")
  
  ## Look for experimental design file
  files <- list.files(path = datadir, pattern = "ExpDesign.csv") 
  if (length(files) < 1) {
    expDesign <- NULL
  }
  else {
    files <- paste(datadir, files, sep = "")    
    expDesign <- read.csv(files[1])    
  }
  

  arena <- list(Name = "ArenaCounter1", Trackers = trackers, ROI = roi, ExpDesign=expDesign, DataDir=dirname, FileName=dirname)
  if(nrow(trackers)>0){
    for(i in 1:nrow(trackers)){
      nm<-paste("Tracker",trackers[i,]$TrackingRegion,sep="_")
      roinm<-trackers[i,1]
      theROI<-c(roi$Width[roi$Name==roinm],roi$Height[roi$Name==roinm])
      theCountingROI<-roi$Name[roi$Type=="Counting"]
      if(length(theCountingROI)<1)
        theCountingROI<-"None"
      tmp<-CounterClass.RawDataFrame(trackers[i,],parameters,theData,theROI,theCountingROI,expDesign)
      arena<-c(arena,setNames(list(nm=tmp),nm))
    }
  }
  class(arena)=c("ArenaCounter","Arena")
  
  assign("ARENACOUNTER1",arena,pos=1)  
  print(paste("ARENACOUNTER1 object saved."))
  arena
}


ArenaTrackerClass<-function(parameters,dirname="Data"){
  datadir<-paste("./",dirname,"/",sep="")
  files <- list.files(path=datadir,pattern = "*Data_[0-9]*.csv")    
  if(length(files)<1) {
    cat("No tracking files found.")
    flush.console()      
  }
  files<-mixedsort(files)
  files<-paste(datadir,files,sep="")
  
  theData<-rbindlist(lapply(files, function(x){read.csv(x, header=TRUE)}))

  ## Try to correct previous version files.
  if(!("TrackingRegion" %in% names(theData))){
    names(theData)[names(theData) == "Region"] <- "CountingRegion"
    names(theData)[names(theData) == "Name"] <- "TrackingRegion"
  }
  
  tmp<-unique(theData[,c("ObjectID","TrackingRegion")])
  trackers<-tmp[with(tmp,order(TrackingRegion,ObjectID))]
  
  #cf<-tmp$TrackingRegion
  #tmp2<-str_sort(cf,numeric=TRUE)
  #trackers<-tmp %>% slice(match(tmp2,TrackingRegion))
  
  ## Get the tracking ROI and the Counting ROI
  ## This reg expression tries to avoid temporary files that begin with '~'
  file <- list.files(datadir, pattern = "^[^~].*xlsx")
  if(length(file)>1)
    stop("Only allowed one experiment file in the directory")
   if(length(file)<1)
    stop("Original experiment file is missing")
  file<-paste(datadir,file,sep="")
  roi <- read_excel(file, sheet = "ROI")
  roi<-subset(roi,roi$Name!="AutoGenerateAntiMask")
  
  ## Look for experimental design file
  files <- list.files(path = datadir, pattern = "ExpDesign.csv") 
  if (length(files) < 1) {
    expDesign <- NULL
  }
  else {
    files <- paste(datadir, files, sep = "")    
    expDesign <- read.csv(files[1])    
  }
  
  
  arena <- list(Name = "Arena1", Trackers = trackers, ROI = roi, ExpDesign=expDesign, DataDir=dirname, FileName=dirname)

  if(nrow(trackers)>0){
    for(i in 1:nrow(trackers)){
      nm<-paste("Tracker",trackers[i,2],trackers[i,1],sep="_")
      print(nm)
      roinm<-trackers$TrackingRegion[i]
      theROI<-c(roi$Width[roi$Name==roinm],roi$Height[roi$Name==roinm])
      theCountingROI<-roi$Name[roi$Type=="Counting"]
      if(length(theCountingROI)<1)
        theCountingROI<-"None"
      tmp<-TrackerClass.RawDataFrame(trackers[i,],parameters,theData,theROI,theCountingROI,expDesign)
      arena<-c(arena,setNames(list(nm=tmp),nm))
    }
  }
  class(arena)=c("ArenaTracker","Arena")
  
  assign("ARENA1",arena,pos=1)  
  print(paste("ARENA1 object saved."))
  arena
}


ReadDDropFiles<-function(parameters,dirname="Data"){
  datadir<-paste("./",dirname,"/",sep="")
  files <- list.files(path=datadir,pattern = "*Data_[0-9]*.csv")   
  if(length(files)<1) {
    cat("No tracking files found.")
    flush.console()      
  }
  justfilenames<-files
  files<-paste(datadir,files,sep="")
  for(i in 1:length(files)){
    f<-files[i]
    runnumber<-sub(".*Data_","",justfilenames[i])
    runnumber<-sub("\\.csv","",runnumber)
    Load.DDrop.Object(parameters,f,dirname,runnumber)
  }
}

Load.DDrop.Object<-function(parameters,filename,dirname,runNumber){
  datadir<-paste("./",dirname,"/",sep="")
  theData<-read.csv(filename, header=TRUE)
  
  ## Just for DDrop, the RELY position needs to be inverted (for plotting, etc)
  theData$RelY<-theData$RelY*(-1.0)
  
  if(!("TrackingRegion" %in% names(theData))){
    names(theData)[names(theData) == "Region"] <- "CountingRegion"
    names(theData)[names(theData) == "Name"] <- "TrackingRegion"
  }
  
  tmp<-unique(theData[,c("ObjectID","TrackingRegion")])
  cf<-tmp$TrackingRegion
  tmp2<-str_sort(cf,numeric=TRUE)
  trackers<-tmp %>% slice(match(tmp2,TrackingRegion))
  

  ## Get the tracking ROI and the Counting ROI
  ## This reg expression tries to avoid temporary files that begin with '~'
  file <- list.files(datadir, pattern = "^[^~].*xlsx")
  if(length(file)>1)
    stop("Only allowed one experiment file in the directory")
  if(length(file)<1)
    stop("Original experiment file is missing")
  file<-paste(datadir,file,sep="")
  roi <- read_excel(file, sheet = "ROI")
  roi<-subset(roi,roi$Name!="AutoGenerateAntiMask")
  
  ## Look for experimental design file
  files <- list.files(path = datadir, pattern = "ExpDesign.csv") 
  if (length(files) < 1) {
    expDesign <- NULL
  }
  else {
    files <- paste(datadir, files, sep = "")    
    expDesign <- read.csv(files[1])    
    expDesign<-subset(expDesign,expDesign$Run==runNumber)
  }
  
  arenaName<-paste("Arena",runNumber,sep="")
  DDrop <- list(Name = arenaName, Trackers = trackers, ROI = roi, ExpDesign=expDesign, DataDir=dirname, FileName=filename)
  
  if(nrow(trackers)>0){
    for(i in 1:nrow(trackers)){
      nm<-paste("Tracker",trackers[i,2],trackers[i,1],sep="_")
      roinm<-trackers$TrackingRegion[i]
      theROI<-c(roi$Width[roi$Name==roinm],roi$Height[roi$Name==roinm])
      theCountingROI<-roi$Name[roi$Type=="Counting"]
      if(length(theCountingROI)<1)
        theCountingROI<-"None"
      tmp<-TrackerClass.RawDataFrame(trackers[i,],parameters,theData,theROI,theCountingROI,expDesign)
      DDrop<-c(DDrop,setNames(list(nm=tmp),nm))
    }
  }
  
  class(DDrop)=c("ArenaTracker","Arena")
  st<-paste("ARENA",runNumber,sep="")
  assign(st,DDrop,pos=1)  
  print(paste("DDrop run",filename,"saved as",st))
  DDrop
}


GetMeanXPositions.Arena<-function(arena,range=c(0,0)){
  for(i in 1:nrow(arena$Trackers)){
    tt<-arena$Trackers[i,]
    t<-Arena.GetTracker(arena,tt)
    tmps<-GetMeanXPositions.Tracker(t,range)
    if(exists("result",inherits = FALSE)==TRUE){
      result<-rbind.missing(result,tmps)       
    }
    else {
      result<-tmps     
    }
  }
  result
}

GetQuartileXPositions.Arena<-function(arena,quartile=1,range=c(0,0)){
  for(i in 1:nrow(arena$Trackers)){
    tt<-arena$Trackers[i,]
    t<-Arena.GetTracker(arena,tt)
    tmps<-GetQuartileXPositions.Tracker(t,quartile,range)
    if(exists("result",inherits = FALSE)==TRUE){
      result<-rbind.missing(result,tmps)       
    }
    else {
      result<-tmps     
    }
  }
  result
}

OutputAliData.ArenaCounter <- function(arena,dirname) {
  trackers.to.get <- arena$Trackers
  
  max.rows<-0
  for(i in 1:nrow(trackers.to.get)){
    tmp <- Arena.GetTracker(arena, trackers.to.get[i, ])
    if(tmp$Parameters$TType!="PairwiseInteractionCounter"){
      stop("Ali output not implmented for this type of counter.")
    }
    tmp2<-length(tmp$InteractionData$Results$ClosestNeighbor_mm)
    if(tmp2>max.rows)
      max.rows<-tmp2
  }
  
  results<-data.frame(matrix(rep(NA,max.rows*(nrow(trackers.to.get)+1)),ncol=nrow(trackers.to.get)+1))
  
  results[,1]<-1:nrow(results)
  for (i in 1:nrow(trackers.to.get)) {
    tmp <- Arena.GetTracker(arena, trackers.to.get[i, ])
    if(tmp$Parameters$TType!="PairwiseInteractionCounter"){
      stop("Ali output not implmented for this type of counter.")
    }
    tmp<-tmp$InteractionData$Results$ClosestNeighbor_mm
    results[1:length(tmp),i+1] <-tmp
  }
  names(results)<-c("Index",trackers.to.get[,1])
  print(paste(dirname,"/AliOutput.csv",sep=""))
  write.csv(results,paste(dirname,"/AliOutput.csv",sep=""),row.names = FALSE)
}

OutputAliData.ArenaTracker <- function(arena,dirname) {
  ## Just get the first of the pair.
  trackers.to.get <- arena$Trackers[arena$Trackers$ObjectID == 0, ]
  
  tmp <- Arena.GetTracker(arena, trackers.to.get[1, ])
  results <- data.frame(tmp$RawData[, c("Minutes", "ClosestNeighbor_mm")])
  names(results) <- c("Minutes", tmp$Name)
  
  if (nrow(trackers.to.get) > 1) {
    for (i in 2:nrow(trackers.to.get)) {
      tmp <- Arena.GetTracker(arena, trackers.to.get[i, ])
      nn<-names(results)
      results <- data.frame(results, tmp$RawData$ClosestNeighbor_mm)
      names(results)<-c(nn,tmp$Name)
    }
  }
  
  write.csv(results,paste(dirname,"/AliOutput.csv",sep=""),row.names = FALSE)
}


Summarize.ArenaCounter<-function(arena,range=c(0,0),ShowPlot=TRUE, WriteToPDF=TRUE){
  for(i in 1:nrow(arena$Trackers)){
    tt<-arena$Trackers[i,]
    t<-Arena.GetTracker(arena,tt)
    tmps<-Summarize(t,range,FALSE)
    if(exists("result",inherits = FALSE)==TRUE){
      result<-rbind(result,tmps)       
    }
    else {
      result<-tmps     
    }
  }
  result
}

Summarize.ArenaTracker<-function(arena,range=c(0,0),ShowPlot=TRUE, WriteToPDF=TRUE){
  for(i in 1:nrow(arena$Trackers)){
    tt<-arena$Trackers[i,]
    t<-Arena.GetTracker(arena,tt)
    tmps<-Summarize(t,range,FALSE)
    if(exists("result",inherits = FALSE)==TRUE){
      result<-rbind(result,tmps)       
    }
    else {
      result<-tmps     
    }
  }
  if(ShowPlot==TRUE){
    if(WriteToPDF==TRUE) {
      fname<-paste("./",arena$DataDir,"/",arena$Name,"_SummaryPlots.pdf",sep="")
      pdf(fname,paper="USr",onefile=TRUE)
      par(mfrow=c(3,2))
    }
    tmp.result<-result[,c("ObjectID","TrackingRegion","PercSleeping","PercWalking","PercMicroMoving","PercResting")]
    tmp.result[is.na(tmp.result)]<-0
    
    tmp.result1<-melt(tmp.result,id.var=c("TrackingRegion","ObjectID"))
    tmp.result1<-data.frame(paste(tmp.result1$TrackingRegion,"_",tmp.result1$ObjectID,sep=""),tmp.result1)
    names(tmp.result1)<-c("ID","TrackingRegion","ObjectID","Type","value")
    
    print(ggplot(tmp.result1, aes(x = ID, y = value, fill = Type))+ 
      geom_bar(stat = "identity")+ggtitle(paste("Arena"," -- Distribution")) +
      labs(x="Tracker ID",y="Fraction"))
    
    ## Now reflect total movement
    tmp.result<-result[,c("ObjectID","TrackingRegion","PercSleeping","PercWalking","PercMicroMoving","PercResting")]
    tmp.result[is.na(tmp.result)]<-0
    
    tmp.result[,"PercSleeping"]<-result[,"PercSleeping"]*result$TotalDist_mm
    tmp.result[,"PercWalking"]<-result[,"PercWalking"]*result$TotalDist_mm
    tmp.result[,"PercMicroMoving"]<-result[,"PercMicroMoving"]*result$TotalDist_mm
    tmp.result[,"PercResting"]<-result[,"PercResting"]*result$TotalDist_mm
    tmp.result1<-melt(tmp.result,id.var=c("TrackingRegion","ObjectID"))
    tmp.result1<-data.frame(paste(tmp.result1$TrackingRegion,"_",tmp.result1$ObjectID,sep=""),tmp.result1)
    names(tmp.result1)<-c("ID","TrackingRegion","ObjectID","Type","value")
    
    print(ggplot(tmp.result1, aes(x = ID, y = value, fill = Type))+ 
            geom_bar(stat = "identity")+ggtitle(paste("Arena",arena$Name," -- Total Movement")) +
            labs(x="Tracker ID",y="Distance (mm)"))
    if(WriteToPDF==TRUE){
      graphics.off()
    }
  }
  result
}

QC.ArenaTracker<-function(arena,range=c(0,0),ShowPlot=TRUE, WriteToPDF=TRUE){
  for(i in 1:nrow(arena$Trackers)){
    tt<-arena$Trackers[i,]
    t<-Arena.GetTracker(arena,tt)
    tmps<-QC(t,range,FALSE)
    if(exists("result",inherits = FALSE)==TRUE){
      result<-rbind(result,tmps)       
    }
    else {
      result<-tmps     
    }
  }
  if(ShowPlot==TRUE){
    if(WriteToPDF==TRUE) {
      fname<-paste("./",arena$DataDir,"/",arena$Name,"_QCPlots.pdf",sep="")
      pdf(fname,paper="USr",onefile=TRUE)
      par(mfrow=c(3,2))
    }
    tmp.result<-result[,c("ObjectID","TrackingRegion","PercHigh","PercIndiscernible","PercNotFound")]
    tmp.result[is.na(tmp.result)]<-0
    
    tmp.result1<-melt(tmp.result,id.var=c("TrackingRegion","ObjectID"))
    tmp.result1<-data.frame(paste(tmp.result1$TrackingRegion,"_",tmp.result1$ObjectID,sep=""),tmp.result1)
    names(tmp.result1)<-c("ID","TrackingRegion","ObjectID","Type","value")
    
    print(ggplot(tmp.result1, aes(x = ID, y = value, fill = Type))+ 
            geom_bar(stat = "identity")+ggtitle(paste("Arena"," -- Distribution")) +
            labs(x="Tracker ID",y="Fraction Frames"))
    
    if(WriteToPDF==TRUE){
      graphics.off()
    }
  }
  result
}


Plot.Arena<-function(arena,range=c(0,0),WriteToPDF=TRUE){
  fname<-paste("./",arena$DataDir,"/",arena$Name,"_Plots.pdf",sep="")
  tmp.list<-list()
  if(WriteToPDF==TRUE) {
    #pdf(fname,paper="USr",onefile=TRUE)
    mypdf(fname,res = 600, height = 9, width = 11, units = "in")
    par(mfrow=c(3,2))
  }
  for(i in 1:nrow(arena$Trackers)){
    tt<-arena$Trackers[i,]
    t<-Arena.GetTracker(arena,tt)
    Plot(t,range)
  }
  if(WriteToPDF==TRUE){
    #graphics.off()
    mydev.off(fname)
  }
}


PlotXY.Arena<-function(arena,range=c(0,0),WriteToPDF=TRUE){
  fname<-paste("./",arena$DataDir,"/",arena$Name,"_XYPlots.pdf",sep="")
  tmp.list<-list()
  if(WriteToPDF==TRUE) {
    #pdf(fname,paper="letter",onefile=TRUE)
    mypdf(fname,res = 600, height = 9, width = 11, units = "in")
    par(mfrow=c(3,2))
  }
  for(i in 1:nrow(arena$Trackers)){
    tt<-arena$Trackers[i,]
    t<-Arena.GetTracker(arena,tt)
    PlotXY(t,range)
  }
  if(WriteToPDF==TRUE){
    #graphics.off()
    mydev.off(fname)
  }
}


EstimateTimesOfDeath<-function(arena){
  for(i in 1:nrow(arena$Trackers)){
    tt<-arena$Trackers[i,]
    t<-Arena.GetTracker(arena,tt)
    x<-which(t$RawData$Sleeping==FALSE)
    min<-t$RawData[x[length(x)],"Minutes"]
    if(i==1){
      results<-data.frame(tt,min)
      names(results)<-c("ObjectID","TrackingRegion","DeathTime_min")
    }
    else {
      tmp<-data.frame(tt,min)
      names(tmp)<-c("ObjectID","TrackingRegion","DeathTime_min")
      results<-rbind(results,tmp)
    }
  }
  
  hours<-results$DeathTime_min/60
  results<-cbind(results,hours)
  names(results)<-c("ObjectID","TrackingRegion","DeathTime_min","DeathTime_hour")
  results
}


PlotTotalDistance.Arena<-function(arena,range=c(0,0),WriteToPDF=TRUE){
  fname<-paste("./",arena$DataDir,"/",arena$Name,"_Distance.pdf",sep="")
  tmp.list<-list()
  if(WriteToPDF==TRUE) {
    #pdf(fname,paper="USr",onefile=TRUE)
    mypdf(fname,res = 600, height = 9, width = 11, units = "in")
    par(mfrow=c(3,2))
  }
  for(i in 1:nrow(arena$Trackers)){
    tt<-arena$Trackers[i,]
    t<-Arena.GetTracker(arena,tt)
    PlotTotalDistance(t,range)
  }
  if(WriteToPDF==TRUE){
    #graphics.off()
    mydev.off(fname)
  }
}

PlotDistanceFromCenter.Arena<-function(arena,range=c(0,0),WriteToPDF=TRUE){
  fname<-paste("./",arena$DataDir,"/",arena$Name,"_DistanceFromCenter.pdf",sep="")
  tmp.list<-list()
  if(WriteToPDF==TRUE) {
    #pdf(fname,paper="USr",onefile=TRUE)
    mypdf(fname,res = 600, height = 9, width = 11, units = "in")
    par(mfrow=c(3,2))
  }
  for(i in 1:nrow(arena$Trackers)){
    tt<-arena$Trackers[i,]
    t<-Arena.GetTracker(arena,tt)
    PlotDistanceFromCenter(t,range)
  }
  if(WriteToPDF==TRUE){
    #graphics.off()
    mydev.off(fname)
  }
}

PlotX.Arena<-function(arena,range=c(0,0),WriteToPDF=TRUE){
  fname<-paste("./",arena$DataDir,"/",arena$Name,"_XPlots.pdf",sep="")
  tmp.list<-list()
  if(WriteToPDF==TRUE) {
    #pdf(fname,paper="USr",onefile=TRUE)
    mypdf(fname,res = 600, height = 9, width = 11, units = "in")
    par(mfrow=c(3,2))
  }
  for(i in 1:nrow(arena$Trackers)){
    tt<-arena$Trackers[i,]
    t<-Arena.GetTracker(arena,tt)
    PlotX(t,range)
  }
  if(WriteToPDF==TRUE){
    #graphics.off()
    mydev.off(fname)
  }
}

PlotY.Arena<-function(arena,range=c(0,0),WriteToPDF=TRUE){
  fname<-paste("./",arena$DataDir,"/",arena$Name,"_YPlots.pdf",sep="")
  tmp.list<-list()
  if(WriteToPDF==TRUE) {
    #pdf(fname,paper="USr",onefile=TRUE)
    mypdf(fname,res = 600, height = 9, width = 11, units = "in")
    par(mfrow=c(3,2))
  }
  for(i in 1:nrow(arena$Trackers)){
    tt<-arena$Trackers[i,]
    t<-Arena.GetTracker(arena,tt)
    PlotY(t,range)
  }
  if(WriteToPDF==TRUE){
    #graphics.off()
    mydev.off(fname)
  }
}

## Private Functions ##
rbind.missing <- function(A, B) { 
  A<-data.table(A)
  B<-data.table(B)
  cols.A <- names(A)
  cols.B <- names(B)
  
  missing.A <- setdiff(cols.B,cols.A)
  # check and define missing columns in A
  if(length(missing.A) > 0L){
    class.missing.A <- lapply(B[,missing.A,with = FALSE], class)
    nas.A <- lapply(class.missing.A, as, object = NA)
    A[,c(missing.A) := nas.A]
  }
  # check and define missing columns in B
  missing.B <- setdiff(names(A), cols.B)
  if(length(missing.B) > 0L){
    class.missing.B <- lapply(A[,missing.B,with = FALSE], class)
    nas.B <- lapply(class.missing.B, as, object = NA)
    B[,c(missing.B) := nas.B]
  }
  # reorder so they are the same
  setcolorder(B, names(A))
  tmp<-data.frame(rbind(A, B))
  tmp[is.na(tmp)]<-0
  tmp
  
  
}

multiplot <- function(..., plotlist = NULL, file, cols = 1, layout = NULL) {
  require(grid)
  
  plots <- c(list(...), plotlist)
  
  numPlots = length(plots)
  
  if (is.null(layout)) {
    layout <- matrix(seq(1, cols * ceiling(numPlots/cols)),
                     ncol = cols, nrow = ceiling(numPlots/cols))
  }
  
  if (numPlots == 1) {
    print(plots[[1]])
    
  } else {
    grid.newpage()
    pushViewport(viewport(layout = grid.layout(nrow(layout), ncol(layout))))
    
    for (i in 1:numPlots) {
      matchidx <- as.data.frame(which(layout == i, arr.ind = TRUE))
      
      print(plots[[i]], vp = viewport(layout.pos.row = matchidx$row,
                                      layout.pos.col = matchidx$col))
    }
  }
}

SmoothTransitions.Arena<-function(arena,minRun=1){
  for(i in 1:nrow(arena$Trackers)){
    tt<-arena$Trackers[i,]
    t<-Arena.GetTracker(arena,tt)
    t2<-SmoothTransitions(t)
    nm<-paste("Tracker",tt$TrackingRegion,tt$ObjectID,sep="_")
    arena[[nm]]<-t2
  }
  arena
}

AnalyzeTransitions.Arena<-function(arena,range=c(0,0),ShowPlot=TRUE){
  result<-list()
  for(i in 1:nrow(arena$Trackers)){
    tt<-arena$Trackers[i,]
    t<-Arena.GetTracker(arena,tt)
    result[[t$Name]]<-AnalyzeTransitions(t,range,ShowPlot)
  }
  result
}

PIPlots.Arena<-function(arena,range=c(0,0),WriteToPDF=TRUE){
  fname<-paste("./",arena$DataDir,"/",arena$Name,"_PIPlots.pdf",sep="")
  if(WriteToPDF==TRUE) {
    ##mypdf(fname,paper="letter",onefile=TRUE)
    mypdf(fname,res = 600, height = 11, width = 9, units = "in")
  }
  for(i in 1:nrow(arena$Trackers)){
    tt<-arena$Trackers[i,]
    t<-Arena.GetTracker(arena,tt)
    PIPlots(t,range)
  }
  if(WriteToPDF==TRUE){
    mydev.off(fname)
  }
}

PIPlots.ArenaCounter<-function(arena,range=c(0,0),WriteToPDF=TRUE){
  fname<-paste("./",arena$DataDir,"/",arena$Name,"_PIPlots.pdf",sep="")
  if(WriteToPDF==TRUE) {
    ##mypdf(fname,paper="letter",onefile=TRUE)
    mypdf(fname,res = 600, height = 11, width = 9, units = "in")
  }
  for(i in 1:nrow(arena$Trackers)){
    tt<-arena$Trackers[i,]
    t<-Arena.GetCounter(arena,tt)
    PIPlots(t,range)
  }
  if(WriteToPDF==TRUE){
    mydev.off(fname)
  }
}

UpdateDistanceCutoff.Arena<-function(arena,newcutoff.mm){
  for(i in 1:nrow(arena$Trackers)){
    t<-Arena.GetTracker(arena,arena$Trackers[i,])
    t<-UpdateDistanceCutoff(t,newcutoff.mm)
    nm<-paste("Tracker",t$Name,sep="_")
    arena[[nm]]<-t
  }
  arena
}

Arena.GetTracker<-function(arena,id){
  if(length(id)<2){
    tmp<-paste("Tracker_",id,sep="")  
  }
  else if(length(id)==2){
    if(id$ObjectID=="NA" || is.na(id$ObjectID)){
      tmp<-paste("Tracker_",id$TrackingRegion,sep="")
    }
    else {
      tmp<-paste("Tracker_",id$TrackingRegion,"_",id$ObjectID,sep="")
    }
  }
  else{
    tmp=""
  }
  arena[[tmp]]
}

## Plotting routines that use these functions take longer to make
## but render MUCH FASTER for pdf plots with  many points.
## See here for details.https://hopstat.wordpress.com/2014/04/
## They require ImageMagick installed: https://imagemagick.org/script/download.php#windows

mypdf = function(pdfname, mypattern = "MYTEMPPNG", ...) {
  fname = paste0(mypattern, "%05d.png")
  gpat = paste0(mypattern, ".*\\.png")
  takeout = list.files(path = tempdir(), pattern = gpat, full.names = TRUE)
  if (length(takeout) > 0) 
    file.remove(takeout)
  pngname = file.path(tempdir(), fname)
  png(pngname, ...)
  return(list(pdfname = pdfname, mypattern = mypattern))
}
# copts are options to sent to convert
mydev.off = function(pdfname, mypattern="MYTEMPPNG", copts = "") {
  dev.off()
  gpat = paste0(mypattern, ".*\\.png")
  pngs = list.files(path = tempdir(), pattern = gpat, full.names = TRUE)
  mystr = paste(pngs, collapse = " ", sep = "")
  pdfname<-paste(getwd(),"/",pdfname,sep="")
  pdfname<-paste("\"",pdfname,"\"",sep="")
  tmp<-(sprintf("magick convert %s -quality 100 %s %s", mystr, pdfname, copts))
  system(tmp)
}

Trim.Arena<-function(arena, matingtime_min, duration_min){
  for(i in 1:nrow(arena$Trackers)){
    tt<-arena$Trackers[i,]
    t<-Arena.GetTracker(arena,tt)
    tmp2 <- GetFirstRegionDuration.Tracker(t, matingtime_min)
    tmp2 <- tmp2[, 4]
    tmp3<-tmp2+duration_min
    t$RawData<-subset(t$RawData,t$RawData$Minutes>tmp2 & t$RawData$Minutes<=tmp3)
    if(nrow(t$RawData)<1){
      mess<-paste("**Warning! Tracker ",t$Name,"has no remaining data**\n")
      cat(mess)
    }
    if("TwoChoiceTracker" %in% class(t)){
      t$PIData<-subset(t$PIData,t$PIData$Minutes>tmp2 & t$PIData$Minutes<=tmp3)
    }
    nm<-paste("Tracker",t$ID$TrackingRegion,t$ID$ObjectID,sep="_")
    arena[[nm]]<-t
  }
  arena
}


ReportDuration.Arena<-function(arena){
  result<-data.frame(matrix(c(0,"None",0,0),nrow=1))
  names(result)<-c("ObjectID","TrackingRegion","StartTime","Duration")  
  index<-1
  for(j in 1:nrow(arena$Trackers)){
      tt<-arena$Trackers[j,]
      t<-Arena.GetTracker(arena,tt)
      tmp<-t$RawData
      if(nrow(tmp)<2) {
        start<-NA
        duration<-NA
      }
      else {
        start<-tmp$Minutes[1]
        duration<-tmp$Minutes[length(tmp$Minutes)]-start
      }
      result[index,]<-c(arena$Trackers$ObjectID[j],arena$Trackers$TrackingRegion[j],start,duration)
      index<-index+1
    }  
  result
}

