#!/bin/bash
#
# -----------------------------------------------------------------------------
#
# File name:          unicycler_pipeline.sh
# Author:             Ivan Munoz Gutierrez
# Date created:       02/07/2021
# Date last modified: 04/01/2021
# Description:        Process Illumina and ONP reads using Unicycler. This
#                     script needs log_parser.py and fasta_extractor.py.
#                     For more details refer to the HELP heredoc.
#
# -----------------------------------------------------------------------------

# USAGE
readonly USAGE="Usage: $0 [-h HELP] -i input_folder -o output_folder"

# HELP heredoc
read -r -d '' HELP << EOM
Pipeline to assemble genomes using Unicycler.

Mandatory aguments:
-i input_folder        provide path to input folder
-o output_folder       provide path to output folder

Optional arguments:
-h                     show this help and exit

To run this program you need a main folder. The input folder must contain
subfolders with the Illumina and ONP reads that will be used for the assembly.
For example, you can have the following tree folder structure:

~/Documents/input/
              SW0001/
                  illumina_reads_1.fastq
                  illumina_reads_2.fastq
                  ONP_reads_L1000.fastq
              SW0002/
                  illumina_reads_1.fastq
                  illumina_reads_2.fastq
                  ONP_reads_L1000.fastq

The script will first analyze the data in folder SW0001. The resulting files
will be put in the output folder inside a new created folder that will be
named SW0001. Then, the script will continue the same process with the SW0002
folder present in the input folder. When the assembly is done, the
unicycler.log files will be parsed to extract all the relevant information,
generating two csv files. The csv files will be named molecules_summary and
assemblies_summary, and will be located in the output folder. Additionally, the
assembly.fasta fasta files will be parsed to extract the fasta sequences into
independent files. The new created fasta files will be named according to the
folder that contains the assembly.fasta file used for the extraction. The new
fasta files names will contain the length and topology of the molecule.

Usage example
-------------

$ ./unicycler_pipeline.sh -i ~/Documents/input -o ~/Documents/output

A tree example of a hypothetical results using the input folder described
before could be the one shown below. To handle future manipulation of the
extracted fasta files, a new folder named assemblies inside output will also
contained the extracted fasta files.

~/Documents/output/
              assemblies_summary.csv
              molecules_summary.csv
              SW0001/
                  assembly.fasta
                  unicycler.log
                  SW0001_4000000_circular.fasta
                  SW0001_100000_circular.fasta
                  SW0001_50000_circular.fasta
              SW0002/
                  assembly.fasta
                  unicycler.log
                  SW0002_5000000_linear.fasta
                  SW0002_200000_circular.fasta
              assemblies/
                  SW0001_4000000_circular.fasta
                  SW0001_100000_circular.fasta
                  SW0001_50000_circular.fasta
                  SW0002_5000000_linear.fasta
                  SW0002_200000_circular.fasta

Notes
-----
Information about the programs used in unicycler_pipeline can be found in:
  i)   unicycler: https://github.com/rrwick/Unicycler
  ii)  log_parser: https://github.com/Ivanmugu/log_parser
  iii) fasta_extractor: https://github.com/Ivanmugu/fasta_extractor
EOM


# -----------------------------------------------------------------------------
# Print help
# Globals:
#   USAGE
#   HELP
# Outputs:
#   Write help to stdout
# -----------------------------------------------------------------------------
function print_help() {
  echo $USAGE
  echo ""
  echo "$HELP"
}


# -----------------------------------------------------------------------------
# Run unicycler program
# Arguments:
#   input [$1] : path to input folder
#   output [$2] : path to output folder
# Outputs:
#   Files resulting from the assembly as assembly.fasta and unicycler.log are
#   saved in the ouput folder.
# -----------------------------------------------------------------------------
function run_unicycler() {
  local input=$1
  local output=$2

  # Accessing folders from input. 
  for folder in $(ls ./$input)
  do
      # Accessing subfolders from input.
      for file in $(ls ./$input/$folder)
      do
          # Getting the names of arguments for unicycler. The variable
          # extention is used to identify the type of read.
          extention=${file##*-}
          # Getting forward Illumina reads (1 indicates forward).
          if [[ "1.fastq" = $extention || "1.fastq.gz" = $extention ]]
          then
              forward=$file
          # Getting reverse Illumina reads (2 indicates reverse).
          elif [[ "2.fastq" = $extention || "2.fastq.gz" = $extention ]]
          then
              reverse=$file
          # Getting long ONP reads (L1000 indicates ONP).
          elif [[ "L1000.fastq" = $extention || "L1000.fastq.gz" = $extention ]]
          then
              long=$file
          # If file is not Illumina or ONP read ignore.
          else
            continue
          fi
      done
      # Creating directory to save the output of unicycler. The name of the
      # directory in the output folder will be the same as in the input folder.
      mkdir ./$output/$folder
      # Running unicycler.
      echo "Running unicycler with files from folder: $folder"
      unicycler -1 ./$input/$folder/$forward -2 ./$input/$folder/$reverse \
        -l ./$input/$folder/$long -t 32 --mode bold -o ./$output/$folder
  done
}


# -----------------------------------------------------------------------------
# Parse command line arguments.
# Globals:
#   USAGE
# Arguments:
#   $@ : all arguments provided in the command line.
# -----------------------------------------------------------------------------
function parse_arguments() {
  local option
  local inputFlag=false
  local outputFlag=false

  # Arguments to parse are -h -i and -o.
  while getopts ":hi:o:" option
  do
    case $option in
      # Priting help.
      h) print_help; exit 1;;
      # Getting path to input folder.
      i) inputFlag=true; inputFolder=$OPTARG;;
      # Getting path to output folder.
      o) outputFlag=true; outputFolder=$OPTARG;;
      # Printing error when flag is missing an argument.
      :) echo "Error: -${OPTARG} requires an argument."; exit 1;;
      # If unknown option, exit.
      *) echo "Error: you provided and unkown argument."; echo $USAGE; exit 1;;
    esac
  done
  # Checking if all mandatory flags were provided.
  if [[ $inputFlag = false || $outputFlag = false ]]
  then
    echo "Error: you forgot to provide input or output."
    echo $USAGE
    exit 1
  fi
  # Checking if inputFolder and outputFolder exist.
  if [[ ! -d $inputFolder ]] 
  then
    echo "Error: input_folder $inputFolder does not exist"
    exit 1
  elif [[ ! -d $outputFolder ]]
  then
    echo "Error: output_folder $outputFolder does not exist"
    exit 1
  else
    echo "input_folder and output_folder exist"
  fi
 
  # ----------------------------------------------------------------------
  # Checking if paths to input and output folders have the correct format.
  # ----------------------------------------------------------------------
  # Getting lengh of input and output path.
  lenInput=${#inputFolder}
  lenOutput=${#outputFolder}
  # Getting the last character if input and output path.
  lastCharInput=${inputFolder:lenInput - 1:1}
  lastCharOutput=${outputFolder:lenOutput - 1:1}
  # If last character in path is not "/" add the "/" to the path.
  if [[ ! $lastCharInput = "/" ]]
  then
    inputFolder="${inputFolder}/"
  fi
  if [[ ! $lastCharOutput = "/" ]]
  then
    outputFolder="${outputFolder}/"
  fi
  echo "Path input folder:  $inputFolder"
  echo "Path output folder: $outputFolder"
}


# -----------------------------------------------------------------------------
# Main.
# Arguments:
#   $@ : all arguments provided in the command line.
# -----------------------------------------------------------------------------
function main() {
  # -------------------
  # Getting user input.
  # -------------------
  parse_arguments $@

  # ------------------
  # Running unicycler.
  # ------------------
  printf "\nRunning unicycler\n"
  run_unicycler $inputFolder $outputFolder

  # ---------------------------------------------------------------
  # Extracting tables from unicycler.log files using log_parser.py.
  # Flags:
  #   -i : path to input folder.
  #   -o : path to output folder.
  # ---------------------------------------------------------------
  printf "\nExtracting tables from unicycler.log\n"
  python3 log_parser.py -i $outputFolder -o $outputFolder

  # ------------------------------------------------------------------------
  # Extracting fasta sequences from assembly.fasta using fasta_extractor.py.
  # Flags:
  #   -i : path to input folder and name of fasta file to be processed.
  #   -o : path to output folder. This flag is optional. If it is not provided
  #        the extracted fasta files will be saved in the same folder that
  #        contains the assembly.fasta used for the extraction.
  # ------------------------------------------------------------------------
  printf "\nExtracting fasta sequences from assembly.fasta\n"
  python3 fasta_extractor.py -i $outputFolder assembly.fasta

  # Make a folder to save a copy of all extracted fasta files
  mkdir $outputFolder/assemblies
  python3 fasta_extractor.py -i $outputFolder assembly.fasta\
  -o $outputFolder/assemblies 

  echo "unicycler_pipeline is done!"
}


# Let's have fun
main "$@"
