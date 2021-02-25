#!/bin/bash
#
# Created on Sunday Feb 7, 2021
# @author: ivanmugu
#
#
# Accessing folders and subfolders to retrieve information from files that
# contain Illumina and ONP reads to run unicycler.py. After running unicycler,
# the script will run log_parser.py and fasta_extractor.py. The log_parser.py
# program will get important information from the tables inside unicycler.log 
# file. The fasta_extractor.py will extract the individual fasta sequences
# generated inside assembly.fasta.
#
# TODO: to finish including log_parser and fasta_extractor in the code
#

# Function to print usage
# Does not get arguments
usage () {
  echo "usage: $0 [-h HELP] -i input_folder -o output_folder"
}

# Function to print help
# Does not get arguments
printHelp () {
  echo
  usage
  echo
  printf "Pipeline to assemble genomes\n\n"
  printf "mandatory aguments:\n"
  printf -- "-i input_folder        provide path to input folder\n"
  printf -- "-o output_folder       provide path to output folder\n\n"
  printf "optional arguments:\n"
  printf -- "-h                     show this help and exit\n\n"
  printf "To run this program you need a main folder. The input folder must\n"
  printf "contain subfolders with the Illumina and ONP reads that will be used\n"
  printf "for the assembly. For examle, you can have the following folders:\n"
  printf "input/\n"
  printf "    SW0001/\n"
  printf "        illumina_reads_1.fastq\n"
  printf "        illumina_reads_2.fastq\n"
  printf "        ONP_reads_L1000.fastq\n"
  printf "    SW0002/\n"
  printf "        illumina_reads_1.fastq\n"
  printf "        illumina_reads_2.fastq\n"
  printf "        ONP_reads_L1000.fastq\n\n"
  printf "The script will first analyze the data in folder SW0001 and put the\n"
  printf "result files in the output folder in a folder that will be named SW001.\n"
  printf "Then, the script will continue the same process with the folder SW0002\n"
  printf "present in the input folder. When the assembly is done, the unicycler.log\n"
  printf "files will be parsed to extract all the relevant information, generating\n"
  printf "two csv files. The csv files will be named molecules_summary and\n"
  printf "assemblies_summary, and will be located in the output folder.\n\n"
  printf "Usage example:\n"
  printf "pepito$ ./unicycler_pipeline.sh -i ~/Documents/input -o ~/Documents/output\n\n"
}

# Function to run unicycler
# Arguments
# --------
# input [$1] : path to input folder
# output [$2] : path to output folder
runUnicycler () {
  local input=$1
  local output=$2
  # Accessing folders from input 
  for folder in $(ls ./$input)
  do
      # Accessing subfolders from input
      for file in $(ls ./$input/$folder)
      do
          # Getting the names of arguments for unicycler
          # extention is used to identify the type of read
          extention=${file##*-}
          # Getting forward Illumina reads (1 indicates forward)
          if [[ "1.fastq" = $extention || "1.fastq.gz" = $extention ]]
          then
              forward=$file
          # Getting reverse Illumina reads (2 indicates reverse)
          elif [[ "2.fastq" = $extention || "2.fastq.gz" = $extention ]]
          then
              reverse=$file
          # Getting long ONP reads (L1000 indicates ONP)
          elif [[ "L1000.fastq" = $extention || "L1000.fastq.gz" = $extention ]]
          then
              long=$file
          # if file is not Illumina or ONP read ignore
          else
            continue
          fi
      done
      # Creating directory to save output of unicycler. The name of the directory in
      # the output folder will be the same as in the input folder
      mkdir ./$output/$folder
      
      # Running unicycler
      echo "Running unicycler with files from folder: $folder"
      unicycler -1 ./$input/$folder/$forward -2 ./$input/$folder/$reverse \
        -l ./$input/$folder/$long -t 32 --mode bold -o ./$output/$folder
      
      # Extracting tables from unicycler.log file
      # In this case, the input directory (-i) corresponds to the output
      # directory created to put the results of unicycler. We want to ananlyze
      # the files created in the output directory for unicycler. The results
      # are going to be put in the same directory. Therefore, output directory
      # (-o) is the same path as input directory (-i)
      echo "Extracting tables from unicycler.log"
      python3 log_parser.py -i ./$output/$folder -o ./$output/$folder

      # Extracting fasta sequences from assembly.fasta
      # -n means name of input fasta file and -d means path do input directory.
      # Because assembly.fasta is created in the output directory after running
      # unicycler, the input directory (-d) is going to the output directory of
      # unicycler.
      echo "Extracting fasta sequences from assembly.fasta"
      python3 fasta_extractor.py -n assembly.fasta -d ./$output/$folder 

      echo "Done"
  done
}

# Cheking provided arguments and getting inputFolder and outputFolder variables
# Arguments
# --------
# $@ : All arguments provided in the command line
parseArguments () {
  local option
  local inputFlag=false
  local outputFlag=false
  # Arguments to parse are -h -i and -o
  while getopts ":hi:o:" option
  do
    case $option in
      # Priting help
      h) printHelp; exit 1;;
      # Getting path to input folder
      i) inputFlag=true; inputFolder=$OPTARG;;
      # Getting path to output folder
      o) outputFlag=true; outputFolder=$OPTARG;;
      # Printing error when flag is missing argument
      :) echo "Error: -${OPTARG} requires an argument."; exit 1 ;;
      # If unknown option exit
      *) echo "Error: you provided and unkown argument."; usage; exit 1;;
    esac
  done
  # Checking if all mandatory flags were provided
  if [[ $inputFlag = false || $outputFlag = false ]]
  then
    echo "Error: you forgot to provide input or output."
    usage
    exit 1
  fi
  # Checking if inputFolder and outputFolder exist
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
 
  # Checking if paths to input and output folders have correct format
  #
  # Getting lengh of input and output path
  lenInput=${#inputFolder}
  lenOutput=${#outputFolder}
  # Getting the last character if input and output path
  lastCharInput=${inputFolder:lenInput - 1:1}
  lastCharOutput=${outputFolder:lenOutput - 1:1}
  # Checking format of input folder
  if [[ ! $lastCharInput = "/" ]]
  then
    inputFolder="${inputFolder}/"
  fi
  # Checking format of output folder
  if [[ ! $lastCharOutput = "/" ]]
  then
    outputFolder="${outputFolder}/"
  fi
  echo "Path input folder:  $inputFolder"
  echo "Path output folder: $outputFolder"
}

# main function
# Arguments
# ---------
# $@ : all the arguments provided in the command line
main () {
  parseArguments $@
  runUnicycler $inputFolder $outputFolder
  echo "Done!"
}

# Running the script
main $@
