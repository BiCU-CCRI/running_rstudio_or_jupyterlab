# Running RStudio server images on clusters

How to get an rstudio server running with singularity on CeMM's cluster, VBC's CLIP
 or our local machines (those where singularity has been installed -- Biohazard and
 the GPU)

Patricia provided us with a sample sbatch submission script file `rstudio-apptainer-interactive.sh`
 (ex. `rstudio-singularity-password.bash`) to get an rstudio server running on the
  CeMM cluster with singularity. Her email is included below:

> Dear all,
> 
>Per our last meeting, attached is a sample submission script for running rstudio
 server singularity jobs on the CeMM cluster.  Please replace the appropriate
  values: \<yourgroup\>, \<youruser\>, and the password.  Do not use your CeMM or
   CCRI password as this password will be in a text file.
>
>Prior to running the script, you can pull an appropriate singularity image. For
 example from rocker:

```bash
module load singularity
cd /nobackup/<yourgroup>/<youruser>/rstudio/
singularity pull --name rstudio-4.2.simg docker://rocker/rstudio:4.2
 ```
>
>You can replace 4.2 with a different rocker rstudio image.  Also, you are not limited
 to rocker images.
>
>Cluster jobs running in the intereactiveq are limited to 12 hours, so your job
 will be killed after 12 hours.  Make sure to save your work prior to that.  
>
>The slurm job, much like the jupyter notebooks, will print the ip address and port
 that you should connect to; paste this into your browser.
>
>Kind Regards,
>
>Patricia

## Rstudio server on CeMM's cluster

Adapted Patricia's script to isolate different RStudio sessions based on the working
 directory of the session. The following changes were made:

- Slurm standard out log file gets written out to the directory where the script
 is run
- Working directory is set as the path from where the script is run
- The path to the Apptainer image is specified to the variable `r_apptainer_img`
 at the top of the script, which is used in the Apptainer exec command.
- In the `APPTAINER_BIND` variable, the path of the working directory on the CeMM
 cluster is bound to `/home/${USER}` in RStudio, instead of binding `/home` of
 the CeMM cluster to `/home` in RStudio
- SSHing into the interactive node to set up port forwarding is no longer necessary - 
  you can copy-paste the link in the log file directly into the browser from the CCRI 
  or CeMM networks.

### Usage

1. Copy the [`rstudio_apptainer_interactive.sh`](rstudio_apptainer_interactive.sh)
  script to your project work directory
2. Update the variables in the script to match your image name
3. Run `sbatch rstudio_apptainer_interactive.sh`
4. Look into the `rstudio_apptainer_interactive_<jobID>.log` file for the link: "`http://<hostname>.int.cemm.at:<port>`"
  The hostname is the node the job is running on (e.g. d004) and the port is the network port (between 8000 and 9000 - these are available over the CCRI network). 
5. Copy-paste the "`http://<hostname>.int.cemm.at:<port>`" link into your web browser (or cmd + click if using a Mac)
6. Login with the username and password specified in the `rstudio_apptainer_interactive.sh` script (`APPTAINERENV_USER` and `APPTAINERENV_PASSWORD`)

### Available Rstudio server images

#### Prefered image

Rocker tidyverse 4.4 image, built by Aleks. Note: DESeq2 installs successfully with
 this: \
`/nobackup/lab_ccri_bicu/public/apptainer_images/tidyverse-4.4-jdk.sif`

#### Other images

Singularity image of our docker image dockrstudio_4.2.0. Note: DESeq2 is not able
 to be installed in the image due to `zlib.h` missing: \
`/nobackup/lab_ccri_bicu/public/apptainer_images/ccribioinf_dockrstudio_4.2.0-v1.sif`\

## Rstudio server on CCRI's machines

Adapted Patricia's script to CCRI's machines (original file `rstudio-apptainer-interactive.sh` (ex.`rstudio-singularity-password.bash`), new file `run_singularity_rstudio_ccri.sh`).
 The following changes were made:

- Removed sbatch commands
- Removed module load command
- Added a variable for singularityimage
- Added the R session default working directory to be printed into the R session configuration file
- Removed /nobackup and /research from the `SINGULARITY_BIND` variable
- Added /scratch to the `SINGULARITY_BIND` variable

### Usage

1. Update the variables in the script to match your image name, R version and working
2.  directory
3. Start a tmux session
4. Run `bash run_singularity_rstudio_ccri.sh`
5. In a web browser go to the `machineIPaddress:port`, which will be printed to
6.  screen after starting the script

### Rstudio server singularity images available:

 `~/bioinf_isilon/core_bioinformatics_unit/Public/singularity_images/ccribioinf_dockrstudio_4.2.0-v1.sif`
  `~/bioinf_isilon/core_bioinformatics_unit/Public/singularity_images/wouter_m_dockrstudio_v4.3.2-V1.simg`