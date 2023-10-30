require(data.table)
require(reshape2)
require(readxl)
require(tibble)
require(plyr)
require(dplyr)
require(tidyr)

PairwiseInteractionCounter.ProcessPairwiseInteractionCounter<-function(counter){
  if (!is.null(counter$ExpDesign)) {
    a <- "TrackingRegion" %in% colnames(counter$ExpDesign)
    b <- "Treatment" %in% colnames(counter$ExpDesign)
    f <- c(a, b)
    if (sum(f) < 2) {
      stop(
        "Experimental design file requires TrackingRegion and Treatments columns."
      )
    }
  }
  counter <- PairwiseInteractionCounter.SetInteractionData(counter)
  class(counter) <- c("PairwiseInteractionCounter", class(counter))
  counter
}

PairwiseInteractionCounter.SetInteractionData<-function(counter) {
  SubFunction<-function(a){
    result<-NA
    if(sum(a$NObjects)==2){
      if(length(a$RelX)==1){
        result<-0
      }
      else if(length(a$RelX)>2){
        a<-a[a$NObjects>0,]
        diffx <- diff(a$RelX)
        diffy <- diff(a$RelY)
        d <- sqrt(diffx * diffx + diffy * diffy)
        result<-d
      }
      else {
        diffx <- diff(a$RelX)
        diffy <- diff(a$RelY)
        d <- sqrt(diffx * diffx + diffy * diffy)
        result<-d
      }
    }
    result
  }
  theData<-counter$RawData
  p<-counter$Parameters
  
  counts<-theData %>% group_by(Frame) %>% mutate(ClosestNeighbor=SubFunction(cur_data())) %>% summarise(ClosestNeighbor = mean(ClosestNeighbor), Objects = sum(NObjects))
  IsNeighborFound<-counts$Objects==2
  counts<-data.frame(counts,IsNeighborFound)
  
  ClosestNeighbor_mm<-counts$ClosestNeighbor*p$mmPerPixel
  ClosestNeighbor_mm[!IsNeighborFound]<-(-1)
  IsInteracting<-ClosestNeighbor_mm<=p$Interaction.Distance.mm
  IsInteracting[!IsNeighborFound]<-FALSE
  
  counts<-data.frame(counts,ClosestNeighbor_mm,IsInteracting)
  names(counts) <- c("Frame", "ClosestNeighbor","Objects","IsNeighborFound","ClosestNeighbor_mm","IsInteracting")
  
  
  missings <-
    length(which(!(seq(
      min(counts$Frame), max(counts$Frame)
    ) %in% counts$Frame)))
  ones <- sum(counts$Objects == 1)
  twos <- sum(counts$Objects == 2)
  more <- sum(counts$Objects > 2)
  
  frequencies <- c(missings, ones, twos, more)
  names(frequencies) <- c("Zero", "One", "Two", "More")
  
  print(" ")
  print(paste("Tracking region:",counter$Name))
  print(paste(sum(counts$IsNeighborFound),"frames found with single neighbors."))
  print(" ")
  
  counter$InteractionData<-list(Frequencies = frequencies, Results = counts)
  counter
}

Summarize.PairwiseInteractionCounter<-function(counter,range=c(0,0),ShowPlot=TRUE){
  rd<-InteractionCounter.GetInteractionData(counter,range) 
  if(sum(range)!=0){
    ff<-PairwiseInteractionCounter.GetFrameCounts(counter,range)
  }
  else {
    ff<-counter$InteractionData$Frequencies
  }
  interacting<-rd[rd$IsInteracting==TRUE,]
  notinteracting<-rd[rd$IsInteracting==FALSE,]
  
  results<-data.frame(counter$ID$TrackingRegion,counter$Parameters$Interaction.Distance.mm,sum(rd$IsInteracting),sum(rd$IsInteracting==FALSE),sum(rd$IsInteracting)/length(rd$IsInteracting),ff[1],ff[2],ff[3],ff[4],ff[3]/(sum(ff)),
                      range[1],range[2])
  names(results)<-c("TrackingRegion","IDistance","FramesInteracting","FramesNotInteracting","PercentInteraction","Zero","One","Two","More","PercTwo","StartMin","EndMin")
  rownames(results)<-1:nrow(results)
  results
}

UpdateDistanceCutoff.PairwiseInteractionCounter <- function(tracker, newcutoff.mm) {
  tracker$Parameters$Interaction.Distance.mm<-newcutoff.mm
  tracker$InteractionData$Results$IsInteracting <-
    tracker$InteractionData$Results$ClosestNeighbor_mm <= newcutoff.mm
  tracker$InteractionData$Results$IsInteracting[!tracker$InteractionData$Results$IsNeighborFound]<-FALSE
  tracker
}

PairwiseInteractionCounter.GetFrameCounts<-function(counter, range=c(0,0)) {
  library(dplyr, warn.conflicts = FALSE)
  
  # Suppress summarise info
  options(dplyr.summarise.inform = FALSE)
  theData<-Tracker.GetRawData(counter,range)
  p<-counter$Parameters
  counts <-
    theData %>% group_by(Frame) %>% summarise(Objects = sum(NObjects))
  missings <-
    length(which(!(seq(
      min(counts$Frame), max(counts$Frame)
    ) %in% counts$Frame)))
  ones <- sum(counts$Objects == 1)
  twos <- sum(counts$Objects == 2)
  more <- sum(counts$Objects > 2)
  
  frequencies <- c(missings, ones, twos, more)
  names(frequencies) <- c("Zero", "One", "Two", "More")
  frequencies
}

InteractionCounter.GetInteractionData <- function(counter, range = c(0, 0)) {
  rd <- counter$InteractionData$Results
  if (sum(range) != 0) {
    rd <- rd[(rd$ElapsedTimeMin > range[1]) & (rd$ElapsedTimeMin < range[2]), ]
  }
  rd
}

Plot.PairwiseInteractionCounter<-function(counter,range = c(0, 0)){
  id<-counter$InteractionData$Results
  x <- ggplot(id, aes(Frame, ClosestNeighbor_mm, color = IsInteracting)) +
    geom_point() +
    ggtitle(paste("Counter:", counter$Name, sep =
                    "")) +
    geom_smooth(method="auto", se=TRUE, fullrange=FALSE, level=0.95) +
    xlab("Frame") + ylab("Distance (mm)")
  print(x)
  
}



###################################
## Still need to be incorporated

GetBinnedInteractionTime <- function(results, binsize.min = 10) {
  et <- as.numeric(results$Results$ElapsedTimeMin)
  
  y <- seq(min(et), max(et), by = binsize.min)
  
  tmpMatrix <- cbind(y[-length(y)], y[-1])
  intervals <- cut(y + 0.000001,
                   y,
                   include.lowest = TRUE,
                   dig.lab = 8)
  intervals <- intervals[-length(intervals)]
  midpoint <- (tmpMatrix[, 1] + tmpMatrix[, 2]) / 2
  intDuration <- rep(NA, nrow(tmpMatrix))
  percDuration <- rep(NA, nrow(tmpMatrix))
  result <-
    data.frame(intervals,
               tmpMatrix[, 2] - tmpMatrix[, 1],
               midpoint,
               tmpMatrix,
               intDuration,
               percDuration)
  names(result) <-
    c(
      "Interval",
      "Duration",
      "MidPoint",
      "Start",
      "End",
      "InteractionTime",
      "PercentageInteraction"
    )
  for (i in 1:nrow(result)) {
    indexer <- (results$Results$ElapsedTimeMin > result$Start[i]) &
      (results$Results$ElapsedTimeMin <= result$End[i]) &
      (results$Results$IsInteracting == TRUE)
    tmpData <- subset(results$Results, indexer)
    result$InteractionTime[i] <- sum(tmpData$DiffTimeMin)
    result$PercentageInteraction[i] <-
      result$InteractionTime[i] / result$Duration[i]
  }
  result
}

## Functions that just catch misapplied higher functions
FinalPI.PairwiseInteractionCounter<-function(tracker){
  cat("This function not available for this type of tracker")
}
CumulativePI.PairwiseInteractionCounter<-function(tracker){
  cat("This function not available for this type of tracker")
}
GetPIData.PairwiseInteractionCounter<-function(tracker,range=c(0,0)){
  cat("This function not available for this type of tracker")
}
PIPlots.PairwiseInteractionCounter<-function(tracker,range=c(0,0)){
  cat("This function not available for this type of tracker")
}
TimeDependentPIPlots.PairwiseInteractionCounter<-function(tracker,range=c(0,0)){
  cat("This function not available for this type of tracker")
}
