source("./Code/GeneralUtility.R")
require(data.table)
require(reshape2)
require(readxl)
require(tibble)
require(plyr)
require(dplyr)
require(tidyr)

## Private Functions
PairwiseInteractionTracker.ProcessPairwiseInteractionTracker <- function(tracker) {
  if (!is.null(tracker$ExpDesign)) {
    a <- "ObjectID" %in% colnames(tracker$ExpDesign)
    b <- "TrackingRegion" %in% colnames(tracker$ExpDesign)
    c <- "CountingRegion" %in% colnames(tracker$ExpDesign)
    d <- "Treatment" %in% colnames(tracker$ExpDesign)
    f <- c(a, b, c, d)
    if (sum(f) < 4) {
      stop(
        "Experimental design file requires ObjectID,TrackingRegion, CountingRegion, PiMult, and Treatments columns."
      )
    }
  }
  tracker <- PairwiseInteractionTracker.GetNeighborDistance(tracker)
  class(tracker) <- c("PairwiseInteractionTracker", class(tracker))
  tracker
}


PairwiseInteractionTracker.GetNeighborDistance<-function(tracker){
  tmp<-tracker$RawData$ClosestNeighbor*tracker$Parameters$mmPerPixel
  
  tmp[tracker$RawData$DataQuality!="High"]<- (-1)
  tmp[tracker$RawData$ClosestNeighbor==-1]<- (-1)
  
  tracker$RawData$IsNeighborFound<-tracker$RawData$ClosestNeighbor >= 0
  
  tracker$RawData$ClosestNeighbor_mm <- tmp
  
  tracker$RawData$IsInteracting <-(tmp<=tracker$Parameters$Interaction.Distance.mm) & (tmp >= 0)
  
  tracker
}

Summarize.PairwiseInteractionTracker <- function(tracker,
                              range = c(0, 0),
                              ShowPlot = TRUE) {
  rd <- Tracker.GetRawData(tracker, range)
 
  ## Now get the summary on the rest
  total.min <- rd$Minutes[nrow(rd)] - rd$Minutes[1]
  total.frames<-sum(rd$IsNeighborFound)
  total.frames.interacting<-sum(rd$IsInteracting)
  perc.interacting<-total.frames.interacting/total.frames
  total.dist <-
    (rd$TotalDistance[nrow(rd)] - rd$TotalDistance[1]) * tracker$Parameters$mmPerPixel
  perc.Sleeping <- sum(rd$Sleeping) / length(rd$Sleeping)
  perc.Walking <- sum(rd$Walking) / length(rd$Walking)
  perc.MicroMoving <- sum(rd$MicroMoving) / length(rd$MicroMoving)
  perc.Resting <- sum(rd$Resting) / length(rd$Resting)
  
  avg.speed <- mean(rd$Speed_mm_s)
  
  regions <- tracker$CountingROI
  r.tmp <- matrix(rep(-1, length(regions)), nrow = 1)
  for (i in 1:length(r.tmp)) {
    r.tmp[1, i] <- sum(rd$CountingRegion == regions[i])
  }
  
  results <-
    data.frame(
      tracker$ID,
      total.min,
      total.dist,
      perc.Sleeping,
      perc.Walking,
      perc.MicroMoving,
      perc.Resting,
      avg.speed,
      range[1],
      range[2],
      total.frames,
      total.frames.interacting,
      perc.interacting,
      r.tmp
    )
  names(results) <-
    c(
      "ObjectID",
      "TrackingRegion",
      "ObsMinutes",
      "TotalDist_mm",
      "PercSleeping",
      "PercWalking",
      "PercMicroMoving",
      "PercResting",
      "AvgSpeed_mm_s",
      "StartMin",
      "EndMin",
      "TotalPairedFrames",
      "TotalFramesInteracting",
      "PercentInteracting",
      regions
    )
  
  if (ShowPlot) {
    tmp <-
      data.frame(
        c(
          results$PercWalking,
          results$PercMicroMoving,
          results$PercResting,
          results$PercSleeping
        ),
        rep("one", 4),
        factor(c(
          "Walking", "MicroMoving", "Resting", "Sleeping"
        ))
      )
    names(tmp) <- c("a", "b", "Movement")
    print(
      qplot(
        x = b,
        y = a,
        data = tmp,
        fill = (Movement)
      ) + geom_bar(stat = "identity") + xlab("Treatment") + ylab("Percentage")
    )
  }
  
  results
}


GetAverageNeighborDistance.PairwiseInteractionTracker <- function(arena,dirname) {
  trackers.to.get <- arena$Trackers[arena$Trackers$ObjectID == 0, ]
  
  tmp <- Arena.GetTracker(arena, trackers.to.get[1, ])
  results <- data.frame(tmp$RawData[, c("Minutes", "ClosestNeighbor_mm")])
  names(results) <- c("Minutes", tmp$Name)
  
  if (nrow(trackers.to.get) > 1) {
    for (i in 2:nrow(trackers.to.get)) {
      tmp <- Arena.GetTracker(arena, trackers.to.get[i, ])
      assign(tmp$Name, tmp$RawData$ClosestNeighbor_mm)
      results <- data.frame(results, tmp$Name)
    }
  }
  
 ## Todo: need to finish this
}

UpdateDistanceCutoff.PairwiseInteractionTracker <- function(tracker, newcutoff.mm) {
  tracker$Parameters$Interaction.Distance.mm<-newcutoff.mm
  tmp <-
    tracker$RawData$ClosestNeighbor_mm <= newcutoff.mm
  
  tracker$RawData$IsInteracting <- tmp & tracker$RawData$IsNeighborFound
  tracker
}

Plot.PairwiseInteractionTracker<-function(tracker,range = c(0, 0)){
  id<-tracker$RawData
  x <- ggplot(id, aes(Frame, ClosestNeighbor_mm, color = IsInteracting)) +
    geom_point() +
    ggtitle(paste("Tracker:", tracker$Name, sep =
                    "")) +
    geom_smooth(method="auto", se=TRUE, fullrange=FALSE, level=0.95) +
    xlab("Frame") + ylab("Distance (mm)")
  print(x)
  
}

## Functions that just catch misapplied higher functions
FinalPI.PairwiseInteractionTracker<-function(tracker){
  cat("This function not available for this type of tracker")
}
CumulativePI.PairwiseInteractionTracker<-function(tracker){
  cat("This function not available for this type of tracker")
}
GetPIData.PairwiseInteractionTracker<-function(tracker,range=c(0,0)){
  cat("This function not available for this type of tracker")
}
PIPlots.PairwiseInteractionTracker<-function(tracker,range=c(0,0)){
  cat("This function not available for this type of tracker")
}
TimeDependentPIPlots.PairwiseInteractionTracker<-function(tracker,range=c(0,0)){
  cat("This function not available for this type of tracker")
}

PlotDistanceFromCenter.PairwiseInteractionTracker <- function(tracker) {
  cat("This function not available for this type of tracker")
}