useR = Rnewest --vanilla --slave
BD = run
RD = res
SD = src
DD = data
CF = conf
LD = log
datafiles := $(wildcard $(DD)/*.dat)
sourcefiles := $(wildcard $(SD)/*)
BASE = baserun

.PHONY = data model plot justplot sim leaveout retro forecast updatabase button

data: $(BD)/data.RData  
$(BD)/data.RData: $(SD)/datascript.R $(datafiles) 
	echo 'source("$(SD)/datascript.R")' | $(useR) 1> $(LD)/data.out 2> $(LD)/data.err

defcon: $(CF)/model.cfg 
$(CF)/model.cfg: $(BD)/data.RData
	echo 'library(stockassessment); load("$(BD)/data.RData"); saveConf(defcon(dat),"$(CF)/model.cfg") ' | $(useR) 1> $(LD)/conf.out 2> $(LD)/conf.err

model: $(BD)/model.RData
$(BD)/model.RData: $(SD)/model.R $(BD)/data.RData $(CF)/model.cfg 
	echo 'source("$(SD)/model.R")' | $(useR) 1> $(LD)/model.out 2> $(LD)/model.err
	rm -f $(BD)/leaveout.RData $(BD)/retro.RData $(BD)/forecast.RData $(BD)/residuals.RData

plot: $(RD)/plotOK
$(RD)/plotOK: $(BD)/model.RData $(SD)/plotscript.R 
	echo 'source("$(SD)/plotscript.R")' | $(useR) 1> $(LD)/plot.out 2> $(LD)/plot.err
	touch $(RD)/plotOK

justplot: 
	echo 'source("$(SD)/plotscript.R")' | $(useR) 1> $(LD)/plot.out 2> $(LD)/plot.err
	touch $(RD)/plotOK

sim: $(BD)/residuals.RData justplot
$(BD)/residuals.RData: $(BD)/model.RData $(SD)/residuals.R
	echo 'source("$(SD)/residuals.R")' | $(useR) 1> $(LD)/res.out 2> $(LD)/res.err

leaveout: $(BD)/leaveout.RData justplot
$(BD)/leaveout.RData: $(BD)/model.RData $(SD)/leaveout.R
	echo 'source("$(SD)/leaveout.R")' | $(useR) 1> $(LD)/lo.out 2> $(LD)/lo.err

retro: $(BD)/retro.RData justplot
$(BD)/retro.RData: $(BD)/model.RData $(SD)/retro.R
	echo 'source("$(SD)/retro.R")' | $(useR) 1> $(LD)/retro.out 2> $(LD)/retro.err

forecast: $(BD)/forecast.RData justplot
$(BD)/forecast.RData: $(BD)/model.RData $(SD)/forecast.R
	echo 'source("$(SD)/forecast.R")' | $(useR) 1> $(LD)/model.out 2> $(LD)/model.err

updatebase: $(BASE)/model.RData

$(BASE)/model.RData: $(BD)/model.RData justplot
	rm -f $(BASE)/*
	cp $(BD)/model.RData $(BASE)

checkalldata: $(LD)/checkdata.tab
$(LD)/checkdata.tab: $(datafiles) $(SD)/datavalidator.R 
	echo 'source("$(SD)/datavalidator.R"); write.table(check.all("$(DD)"),sep="|",file="$(LD)/checkdata.tab",eol="\r\n")' | R --slave --vanilla 1> $(LD)/data.out 2> $(LD)/data.err

checkallsource: $(LD)/checksource.tab
$(LD)/checksource.tab: $(sourcefiles) $(SD)/sourcevalidator.R 
	echo 'source("$(SD)/sourcevalidator.R"); write.table(check.all.source("$(SD)"),sep="|",file="$(LD)/checksource.tab",eol="\r\n")' | R --slave --vanilla 1> $(LD)/source.out 2> $(LD)/source.err

button: 
	@echo Upgrade to baserun\; updatebase\; use current run as new baserun
	@echo Add leave-one-out runs\; leaveout\; Add leave-one-out runs based on the current model 
	@echo Add retro runs\; retro\; Add retrospective runs based on the current model 
	@echo Add forecasts\; forecast\; Add forecast runs to the output
	@echo Add residuals\; sim\; Add prediction and single joint sample residuals 
