source("ParametersClass.R")
source("PairwiseInteractionCounter.R")
source("SocialDistanceCounter.R")
source("TwoChoiceCounter.R")

CounterClass.RawDataFrame <-
  function(id,
           parameters,
           data,
           roisize,
           theCountingROI,
           expDesign) {
    tmp <- data
    tmp <-
      subset(tmp,tmp$TrackingRegion == id$TrackingRegion)
    tmp <- droplevels(tmp)
    
    if (is.na(parameters$FPS)) {
      ## Transform the mSec so that the first observation is 0
      ## Well, maybe not.  Definitely not for DDrop, probably
      ## not for other applications.  I'll comment it out for now.
      ##tmp$MSec<-tmp$MSec - tmp$MSec[1]
      Minutes <- tmp$MSec / (1000 * 60)
    }
    else {
      min.per.frame = 1.0 / (parameters$FPS * 60)
      Minutes <- tmp$Frame*min.per.frame
    }
    
    tmp <- data.frame(tmp, Minutes)
    tmp$CountingRegion <- factor(tmp$CountingRegion)
    tmp$DataQuality <- factor(tmp$DataQuality)
    
    Xpos_mm <- tmp$RelX * parameters$mmPerPixel
    Ypos_mm <- tmp$RelY * parameters$mmPerPixel
    
    tmp<-data.frame(tmp,Xpos_mm,Ypos_mm)
    
    if (!is.null(expDesign)) {
      expDesign<-subset(expDesign,expDesign$TrackingRegion == id$TrackingRegion)      
    }
    name<-paste(id$TrackingRegion)
    #name<-paste(id)
    data = list(
      ID = id,
      Name=name,
      ROI = roisize,
      CountingROI = theCountingROI,
      Parameters = parameters,
      RawData = tmp,
      ExpDesign = expDesign
    )
    class(data) = "Counter"
    if (parameters$TType == "PairwiseInteractionCounter") {
      data <- PairwiseInteractionCounter.ProcessPairwiseInteractionCounter(data)
    }
    else if (parameters$TType == "SocialDistanceCounter") {
      data <- SocialDistanceCounter.ProcessSocialDistanceCounter(data)
    }
    else if (parameters$TType == "TwoChoiceCounter") {
      data <- TwoChoiceCounter.ProcessTwoChoiceCounter(data)
    }
    else if(parameters$TType == "Counter"){
      
    }
    else{
      stop("Improper tracker type!")
    }
    
    data
  }


Counter.GetRawData <- function(counter, range = c(0, 0)) {
  rd <- counter$RawData
  if (sum(range) != 0) {
    rd <- rd[(rd$Minutes > range[1]) & (rd$Minutes < range[2]), ]
  }
  rd
}

PlotXY.Counter <-
  function(counter,
           range = c(0, 0),
           ShowQuality = FALSE,
           PointSize = 0.75) {
    rd <- Counter.GetRawData(counter, range)
    
    xlim <- c(min(rd$RelX), max(rd$RelX))
    ylim <- c(min(rd$RelY), max(rd$RelY))
    ylim2 <- c(max(rd$RelY), min(rd$RelY))
    
    xlims <-
      c(counter$ROI[1] / -2, counter$ROI[1] / 2) * counter$Parameters$mmPerPixel
    ylims <-
      c(counter$ROI[2] / -2, counter$ROI[2] / 2) * counter$Parameters$mmPerPixel
    x <- ggplot(rd, aes(Xpos_mm, Ypos_mm)) +
      geom_point() +
      coord_fixed() +
      ggtitle(paste("Counter:", counter$Name, sep =
                      "")) +
      xlab("XPos (mm)") + ylab("YPos (mm)") + xlim(xlims) +
      ylim(ylims)
    print(x)
  }

PlotX.Counter <- function(counter, range = c(0, 0)) {
  rd <- Counter.GetRawData(counter, range)
  
  ylims <-
    c(counter$ROI[1] / -2, counter$ROI[1] / 2) * counter$Parameters$mmPerPixel
  print(
    ggplot(rd, aes(Minutes, Xpos_mm),
           xlab = "Minutes", ylab = "XPos (mm)") +  ggtitle(paste("Counter:", counter$Name, sep =
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
      scale_fill_manual(values = alpha(c("gray", "red", "green"), .07)) +
      geom_line(aes(group = 1), size = 2) + ylim(ylims)
  )
  
}

PlotY.Counter <- function(counter, range = c(0, 0)) {
  rd <- Counter.GetRawData(counter, range)
  ylims <-
    c(counter$ROI[2] / -2, counter$ROI[2] / 2) * counter$Parameters$mmPerPixel
  if(is.null(counter$ExpDesign)){
    title<-paste("Counter:", counter$Name, sep ="")
  }
  else{
    title<-paste("Counter: ", counter$Name, "  Treatment: ",counter$ExpDesign$Treatment[1],sep ="")
  }
  print(
    ggplot(rd, aes(Minutes, Ypos_mm),
           xlab = "Minutes", ylab = "YPos (mm)") +  ggtitle(title) +
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
      scale_fill_manual(values = alpha(c("gray", "red","green"), .07)) +
      geom_line(aes(group = 1), size = 2) + ylim(ylims)
  )
}
