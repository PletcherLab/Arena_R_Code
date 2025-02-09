CentrophobismTracker.ProcessCentrophobismTracker <- function(tracker) {
  if (!is.null(tracker$ExpDesign)) {
    a <- "ObjectID" %in% colnames(tracker$ExpDesign)
    b <- "TrackingRegion" %in% colnames(tracker$ExpDesign)
    c <- "Treatment" %in% colnames(tracker$ExpDesign)
    d <- c(a, b, c)
    if (sum(d) < 3) {
      stop(
        "Experimental design file requires ObjectID,TrackingRegion, and Treatments columns."
      )
    }
  }
  tracker <- CentrophobismTracker.SetCentrophobismData(tracker)
  class(tracker) <- c("CentrophobismTracker", class(tracker))
  tracker
}

Get.Center.Distance<-function(RelX, RelY, CenterPoint){
  
}

Get.Wall.Distances<-function(RelX,RelY,walls){
  
  ## x is one row of wall data
  ## walls is a four element vector of left, right, top, bottom, wall values.
  a<-abs(RelX-walls[1])
  b<-abs(RelX-walls[2])
  c<-abs(RelY-walls[3])
  d<-abs(RelY-walls[4])

  tmp<-cbind(a,b,c,d)
  result<-apply(tmp,1,min)
  result
}

CentrophobismTracker.SetCentrophobismData<-function(tracker){
  ## Get the rel x coordinates of right and left walls
  tmp<-tracker$ROI[1]/2
  x.left<-(-1.0)*tmp
  x.right<-tmp
  
  tmp<-tracker$ROI[2]/2
  y.top<-(-1.0)*tmp
  y.bottom<-tmp
  
  walls<-c(x.left,x.right,y.top,y.bottom)
  
  tracker$RawData<-tracker$RawData%>% mutate(WallDist_mm=Get.Wall.Distances(RelX,RelY,walls), CenterDist_mm=sqrt(RelX*RelX+RelY*RelY))
  
  tracker$RawData$WallDist_mm<-tracker$RawData$WallDist_mm*tracker$Parameters$mmPerPixel
  tracker$RawData$CenterDist_mm<- tracker$RawData$CenterDist_mm*tracker$Parameters$mmPerPixel
  
  tracker
  
  
}

PlotXY.CentrophobismTracker <-
  function(tracker,
           range = c(0, 0),
           ShowQuality = FALSE,
           PointSize = 0.75,
           UseCenterDistance=TRUE) {
    rd <- Tracker.GetRawData(tracker, range)
    
    xlim <- c(min(rd$RelX), max(rd$RelX))
    ylim <- c(min(rd$RelY), max(rd$RelY))
    ylim2 <- c(max(rd$RelY), min(rd$RelY))
    
    
    if (ShowQuality == FALSE) {
      tmp2 <- rep("Moving", length(rd$RelX))
      tmp2[rd$Sleeping] <- "Sleeping"
      tmp2[rd$Resting] <- "Resting"
      tmp2[rd$MicroMoving] <- "Micromoving"
    }
    else {
      tmp2 <- rep("HighQuality", length(rd$RelX))
      tmp2[rd$DataQuality != "High"] <- "LowQuality"
    }
    Movement <- factor(tmp2)
    xlims <-
      c(tracker$ROI[1] / -2, tracker$ROI[1] / 2) * tracker$Parameters$mmPerPixel
    ylims <-
      c(tracker$ROI[2] / -2, tracker$ROI[2] / 2) * tracker$Parameters$mmPerPixel
    
    if(UseCenterDistance==TRUE){
      x <- ggplot(rd, aes(Xpos_mm, Ypos_mm, color = CenterDist_mm)) +
        geom_point() +
        coord_fixed() +
        ggtitle(paste("Tracker:", tracker$Name, sep =
                        "")) +
        xlab("XPos (mm)") + ylab("YPos (mm)") + xlim(xlims) +
        ylim(ylims)  
    }
    else {
      x <- ggplot(rd, aes(Xpos_mm, Ypos_mm, color = WallDist_mm)) +
        geom_point() +
        coord_fixed() +
        ggtitle(paste("Tracker:", tracker$Name, sep =
                        "")) +
        xlab("XPos (mm)") + ylab("YPos (mm)") + xlim(xlims) +
        ylim(ylims)
    }
    print(x)
  }

Summarize.CentrophobismTracker<-function(tracker,range=c(0,0),ShowPlot=TRUE){  
  rd <- Tracker.GetRawData(tracker, range)
  
  ## Now get the summary on the rest
  total.min <- rd$Minutes[nrow(rd)] - rd$Minutes[1]
  total.frames<-nrow(rd)
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
  
  AvgWallDist<-mean(rd$WallDist_mm)
  perc.WallDist_2mm<-sum(rd$WallDist_mm<2.0)/length(rd$WallDist_mm)
  perc.WallDist_5mm<-sum(rd$WallDist_mm<5.0)/length(rd$WallDist_mm)
  perc.WallDist_10mm<-sum(rd$WallDist_mm<10.0)/length(rd$WallDist_mm)
  perc.WallDist_15mm<-sum(rd$WallDist_mm<15.0)/length(rd$WallDist_mm)
  
  AvgCenterDist<-mean(rd$CenterDist_mm)
  perc.CenterDist_2mm<-sum(rd$CenterDist_mm>2.0)/length(rd$CenterDist_mm)
  perc.CenterDist_5mm<-sum(rd$CenterDist_mm>5.0)/length(rd$CenterDist_mm)
  perc.CenterDist_10mm<-sum(rd$CenterDist_mm>10.0)/length(rd$CenterDist_mm)
  perc.CenterDist_15mm<-sum(rd$CenterDist_mm>15.0)/length(rd$CenterDist_mm)
  
  
  treatment<-NA
  if(is.null(tracker$ExpDesign)==FALSE){
  if(nrow(tracker$ExpDesign)==1){
    treatment<-tracker$ExpDesign$Treatment[1]
  }
  }
  
  
  results <-
    data.frame(
      tracker$ID,
      treatment,
      total.min,
      total.dist,
      AvgCenterDist,
      perc.CenterDist_2mm,
      perc.CenterDist_5mm,
      perc.CenterDist_10mm,
      perc.CenterDist_15mm,
      AvgWallDist,
      perc.WallDist_2mm,
      perc.WallDist_5mm,
      perc.WallDist_10mm,
      perc.WallDist_15mm,
      perc.Sleeping,
      perc.Walking,
      perc.MicroMoving,
      perc.Resting,
      avg.speed,
      range[1],
      range[2],
      total.frames,
      r.tmp
    )
  names(results) <-
    c(
      "ObjectID",
      "TrackingRegion",
      "Treatment",
      "ObsMinutes",
      "TotalDist_mm",
      "MeanCenterDist_mm",
      "PercCenterDist2mm",
      "PercCenterDist5mm",
      "PercCenterDist10mm",
      "PercCenterDist15mm",
      "MeanWallDist_mm",
      "PercWallDist2mm",
      "PercWallDist5mm",
      "PercWallDist10mm",
      "PercWallDist15mm",
      "PercSleeping",
      "PercWalking",
      "PercMicroMoving",
      "PercResting",
      "AvgSpeed_mm_s",
      "StartMin",
      "EndMin",
      "TotalFrames",
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


PlotDistanceFromCenter.CentrophobismTracker <-
  function(tracker,
           range = c(0, 0),
           ShowQuality = FALSE) {
    rd <- Tracker.GetRawData(tracker, range)
    if (ShowQuality == FALSE) {
      tmp2 <- rep("Moving", length(rd$RelX))
      tmp2[rd$Sleeping] <- "Sleeping"
      tmp2[rd$Resting] <- "Resting"
      tmp2[rd$MicroMoving] <- "Micromoving"
    }
    else {
      tmp2 <- rep("HighQuality", length(rd$RelX))
      tmp2[rd$DataQuality != "High"] <- "LowQuality"
    }
    
  
    
    Movement <- factor(tmp2)
    
    x <- ggplot(rd, aes(Minutes, CenterDist_mm),
                xlab = "Minutes", ylab = "Distance From Center (mm)") +  ggtitle(paste("Tracker:", tracker$Name, sep =
                                                                                   "")) +
      geom_rect(
        aes(
          xmin = Minutes,
          xmax = dplyr::lead(Minutes, default = 0),
          ymin = -Inf,
          ymax = Inf,
          fill = factor(Indicator)
        ),
        show.legend = F
      ) +
      scale_fill_manual(values = alpha(c("gray", "red", "red"), .07)) +
      geom_line(aes(group = 1, color = Movement), linewidth = 2) + ylab("Distance From Center (mm))") + geom_smooth(method = "loess", color="Purple")
    print(x)
  }