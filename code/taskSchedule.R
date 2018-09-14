################################
### Scheduling Pull and Prep ###
################################

library(taskscheduleR)

pullPrepScript = "C:/Users/sberry5/Documents/research/ticketOptions/code/teamOptionsPullPrep.R"

taskscheduler_create(taskname = "optionsPullPrep", rscript = pullPrepScript, 
                     schedule = "DAILY", starttime = "13:00", 
                     startdate = format(Sys.Date(), "%m/%d/%Y"))

# WARNING!!
# This is for the future! Do not uncomment and run until we are done!

# taskscheduler_delete(taskname = "optionsPullPrep")
