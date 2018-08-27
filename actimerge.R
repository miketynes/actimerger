library(dplyr, quietly = TRUE)
library(chron, quietly = TRUE)
library(magrittr, quietly = TRUE)
library(stringr, quietly = TRUE)


#' Delete the summary statsitsics saved in a participant table by AW2
#' @param acti actigraphy frame: a df of daily level participant data exported by AW2
rm_summary_stats <- function(acti) {
  acti <- acti[complete.cases(acti["IntNum"]), ]
  return(acti)
}

#' Set the datatypes of each column in an actigraphy frame to something useful
set_col_classes <- function(acti) {
  acti$IntName <- factor(acti$IntName)
  acti$etime <- chron(times. = acti$etime, format = c("h:m:s"))
  acti$edate <- chron(dates. = acti$edate)
  return(acti)
}

#' Select the custom interval data from an acti frame (excluding SOL)
get_custom_ints <- function(acti) {
  custom_ints <- acti %>% 
    filter(IntName == "Custom") %>% 
    select(-sol)
  return(custom_ints)
}

#' Get edate and sol from the down intervals of an acti frame. 
get_down_ints <- function(acti) {
  down_ints <- acti %>% 
    filter(IntName == "Down") %>% 
    select(edate, sol)
  return(down_ints)
}

#' Grab the desired variables from custom and down intervals from acti df
select_custom_down <- function(acti) {
  down <- get_down_ints(acti)
  custom <- get_custom_ints(acti)
  result <- merge(custom, down, by = "edate")
  result %<>% select(-IntName) 
}

#' Determine whether any WAKETIMES in an acti frame are after the specified cutoff
#' @param x a vector of time objects (not called 'times' to avoid clobbering)
#' @param cutoff a single h:m:s time string
#' @returns bool: if any WAKETIMES are after the cutoff
after_cutoff <- function(x, cutoff) {
  cutoff <- chron(times. = cutoff)
  return(any(x > cutoff))
}

#' Loop over acti files, reshape, and append to list
#' @param acti_files: a vector of actigraph filenames
#' @param cutoff: h:m:s time string. Files with WAKETIMES after the cutoff will throw a warning
#' @return list of reshaped actigraphy dfs 
reshape_files <- function(acti_files, cutoff = "18:00:00") {
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
    if (after_cutoff(subj_df$etime, cutoff)) {
      warning(paste0(current_file, " has waketimes times after cutoff."))
    }
    # hairstudy 
    # file_id <- str_extract(current_file, "^[0-9]+")
    # sleepstudy
    file_id <- str_extract(current_file, "C[0-9]{8}(\\(2\\))?_y\\d_[A-Z]{2}")
    subj_df$file_id <- file_id
    acti_list[[i]] <- subj_df
  }
  return(acti_list)
}

##############################################

path <- commandArgs(trailingOnly = TRUE)

main <- function(path) {
  setwd(path)
  acti_files <- dir(pattern = "ALL_INT")
  acti_list <- reshape_files(acti_files)
  outframe <- do.call(rbind, acti_list)
  outtime <- format(Sys.time(), "%Y.%m.%d-%H.%M.%S")
  outname <- paste0("actimerged_", outtime, ".csv")
  write.csv(outframe, outname, row.names = FALSE)
}

main(path)
