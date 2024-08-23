# running_rstudio_singularity
how to get an rstudio server running with singularity on CeMM's cluster, VBC's CLIP or our local machines (those where singularity has been installed -- Biohazard and the GPU)

Patricia provided us with a sample sbatch submission script (file `rstudio-singularity-password.bash`) to get an rstudio server running on the CeMM cluster with singularity. Her email is included below:

> Dear all,
> 
>Per our last meeting, attached is a sample submission script for running rstudio server singularity jobs on the CeMM cluster.  Please replace the appropriate values: \<yourgroup\>, \<youruser\>, and the password.  Do not use your CeMM or CCRI password as this password will be in a text file.
>
>Prior to running the script, you can pull an appropriate singularity image.  For example from rocker:

 ```
    module load singularity
    cd /nobackup/<yourgroup>/<youruser>/rstudio
    singularity pull --name rstudio-4.2.simg docker://rocker/rstudio:4.2
 ```
>
>You can replace 4.2 with a different rocker rstudio image.  Also, you are not limited to rocker images.
>
>Cluster jobs running in the intereactiveq are limited to 12 hours, so your job will be killed after 12 hours.  Make sure to save your work prior to that.  
>
>The slurm job, much like the jupyter notebooks, will print the ip address and port that you should connect to; paste this into your browser.
>
>Kind Regards,
>
>Patricia

## Rstudio server on CeMM's cluster

Adapted Patricia's script to isolate different RStudio sessions based on the working directory of the session. The following changes were made:

* Slurm standard out log file gets written out to the directory where the script is run
* Working directory is set as the path from where the script is run
* The path to the singularity image is specified to the variable `singularityimage` at the top of the script, which is used in the singularity exec command.
* In the `SINGULARITY_BIND` variable, the path of the working directory on the CeMM cluster is bound to /home/$(whoami) in RStudio, instead of binding /home of the CeMM cluster to /home in RStudio

### Usage

1. Update the variables in the script to match your image name
2. Run `sbatch rstudio-singularity-password.bash`
3. Look into the file rstudio-singularity-%j.log which will have the following line right at the top 
   "Running RStudio at `machineIPaddress:port`"
4. In a terminal, enter the following command
   `ssh -N -f -L localhost:<port>:localhost:<port> <username>@<machineIPaddress>`
5. Open localhost:<port> in your browser
6. Login to the session with your username and the password specified in the run script 

### Rstudio server images available

**Singularity image of our docker image dockrstudio_4.2.0**
/nobackup/lab_ccri_bicu/public/apptainer_images/ccribioinf_dockrstudio_4.2.0-v1.sif
(DESeq2 is not able to be installed in the image due to `zlib.h` missing)

**Rocker tidyverse 4.4 image, built by Aleks**
/nobackup/lab_ccri_bicu/public/apptainer_images/tidyverse-4.4-jdk.sif
(DESeq2 installs successfully with this)



## Rstudio server on CCRI's machines

Adapted Patricia's script to CCRI's machines (original file `rstudio-singularity-password.bash`, new file `run_singularity_rstudio_ccri.sh`). The following changes were made:

* Removed sbatch commands
* Removed module load command
* Added a variable for singularityimage
* Added the R session default working directory to be printed into the R session configuration file 
* Removed /nobackup and /research from the `SINGULARITY_BIND` variable
* Added /scratch to the `SINGULARITY_BIND` variable

### Usage

1. Update the variables in the script to match your image name, R version and working directory
2. Start a tmux session
3. Run `bash run_singularity_rstudio_ccri.sh`
4. In a web browser go to the `machineIPaddress:port`, which will be printed to screen after starting the script

### Rstudio server singularity images available:

 `~/bioinf_isilon/core_bioinformatics_unit/Public/singularity_images/ccribioinf_dockrstudio_4.2.0-v1.sif`
  `~/bioinf_isilon/core_bioinformatics_unit/Public/singularity_images/wouter_m_dockrstudio_v4.3.2-V1.simg`