# Causal Final Project
Jimmy Butler and Jeremy Goldwasser

# File Directory

+ figures: contains all of the figures used in our paper, created from our analyses
+ original-project: the STATA scripts and log files from the original analysis
+ coverage_regression.Rmd: used to estimate coverage regression equations for Sesame Street coverage and make relevant plots for analysis
+ extra_analysis.Rmd: used for outcome imputation and doubly robust supplementary analysis
+ file_explorations.R: R script with code to load up authors original data
+ orig-paper.pdf: the original paper we are replicating
+ outcome1980_preprocess.Rmd: preprocessing steps to prepare data for 1980 outcome analysis
+ outcome1980_results.Rmd: script fitting models and making tables of causal effects for 1980 outcome, using 1980 preprocessed data
+ outcome1990_preprocess.Rmd: prepares data for 1990 outcome analysis
+ outcome1990_results.Rmd: regression models for 1990 outcomes
+ outcome2000_preprocess.Rmd: prepares data for 2000 outcome analysis
+ outcome2000_results.Rmd: regression models for 2000 outcomes

NOTE: the census data files are too large to be loaded into GitHub, so the repo does not contain the actualy 'data' directory from the original downloadable project. I just included it in a .gitignore so it doesn't get uploaded to GitHub. Just add the 'data' directory from the authors' downloadable project to your local clone of the repo to maintain filepaths, and the .gitignore should make it so that it doesn't get uploaded. Running the preprocessing files should then nevertheless create the preprocessed data, and running the 'results' .Rmd files should extract from those created preprocessed data files.
