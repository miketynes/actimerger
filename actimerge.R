library(dplyr, quietly = TRUE)
library(chron, quietly = TRUE)
library(magrittr, quietly = TRUE)

rm_summary_stats <- function(acti) {
  acti <- acti[complete.cases(acti["IntNum"]), ]
  return(acti)
}

set_col_classes <- function(acti) {
  acti$IntName <- factor(acti$IntName)
  acti$etime <- chron(times. = acti$etime, format = c("h:m:s"))
  acti$edate <- chron(dates. = acti$edate)
  return(acti)
}

get_custom_ints <- function(acti) {
  custom_ints <- acti %>% 
    filter(IntName == "Custom") %>% 
    select(-sol)
  return(custom_ints)
}

get_down_ints <- function(acti) {
  down_ints <- acti %>% 
    filter(IntName == "Down") %>% 
    select(edate, sol)
  return(down_ints)
}

select_custom_down <- function(acti) {
  down <- get_down_ints(acti)
  custom <- get_custom_ints(acti)
  result <- merge(custom, down, by = "edate")
  result %<>% select(-IntName) 
}

after_cutoff <- function(x, cutoff) {
  # args:
  #   x: a vector of time objects (not called 'times' to avoid clobbering)
  #   cutoff: a single h:m:s time string
  # returns:
  #   bool: if any times are before the cutoff
  
  cutoff <- chron(times. = cutoff)
  return(any(x > cutoff))
}

reshape_files <- function(acti_files, cutoff = "18:00:00") {
  # Loop over acti files, reshape, and append to list
  # Args:
  #   acti_files: a vector of actigraph filenames
  #   cutoff: h:m:s time string. 
  #           files with sleep times after the cutoff will throw a warning
  # Returns: 
  #   list of reshaped actigraphy dfs 
  
  acti_list <- vector("list", length(acti_files))
  for (i in seq_along(acti_files)) {
    current_file <- acti_files[i]
    subj_df <- read.csv(current_file)
    if (!("IntNum" %in% names(subj_df))) {
      warning(paste(current_file, "has invalid format: skipping."))
      next
    } 
    subj_df <- rm_summary_stats(subj_df)
    subj_df <- set_col_classes(subj_df)
    subj_df <- select_custom_down(subj_df)
    if (anyDuplicated(subj_df$edate)) {
      warning(paste0("Duplicate dates in ", current_file, ": skipping."))
      next
    }
    if (after_cutoff(subj_df$etime, CUTOFF)) {
      warning(paste0(current_file, " has times after cutoff."))
    }
    acti_list[[i]] <- subj_df
  }
  return(acti_list)
}

##############################################

path <- commandArgs(trailingOnly = TRUE)

main <- function(path) {
  setwd(path)
  acti_files <- dir(pattern = ".txt")
  acti_list <- reshape_files(acti_files)
  outframe <- do.call(rbind, acti_list)
  outtime <- format(Sys.time(), "%Y.%m.%d-%H.%M.%S")
  outname <- paste0("actimerged_", outtime, ".csv")
  write.csv(outframe, outname, row.names = FALSE)
}

main(path)
