# (c) 2015 Jörn Dinkla, www.dinkla.com 
#
# R code for some diagrams for the lbnn app
# 
# Installation instructions:
#
# This file depends on the packages ggplot2 and ggmap.
#
# $ install.packages(c("ggplot2", "ggmap"))
#
# for pretty fonts the following extra package is needed
#
# $ install.packages("extrafont")
#
# you have to import all the windows fonts with
#
# $ library(extrafont)
# $ font_import()
#
# but warning: this may take a while
#
# see http://blog.revolutionanalytics.com/2012/09/how-to-use-your-favorite-fonts-in-r-charts.html
# and http://www.r-bloggers.com/change-fonts-in-ggplot2-and-create-xkcd-style-graphs/
#
# ---------------------------------------------------------------------
#
# ggmap was published in
#   D. Kahle and H. Wickham. ggmap: Spatial Visualization with ggplot2. The R Journal,
#   5(1), 144-161. URL http://journal.r-project.org/archive/2013-1/kahle-wickham.pdf
#
#   @Article{,
#     author = {David Kahle and Hadley Wickham},
#     title = {ggmap: Spatial Visualization with ggplot2},
#     journal = {The R Journal},
#     year = {2013},
#     volume = {5},
#     number = {1},
#     pages = {144--161},
#     url = {http://journal.r-project.org/archive/2013-1/kahle-wickham.pdf},
#   }

setwd("C:/workspace/location-based-nearest-neighbours/temp")

use_hdfs <- FALSE

library(ggplot2)
library(ggmap)
library(extrafont)

if (use_hdfs) {
    library(rhdfs)
}

lbnn_init <- function() {
#font_import()
	loadfonts()
#	loadfonts(device="win")
}


	# if (use_hdfs) {
	# 	rs <- NULL
	# } else {
	# 	rs <- read.csv(file=filename, header=TRUE, sep=";")
	# }
	# rs


#
# Definitions
#

dinkla_blue <- "#1E2D5B"
dinkla_dark_blue <- "#0F162E"
dinkla_red <- "#AF0A14"
font_family <- "Verdana"

export_width <- 3820
export_height <- 2160

#
# auxiliary functions 
#

# convert a string to a date
# see http://stackoverflow.com/questions/16402064/problems-formatting-date-into-format-y-m
yyyymm_as_date <- function(xs) {
	as.Date(paste(xs, "01", sep=""), format="%Y%m%d")
}

# convert a string to a date
yyyymmdd_as_date <- function(xs) {
	as.Date(xs, format="%Y%m%d")
}

# read a csv file with a text key and numeric values
read_textkey_value <- function(file, n=1) {
	read.csv(file=file, header=TRUE, sep=";", colClasses=c("character",rep("numeric", n)))
}

# create a color from 'color'
mk_color <- function(color,alpha) {
	v <- col2rgb(color)
	rgb(v[1]/255, v[2]/255, v[3]/255, alpha)
}

# create a palette from 'color'
mk_palette <- function(color, n = 10, alpha_start = 0.1, alpha_end = 0.9) {
	v <- col2rgb(color)
	w <- v/255.0
	alpha_width <- alpha_end - alpha_start
	alpha_delta <- alpha_width / n
	alphas <- seq(alpha_start, alpha_end, alpha_delta)
	f <- function(alpha) {
		rgb(w[1], w[2], w[3], alpha)
	}
	mapply(f, alphas)
}

export <- function(filename) {
  png(filename, width=export_width, height=export_height, units="px")
}

#
# sums_hh: checkins per hour 
#
# displayed in a pie chart
#

sums_hh <- read_textkey_value(file="sums_hh.csv")

chart_hh <- function(scale=1) {
  
  # here pie is used, not a ggplot2 function
  size_cex <- 1 * scale
  size_cex_main <- 2.5 * scale

	vs <- sums_hh$value
	cs <- mk_palette(dinkla_blue, length(vs), 0.5, 0.95)
	ls <- sums_hh$hh
	pct <- round(vs/sum(vs)*100)
	ls <- paste(paste(ls, pct, sep="\n"), "%", sep="")
	pie(vs, col=cs, labels=ls, clockwise=TRUE, border=NULL, main="Number of checkins during the day", family="Verdana", col.main=dinkla_red, col.lab=dinkla_dark_blue, cex=size_cex, cex.main=size_cex_main, mai=c(15, 4, 4, 2) + 10.1, lheight=10)
}

export_hh <- function() {
  export("lbnn_piechart.png")
  chart_hh(2.15)
  dev.off()
}

#
# sums_ym: checkins per month
#
# displayed in a bar chart
#

sums_ym <- read_textkey_value(file="sums_yyyymm.csv")
sums_ym$yyyymm <- yyyymm_as_date(sums_ym$yyyymm)

chart_ym <- function(scale = 1) {

	size_small <- 12 * scale
	size_middle <- 16 * scale
	size_large <- 24 * scale

	p <- ggplot(sums_ym, aes(x=yyyymm, y=value)) + 
			geom_bar(stat="identity", fill=dinkla_blue, color=dinkla_blue) + 
			theme(
				panel.background = element_rect(fill=mk_color(dinkla_blue, 0.1)),
				panel.grid.major.x = element_blank(),
    		    panel.grid.minor.x = element_blank()
    		) +
			ggtitle("Number of check-ins per month in the loc-gowalla dataset") +
   			xlab("Month") + ylab("Number of check-ins")  +
			theme(
			axis.title.x=element_text(size=size_middle, family=font_family, lineheight=.9, colour=dinkla_red),
			axis.text.x=element_text(size=size_small, color=dinkla_blue, family=font_family),
			axis.title.y=element_text(size=size_middle, family=font_family, lineheight=.9, colour=dinkla_red),
			axis.text.y=element_text(size=size_small, color=dinkla_blue, family=font_family),
			plot.title=element_text(size=size_large, color=dinkla_red, family=font_family)
			)
   	p
}

#
# sums_ymd: checkins per day
#
# displayed in a line graph
#

sums_ymd <- read_textkey_value(file="sums_yyyymmdd.csv")
sums_ymd$yyyymmdd <- yyyymmdd_as_date(sums_ymd$yyyymmdd)

chart_ymd <- function(scale = 1) {

	size_small <- 12 * scale
	size_middle <- 16 * scale
	size_large <- 24 * scale

	a <- sums_ymd
	#a$smoothed <- as.vector(smooth(a$value, ))
	a$smoothed <- filter(a$value, rep(1/7, 7), sides=2)
	p <- ggplot(a, aes(x=yyyymmdd, y=value)) + 
			geom_area(fill=dinkla_blue, alpha=.3) + 
			geom_line(color=dinkla_blue) + 
			geom_line(aes(y=smoothed), color=dinkla_red) + 
			theme(
				panel.background = element_rect(fill=mk_color(dinkla_blue, 0.1)),
				legend.position=c(0.1, 0.7)) + 
			ggtitle("Number of check-ins per day in the loc-gowalla dataset") +
   			xlab("Date") + ylab("Number of check-ins") +
			theme(
				axis.title.x=element_text(size=size_middle, family=font_family, lineheight=.9, colour=dinkla_red),
				axis.text.x=element_text(size=size_small, color=dinkla_blue, family=font_family),
				axis.title.y=element_text(size=size_middle, family=font_family, lineheight=.9, colour=dinkla_red),
				axis.text.y=element_text(size=size_small, color=dinkla_blue, family=font_family),
				plot.title=element_text(size=size_large, color=dinkla_red, family=font_family)
			) 

	p
}

#
# sums_ns: Number of neighbors
#
# displayed in a histogram
#

sums_ns1 <- read.csv(file="num_neighbors_20091006_5.0.csv", header=TRUE, sep=";")

chart_ns <- function(binwidth = 8, scale = 1) {

	size_small <- 12 * scale
	size_middle <- 16 * scale
	size_large <- 24 * scale
	origin <- 1 - binwidth

	# filter out users with no neighbors
	#a <- sums_ns1[sums_ns1$number.of.neighbors > 0,]
	a <- sums_ns1
	mx <- max(a$number.of.neighbors)

	p <- ggplot(a, aes(x=number.of.neighbors)) + 
			geom_histogram(binwidth=binwidth, origin=origin, fill=mk_color(dinkla_blue, 0.8), color=dinkla_dark_blue) +
			scale_x_continuous(breaks=seq(0, mx, 5)) +
			theme(
				panel.background = element_rect(fill=mk_color(dinkla_blue, 0.1)),
				panel.grid.major.x = element_blank(),
    		    panel.grid.minor.x = element_blank()) + 
			ggtitle("Number of neighbors (also checked in) in a 5km range") +
   			xlab("Number of neighbors") + ylab("Number of users")  +
			theme(
			axis.title.x=element_text(size=size_middle, family=font_family, lineheight=.9, colour=dinkla_red),
			axis.text.x=element_text(size=size_small, color=dinkla_blue, family=font_family),
			axis.title.y=element_text(size=size_middle, family=font_family, lineheight=.9, colour=dinkla_red),
			axis.text.y=element_text(size=size_small, color=dinkla_blue, family=font_family),
			plot.title=element_text(size=size_large, color=dinkla_red, family=font_family)
			)
   	p
}

#
# sums_ns: Number of neighbors
#
# displayed on a map
#

sums_loc <- read.csv(file="sums_location.csv", header=TRUE, sep=";")

chart_loc <- function(scale = 1) {

  size_small <- 12 * scale
  size_middle <- 16 * scale
  size_large <- 24 * scale
  
	# calc percentages
	a <- sums_loc
	a$pct <- a$number.of.checkins/sum(a$number.of.checkins)*100

	# filter data
	a <- a[a$pct >= 0.1,]
	# get the map and add points
  w <- get_map("Salina, Kansas, USA", zoom=4, scale=2)
	p <- ggmap(w) +
	  ggtitle("Regions with a high number of check-ins") + 
			theme(
				plot.title=element_text(size=size_large, color=dinkla_red, family=font_family),
				legend.position="top",
				legend.title=element_text(size=size_middle, color=dinkla_blue, family=font_family),
				legend.text=element_text(size=size_small, color=dinkla_blue, family=font_family)
			)

	p + geom_point(data=a, aes(locationY, locationX, color=pct), size=10, alpha=.9) + 
			scale_color_gradient2(low=dinkla_dark_blue, mid=dinkla_blue, high=dinkla_red, name="in %")
}
