
## Note, high density and PI plots require ImageMagik to be installed for 
## simpler PDF outputs.
## Get it here: https://imagemagick.org/script/download.php#windows
## Also required are the following packages: ggplot2, markovchain, Gmisc, 
##  data.table, reshape2, readxl, tibble, stringr, readr


rm(list=ls())
## Do one of the following two
source("./Code/ArenaObject.R")

## Always put this here to remove any old variables
CleanTrackers()

## First make a parameter class
## You can define a generic tracker
p<-ParametersClass.CentrophobismTracker()

## If you are analyzing a movie, then you need to specify the FPS
## that was used when the movie was recorded!
## If your data were collected with a live (i.e., FLIR) camera,
## then FPS should remain NA because the interframe time is 
## saved in the output file by DTrack.
p<-Parameters.SetParameter(p,FPS=10)

## Check out the parameters and ensure that they are appropriate.
## Notably, make sure the mmPerPixel value is correct for your setup.
## Note that sleep is not currently implemented.

## This value is for the new CCD camera setup
mm.per.pixel<-0.15
p<-Parameters.SetParameter(p,mmPerPixel=mm.per.pixel)

## change parameters as you need
##p<-SetParameter(p,Filter.Sleep=1)
##p<-SetParameter(p,Filter.Tracker.Error=`1)

## Place your tracking data and the experiment file in a subdirectory.
## If you name it something other than 'Data' you need to supply it as
## a parameter to the ArenaClass function

arena<-ArenaClass(p,dirname="Data/CentrophobismData")

## Basic movement information and region summaries can be obtained from
Summarize(arena)
## By default a summary output pdf files is produces as well (this can be turned off).

## Currently (9/18/2023) this code requires the tracking region to be square to get distances
## from the wall

## To extract a specific chamber from the experiment
tracker<-Arena.GetTracker(arena,3)

## To plot position information use PlotX for either 
## the arena or a specific tracker. If you pass an arena object
## the output is sent to a pdf file by default (can be changed)
## but if you send a tracker it is not.
PlotXY(arena)

