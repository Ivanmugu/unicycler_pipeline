# unicycler_pipeline
Pipeline to assemble genomes using Unicycler.

## Function

To run this program you need a main folder. The input folder must contain
subfolders with the Illumina and ONP reads that will be used for the assembly.
For example, you can have the following tree folder structure:

```
~/Documents/input/
              SW0001/
                  illumina_reads_1.fastq
                  illumina_reads_2.fastq
                  ONP_reads_L1000.fastq
              SW0002/
                  illumina_reads_1.fastq
                  illumina_reads_2.fastq
                  ONP_reads_L1000.fastq
```

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

## Example of usage

```bash
$ ./unicycler_pipeline.sh -i ~/Documents/input -o ~/Documents/output
```

A tree example of a hypothetical results using the input folder described
before could be the one shown below. To handle future manipulation of the
extracted fasta files, a new folder named assemblies inside output will also
contained the extracted fasta files.

```
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
```

## Notes

Information about the programs used in unicycler_pipeline can be found in:

  *  unicycler: https://github.com/rrwick/Unicycler
  *  log_parser: https://github.com/Ivanmugu/log_parser
  *  fasta_extractor: https://github.com/Ivanmugu/fasta_extractor
