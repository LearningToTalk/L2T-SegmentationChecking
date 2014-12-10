# Author: Patrick Reidy
# Date:   June 24, 2014


# Include the auxiliary code files.
include ../L2T-utilities/L2T-Utilities.praat
include ../L2T-StartupForm/L2T-StartupForm.praat
include ../L2T-Audio/L2T-Audio.praat
include ../L2T-WordList/L2T-WordList.praat
include ../SegmentationLog/L2T-SegmentationLog.praat
include ../L2T-SegmentationTextGrid/L2T-SegmentationTextGrid.praat




# A general function for checking whether the current values of variables allow the progress to subsequent phases of the script.
procedure ready
  if (audio.praat_obj$ <> "") & 
     ... (wordlist.praat_obj$ <> "") &
     ... (segmentation_log.praat_obj$ <> "") &
     ... (segmentation_textgrid.praat_obj$ <> "")
    .to_check_segmentations = 1
  else
    .to_check_segmentations = 0
  endif
endproc




# A procedure to determine information about the current trial to check.
procedure current_trial_to_check
#    printline
#    printline Current trial:
  # Determine the [.row_on_wordlist] that designates the current trial by getting the value of the 'NumberOfTrialsSegmented' column, on the second column, and then incrementing this number by one.
  select 'segmentation_log.praat_obj$'
  .row_on_wordlist = Get value... 'segmentation_log.row_on_segmentation_log'
                              ... 'segmentation_log_columns.segmented_trials$'
  .row_on_wordlist = .row_on_wordlist + 1
  # Consult the WordList table to look-up the current trial's...
  # ... Trial Number
  select 'wordlist.praat_obj$'
  .trial_number$ = Get value... '.row_on_wordlist'
                            ... 'wordlist_columns.trial_number$'
#    printline   '.trial_number$'

## PFR: Wrapping the assignment of [.target_word$] in if...elif...endif clauses,
##      so that the column of the WordList, from which is drawn the label of
##      the Word interval, can be set according to the [.experimental_task$].
  # ... Target Word
  if session_parameters.experimental_task$ == "RealWordRep"
    .target_word$ = Get value... '.row_on_wordlist'
                             ... 'wordlist_columns.word$'
  elif session_parameters.experimental_task$ == "NonWordRep"
    .target_word$ = Get value... '.row_on_wordlist'
                             ... 'wordlist_columns.orthography$'
  endif
## /PFR 2014-08-01
### MEB commenting out from here, so that the script can work with NWR WordList files.
  # ... Target Consonant
#  .target_c$ = Get value... '.row_on_wordlist'
#                        ... 'wordlist_columns.target_c$'
#    printline   '.target_c$'
  # ... Target Vowel
#  .target_v$ = Get value... '.row_on_wordlist'
 #                       ... 'wordlist_columns.target_v$'
#    printline   '.target_v$'
### End of commenting out.

  # Determine the xmin, xmid, and xmax of the interval on the 'Trial' tier of the segmented TextGrid that corresponds to the current trial.
  @interval: segmentation_textgrid.praat_obj$,
         ... segmentation_textgrid_tiers.trial,
         ... .trial_number$
  .xmin = interval.xmin
  .xmid = interval.xmid
  .xmax = interval.xmax
  .zoom_xmin = .xmin - 1.0
  .zoom_xmax = .xmax + 1.0
#    printline   'current_trial_to_check.xmin'
#    printline   'current_trial_to_check.xmid'
#    printline   'current_trial_to_check.xmax'
endproc


procedure trial_options
  .resegment$  = "Re-segment this trial"
## PFR: Adding [.copy_trial$] for when the checker wants to make small
##      adjustments to the trial, manually.
  .copy_trial$ = "Copy this trial & modify manually"
## /PFR 2014-08-04
  .next_trial$ = "Keep this trial as it is"
  .save_quit$  = "Save my progress & quit"
  beginPause: "Trial: 'current_trial_to_check.trial_number$'"
# MEB: Changing default to 3, to speed up.
#    choice: "I want to", 1
    choice: "I want to", 3
      option: .resegment$
## PFR: Adding option for [.copy_trial$].
      option: .copy_trial$
## /PFR 2014-08-04
      option: .next_trial$
      option: .save_quit$
  endPause: "", "Do it!", 2, 1
  .choice  = i_want_to
  .choice$ = i_want_to$
endproc


procedure segment_interval_tier: .tier, .xmin, .xmax, .label$
  select 'segmentation_textgrid.praat_obj$'
  Insert boundary... '.tier' '.xmin'
  Insert boundary... '.tier' '.xmax'
  .xmid = (.xmin + .xmax) / 2
  .interval = Get interval at time... '.tier' '.xmid'
  Set interval text... '.tier' '.interval' '.label$'
endproc


procedure segment_point_tier: .tier, .time, .label$
  if .label$ <> ""
    select 'segmentation_textgrid.praat_obj$'
    Insert point... '.tier' '.time' '.label$'
  endif
endproc


procedure segment_interval: .repetition
  # Prompt the user to enter the Context and Notes information.
  beginPause: "Trial: 'current_trial_to_check.trial_number$'"
    if .repetition == 1
      comment: "Please highlight the FIRST interval you would like to segment."
    else
      comment: "Please highlight the NEXT interval you would like to segment."
    endif
### MEB: Changed this to add the standard notes.
#    comment: "Click 'Segment interval' once you have filled the fields below."
    comment: "Click 'Segment interval' once you have chosen the context label, ..."
	choice: "Context", 2
	  option: "NonResponse"
	  option: "Response"
	  option: "UnpromptedResponse"
	  option: "VoicePromptResponse"
	  option: "Perseveration"
	  option: "TargetPromptMissing"
### MEB: Need these options for the standard notes tier labels
    comment ("and marked any of the following standard notes that is appropriate.") 
	boolean ("talking over stimulus", 0)
	boolean ("noise during response", 0)
	boolean ("fragment", 0)
	boolean ("false start", 0)
	boolean ("not initial", 0)
   comment ("and [optionally] added any non-standard note, if appropriate.") 
### Added the above standard notes.
    sentence: "Notes", ""
  endPause: "", "Segment interval", 2, 1
  # Get the [.xmin] and [.xmax] of the selection.
  editor 'segmentation_textgrid.praat_obj$'
    .xmin = Get start of selection
    .xmax = Get end of selection
  endeditor
  # Segment the Context tier.
  .context_label$ = context$
  @segment_interval_tier: segmentation_textgrid_tiers.check_context,
                      ... .xmin, .xmax, .context_label$
  # Segment the Repetition tier.
  .repetition_label$ = "'.repetition'"
  @segment_interval_tier: segmentation_textgrid_tiers.check_repetition,
                      ... .xmin, .xmax, .repetition_label$
  # Add the Notes.
### MEB: added code to build the note$ before adding the Note label to the SegmNotes tier.
  note$ = ""
  num_notes = 0
  if 'talking_over_stimulus'
	note$ = note$+"TOS"
	num_notes = 'num_notes' + 1
  endif
  if 'noise_during_response'
	if (num_notes > 0)
		note$ = note$ + "; "
	endif
	note$ = note$+"noise"
	num_notes = 'num_notes' + 1
  endif
  if 'fragment'
	if (num_notes > 0)
		note$ = note$ + "; "
	endif
	note$ = note$+"fragment"
	num_notes = 'num_notes' + 1
  endif
  if 'false_start'
	if (num_notes > 0)
		note$ = note$ + "; "
	endif
	note$ = note$+"FS"
  endif
  if 'not_initial'
	if (num_notes > 0)
		note$ = note$ + "; "
	endif
	note$ = note$+"NI"
  endif
# Add a non-standard note, if there is one.
  if notes$ <> ""
	if (num_notes > 0)
		note$ = note$ + "; "
	endif
	note$ = note$+notes$
  endif
  .notes_label$ = note$
####
#  .notes_label$ = notes$
  .notes_time = (.xmin + .xmax) / 2
  @segment_point_tier: segmentation_textgrid_tiers.check_notes,
                   ... .notes_time, .notes_label$
endproc

# PFR: commenting out this function because we are switching from a 9 tier
#      format to an 11 tier format for the Segmentation Checking TextGrid.
#      So, the interval boundaries on the Trial and Word tiers no longer need
#      to be adjusted.  Instead, new intervals on the CheckedTrial and
#      CheckedWord tiers need to be created.
# /PFR 2014-08-01
#procedure adjust_interval_boundaries: .tier, .xmin, .xmax
#  .xmid = (current_trial_to_check.xmin + current_trial_to_check.xmax) / 2
#    select 'segmentation_textgrid.praat_obj$'
#    .interval = Get interval at time... '.tier' '.xmid'
#    Set interval text... '.tier' '.interval'
#    Remove right boundary... '.tier' '.interval'
#    Remove left boundary... '.tier' '.interval'
#    Insert boundary... '.tier' '.xmin'
#    Insert boundary... '.tier' '.xmax'
#    if .tier == segmentation_textgrid_tiers.trial
#      .label$ = current_trial_to_check.trial_number$
#    elif .tier == segmentation_textgrid_tiers.word
### PFR wrapping the reference to .target_word$ in an if...endif clause so that it only applies during RWR segmentation-checking.
#      if session_parameters.experimental_task$ == experimental_tasks.rwr$
#        .label$ = current_trial_to_check.target_word$
#      endif
#    endif
#    Set interval text... '.tier' '.interval' '.label$'
#endproc


# PFR: commenting out this function because we are switching from a 9 tier
#      format to an 11 tier format for the Segmentation Checking TextGrid.
#      So, the interval boundaries on the Trial and Word tiers no longer need
#      to be adjusted.  Instead, new intervals on the CheckedTrial and
#      CheckedWord tiers need to be created.
# /PFR 2014-08-01
#procedure adjust_trial_boundaries: .xmin, .xmax
#  if .xmin < current_trial_to_check.xmin | .xmax > current_trial_to_check.xmax
#    @adjust_interval_boundaries: segmentation_textgrid_tiers.trial,
#                             ... .xmin, .xmax
#    @adjust_interval_boundaries: segmentation_textgrid_tiers.word,
#                             ... .xmin, .xmax
#  endif
#endproc


procedure resegment_trial
## PFR: commenting this out so that the [.trial_xmin] and [.trial_xmax] are
##      not in any way determined by the original trial boundaries when the
##      trial is resegmented.
#  # Keep track of the [.trial_xmin] and [.trial_xmax] times.
#  .trial_xmin = current_trial_to_check.xmin
#  .trial_xmax = current_trial_to_check.xmax
## /PFR 2014-08-01
  # Keep track of the Repetition number
  .repetition = 1
  # Segment the first interval.
  @segment_interval: .repetition
## PFR: [.trial_xmin] and [.trial_xmax] are initialized to the [.xmin] and
##      [.xmax] values of [segment_interval], respectively.
  # Keep track of the [.trial_xmin] and [.trial_xmax] times.
  .trial_xmin = segment_interval.xmin
  .trial_xmax = segment_interval.xmax
## /PFR 2014-08-01
## PFR: commenting this out because [.trial_xmin] and [.trial_xmax] are not
##      updated, per se, after [segment_interval]; they are initialized after
##      [segment_interval].  See new code block above.
#  # Update the [.trial_xmin] and [.trial_xmax] accumulators.
#  if segment_interval.xmin < .trial_xmin
#    .trial_xmin = segment_interval.xmin
#  endif
#  if segment_interval.xmax > .trial_xmax
#    .trial_xmax = segment_interval.xmax
#  endif
## /PFR 2014-08-01
  # Throw the checker into a while-loop.
  .continue_segmenting = 1
  while .continue_segmenting
    beginPause: "Trial: 'current_trial_to_check.trial_number$'"
      .segment$    = "Segment another interval"
      .move_on$ = "Move on to the next trial"
### MEB: If make this be 2 as the option, would move faster.
#      choice: "I want to", 1
        choice: "I want to", 2
        option: .segment$
        option: .move_on$
    endPause: "", "Do it!", 2, 1
    if i_want_to$ == .segment$
      .repetition = .repetition + 1
      @segment_interval: .repetition
      # Update the [.trial_xmin] and [.trial_xmax] accumulators.
      if segment_interval.xmin < .trial_xmin
        .trial_xmin = segment_interval.xmin
      endif
      if segment_interval.xmax > .trial_xmax
        .trial_xmax = segment_interval.xmax
      endif
    elif i_want_to$ == .move_on$
      .continue_segmenting = 0
    endif
  endwhile
## PFR: commenting this out because the original Trial and Word intervals are
##      no longer modified under the 11 tier format.
#  # Optionally adjust the boundaries of the Trial and Word intervals.
#  @adjust_trial_boundaries: .trial_xmin, .trial_xmax
## /PFR 2014-08-01
## PFR: Add interval boundaries & labels to the CheckedTrial and CheckedWord
##      tiers.
  @segment_interval_tier: segmentation_textgrid_tiers.check_trial,
                      ... .trial_xmin, .trial_xmax,
                      ... current_trial_to_check.trial_number$
  @segment_interval_tier: segmentation_textgrid_tiers.check_word,
                      ... .trial_xmin, .trial_xmax,
                      ... current_trial_to_check.target_word$
## /PFR 2014-08-01
  # Add a point on the 'ToReview' tier, noting that this trial was modified.
  .trial_xmid = (.trial_xmin + .trial_xmax) / 2
  select 'segmentation_textgrid.praat_obj$'
  Insert point... 'segmentation_textgrid_tiers.to_review' '.trial_xmid'
              ... review
endproc


procedure current_trial_as_table
  @extract_interval: segmentation_textgrid.praat_obj$,
                 ... current_trial_to_check.xmin,
                 ... current_trial_to_check.xmax
  .textgrid_obj$ = extract_interval.praat_obj$
  @textgrid2table: .textgrid_obj$
  .praat_obj$ = textgrid2table.praat_obj$
  @remove: .textgrid_obj$
endproc


procedure elicitations_of_current_trial
  @current_trial_as_table
  select 'current_trial_as_table.praat_obj$'
  Extract rows where column (text)... tier "is equal to" 
                                  ... 'segmentation_textgrid_tiers.context$'
  .praat_obj$ = selected$()
  .n_elicitations = Get number of rows
  @remove: current_trial_as_table.praat_obj$
endproc


procedure elicitation_boundaries: .elicitation
  # Get the [.xmin], [.xmid], and [.xmax] values from the Table of the 
  # [elicitations_of_current_trial].
  select 'elicitations_of_current_trial.praat_obj$'
  .xmin = Get value... '.elicitation' tmin
  .xmax = Get value... '.elicitation' tmax
  .xmid = (.xmin + .xmax) / 2
  # Look up on the Segmentation TextGrid, the interval on the Context tier at
  # the [.xmid] timepoint.
  select 'segmentation_textgrid.praat_obj$'
  .interval = Get interval at time... 'segmentation_textgrid_tiers.context'
                                  ... '.xmid'
  # Use this [.interval] number to determine the boundary times of the
  # elicitation.
  .xmin = Get start point... 'segmentation_textgrid_tiers.context'
                         ... '.interval'
  .xmax = Get end point... 'segmentation_textgrid_tiers.context'
                       ... '.interval'
  .xmid = (.xmin + .xmax) / 2
endproc


procedure duplicate_interval: .from_tier, .to_tier
  # Get the label of the interval on [.tier].
  @interval_label_at_time: segmentation_textgrid.praat_obj$, .from_tier,
                       ... elicitation_boundaries.xmid
  .label$ = interval_label_at_time.label$
  # Copy down the interval.
  select 'segmentation_textgrid.praat_obj$'
  Insert boundary... '.to_tier' 'elicitation_boundaries.xmin'
  Insert boundary... '.to_tier' 'elicitation_boundaries.xmax'
  .interval = Get interval at time... '.to_tier' 'elicitation_boundaries.xmid'
  Set interval text... '.to_tier' '.interval' '.label$'
endproc


procedure duplicate_notes
  # Extract the current elicitation and convert it to a table.
  @extract_interval: segmentation_textgrid.praat_obj$,
                 ... elicitation_boundaries.xmin,
                 ... elicitation_boundaries.xmax
  .elicitation_textgrid$ = extract_interval.praat_obj$
  select '.elicitation_textgrid$'
  .n_notes = Get number of points... 'segmentation_textgrid_tiers.segm_notes'
  if .n_notes > 0
    @textgrid2table: .elicitation_textgrid$
    .elicitation_table$ = textgrid2table.praat_obj$
    # Subset the elicitation-table to just the points on the SegmNotes tier.
    Extract rows where column (text)... tier "is equal to"
                                   ... 'segmentation_textgrid_tiers.segm_notes$'
    .notes_table$ = selected$()
    # Loop through rows of [.notes_table$]
    select '.notes_table$'
    .n_notes = Get number of rows
      for .note to .n_notes
        select '.notes_table$'
        .time = Get value... '.note' tmin
        select 'segmentation_textgrid.praat_obj$'
        .index = Get nearest index from time...
                 ... 'segmentation_textgrid_tiers.segm_notes' '.time'
        .time = Get time of point... 'segmentation_textgrid_tiers.segm_notes'
                                 ... '.index'
        .text$ = Get label of point... 'segmentation_textgrid_tiers.segm_notes'
                                   ... '.index'
        Insert point... 'segmentation_textgrid_tiers.check_notes' '.time'
                    ... '.text$'
      endfor
    # Clean up the Praat Objects list
    @remove: .elicitation_table$
    @remove: .notes_table$
  endif
  @remove: .elicitation_textgrid$
endproc


procedure duplicate_elicitation: .elicitation
  # Get the boundary times of the [.elicitation].
  @elicitation_boundaries: .elicitation
  # Duplicate the Context interval.
  @duplicate_interval: 'segmentation_textgrid_tiers.context',
                   ... 'segmentation_textgrid_tiers.check_context'
  # Duplicate the Repetition interval.
  @duplicate_interval: 'segmentation_textgrid_tiers.repetition',
                   ... 'segmentation_textgrid_tiers.check_repetition'
  # Duplicate the points on the SegmNotes tier.
  @duplicate_notes
endproc


procedure duplicate_trial
## PFR: Copy the intervals on the Trial and Word tiers to the CheckedTrial and
##      CheckedWord tiers, respectively.
  @segment_interval_tier: segmentation_textgrid_tiers.check_trial,
                      ... current_trial_to_check.xmin, 
                      ... current_trial_to_check.xmax,
                      ... current_trial_to_check.trial_number$
  @segment_interval_tier: segmentation_textgrid_tiers.check_word,
                      ... current_trial_to_check.xmin, 
                      ... current_trial_to_check.xmax,
                      ... current_trial_to_check.target_word$
## /PFR 2014-08-01  
  # Duplicate each elicitation.
  @elicitations_of_current_trial
  for .elicitation to elicitations_of_current_trial.n_elicitations
    @duplicate_elicitation: .elicitation
  endfor
  # Clean up the Praat Objects list.
  @remove: elicitations_of_current_trial.praat_obj$
endproc


procedure pause_to_edit_manually
  .current_trial$ = current_trial_to_check.trial_number$
  beginPause: "Holding pattern..."
    comment: "Feel free to edit by hand the segmentations of '.current_trial$' on Tiers 6--10."
    comment: "When you are finished editing '.current_trial$', click 'Move on!'"
  endPause: "", "Move on!", 2, 1
endproc


procedure update_log
  select 'segmentation_log.praat_obj$'
  .n_checked = Get value... 'segmentation_log.row_on_segmentation_log'
                        ... 'segmentation_log_columns.segmented_trials$'
  .n_checked = .n_checked + 1
  Set numeric value... 'segmentation_log.row_on_segmentation_log'
                   ... 'segmentation_log_columns.segmented_trials$'
                   ... '.n_checked'
endproc


procedure save_progress
  # Save the Segmentation Log as a tab-separated file.
  select 'segmentation_log.praat_obj$'
  printline Saving 'segmentation_log.praat_obj$' to 'segmentation_log.write_to$'
  Save as tab-separated file... 'segmentation_log.write_to$'
  # Save the TextGrid as a text file.
  select 'segmentation_textgrid.praat_obj$'
  printline Saving 'segmentation_textgrid.praat_obj$' to
        ... 'segmentation_textgrid.write_to$'
  Save as text file... 'segmentation_textgrid.write_to$'
endproc


procedure check_if_finished
  select 'segmentation_log.praat_obj$'
  .n_trials = Get value... 'segmentation_log.row_on_segmentation_log'
                       ... 'segmentation_log_columns.trials$'
  .n_checked = Get value... 'segmentation_log.row_on_segmentation_log'
                        ... 'segmentation_log_columns.segmented_trials$'
  .finished = .n_checked == .n_trials
endproc


procedure extract_merge_and_save_checked_tiers
  @participant: segmentation_log.read_from$,
            ... session_parameters.participant_number$
  .write_to$ = session_parameters.experiment_directory$ + "/" +
           ... "Segmentation" + "/" + "TextGrids" + "/" +
           ... session_parameters.experimental_task$ + "_" +
           ... participant.id$ + "_" +
           ... session_parameters.initials$ + "segm.TextGrid"
  # Trial tier
  select 'segmentation_textgrid.praat_obj$'
## PFR: changed so that [.check_trial] is extracted.
#  Extract one tier... 'segmentation_textgrid_tiers.trial'
  Extract one tier... 'segmentation_textgrid_tiers.check_trial'
## /PFR 2014-08-01
  .trial_textgrid$ = selected$()
  # Word tier
  select 'segmentation_textgrid.praat_obj$'
## PFR: changed so that [.check_word] is extracted.
#  Extract one tier... 'segmentation_textgrid_tiers.word'
  Extract one tier... 'segmentation_textgrid_tiers.check_word'
## /PFR 2014-08-01
  .word_textgrid$ = selected$()
  # Checked Context tier
  select 'segmentation_textgrid.praat_obj$'
  Extract one tier... 'segmentation_textgrid_tiers.check_context'
  .context_textgrid$ = selected$()
  # Checked Repetition tier
  select 'segmentation_textgrid.praat_obj$'
  Extract one tier... 'segmentation_textgrid_tiers.check_repetition'
  .repetition_textgrid$ = selected$()
  # Checked Notes tier.
  select 'segmentation_textgrid.praat_obj$'
  Extract one tier... 'segmentation_textgrid_tiers.check_notes'
  .notes_textgrid$ = selected$()
  # Select all of the extracted tiers.
  select '.trial_textgrid$'
  plus '.word_textgrid$'
  plus '.context_textgrid$'
  plus '.repetition_textgrid$'
  plus '.notes_textgrid$'
  Merge
  Rename... 'participant.id$'_Checked
  .praat_obj$ = selected$()
  # Rename the Context, Repetition, and Notes tiers.
  select '.praat_obj$'
## PFR: added lines so that the [.check_trial$] and [.check_word$] tiers are
##      renamed to [.trial$] and [.word$] tiers, respectively.
  Set tier name... 1 'segmentation_textgrid_tiers.trial$'
  Set tier name... 2 'segmentation_textgrid_tiers.word$'
## /PFR 2014-08-01
  Set tier name... 3 'segmentation_textgrid_tiers.context$'
  Set tier name... 4 'segmentation_textgrid_tiers.repetition$'
  Set tier name... 5 'segmentation_textgrid_tiers.segm_notes$'
  # Save the Checked TextGrid.
  select '.praat_obj$'
  Save as text file... '.write_to$'
  # Remove all of the extracted tiers.
  @remove: .trial_textgrid$
  @remove: .word_textgrid$
  @remove: .context_textgrid$
  @remove: .repetition_textgrid$
  @remove: .notes_textgrid$
  @remove: .praat_obj$
endproc










################################################################################
#  Main procedure                                                              #
################################################################################

# Set the session parameters.
@session_parameters
#printline 'session_parameters.initials$'
#printline 'session_parameters.workstation$'
#printline 'session_parameters.experimental_task$'
#printline 'session_parameters.testwave$'
#printline 'session_parameters.participant_number$'
#printline 'session_parameters.activity$'
#printline 'session_parameters.analysis_directory$'
printline Data directory: 'session_parameters.experiment_directory$'

# Load the audio file
@audio

# Load the WordList.
@wordlist

# Load the Segmentation Log.
@segmentation_log

# Load the Segmented TextGrid.
@segmentation_textgrid

# Only proceed to checking segmentations if all the requisite files have been loaded to the Praat Objects list.
@ready
if ready.to_check_segmentations
  printline Ready to check: 'segmentation_textgrid.praat_obj$'
  # Open an Editor window that displays the audio Sound object and the 
  # segmented TextGrid object.
  @open_editor: segmentation_textgrid.praat_obj$,
            ... audio.praat_obj$
  # Enter a while-loop within which the segmentation checking is performed.
  continue_checking = 1
  while continue_checking
    # Determine the current trial to check.
    @current_trial_to_check

    # Zoom to the current trial.
    @zoom: segmentation_textgrid.praat_obj$, 
       ... current_trial_to_check.zoom_xmin,
       ... current_trial_to_check.zoom_xmax,

    # Display a form prompting the checker to decide what she would like to do
    # to the current trial.
    @trial_options
    if trial_options.choice$ == trial_options.resegment$
      # Resegment the trial, elictation-by-elictation.
      @resegment_trial
      # Update the Segmentation Log.
      @update_log

## PFR: Adding a block for when the checker decides to copy the trial
##      and then modify it manually.
    elif trial_options.choice$ == trial_options.copy_trial$
      # Duplicate the trial from the "Segmentation" tiers to the "Check" tiers.
      @duplicate_trial
      # Pause to allow the user to edit the segmentations manually.
      @pause_to_edit_manually
      # Update the Segmentation Log.
      @update_log
## /PFR 2014-08-04

    elif trial_options.choice$ == trial_options.next_trial$
      # Duplicate the trial from the "Segmentation" tiers to the "Check" tiers.
      @duplicate_trial
      # Update the Segmentation Log.
      @update_log
      
    elif trial_options.choice$ == trial_options.save_quit$
      # Break out of the loop.
      continue_checking = 0
    endif
    
    # Save progress.
    @save_progress
    
    # Check if all trials have been checked.
    @check_if_finished
    if check_if_finished.finished
      continue_checking = 0
      @extract_merge_and_save_checked_tiers
    endif
  endwhile   # if continue_checking == 0
endif


@save_progress
@remove: audio.praat_obj$
@remove: wordlist.praat_obj$
@remove: segmentation_log.praat_obj$
@remove: segmentation_textgrid.praat_obj$



