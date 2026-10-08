# Running RStudio Server images on clusters

Run RStudio Server with Apptainer/Singularity on the CeMM cluster (Apptainer/Singularity has to be available).

**Note:** You can use the included [`.gitignore`](.gitignore) to exclude RStudio Server files you likely do not want to track with `git`.

The following RStudio Server scripts are adapted from **Patricia Carey's** (CeMM IT) original script (`rstudio-singularity-password.bash`)
 which she kindly provided to us.

## RStudio Server on the CeMM cluster

**Do not use** your **CeMM** or **St. Anna CCRI** **password** as this password will be saved in a text file.

Cluster jobs running in the `intereactiveq` are limited to **12 hours**, so your job will be **killed** after 12 hours. Make sure
 to save your work before that.

Before running the script, you can pull an appropriate Apptainer image. For example, from [rocker](https://hub.docker.com/r/rocker/rstudio/tags)
 (when running an interactive cluster job!):

```bash
module load apptainer/1.1.9
export APPTAINER_CACHEDIR="/tmp"
export APPTAINER_TMPDIR="/tmp"

mkdir -p ${HOME}/rstudio_images

apptainer pull --name ${HOME}/rstudio_images/rstudio-4.2.sif docker://rocker/rstudio:4.2
```

The script:

- The default work directory is the directory from where the script is run. You can change the work directory at the top
 of the script in the variable `workdir`. This directory is mounted as your *home* directory in the RStudio (bottom right).
- The path to the Apptainer image is specified in the variable `rstudio_apptainer_image` at the top of the script.
- The `APPTAINER_BIND` variable stores all the bound paths to the running RStudio Server.
    - `/nobackup` and `/research` are mounted to the same paths in the running RStudio Server session.
- Prints standard Slurm out log file gets written out to `./logs`.
- Assigned interactive node and port is written to the `./logs/rstudio_apptainer_%j.log` where `%j` is the Slurm job ID.
    - You can simply `cmd+click` or `ctrl+click` the link in the log file to open the RStudio Server, or you can copy-paste
    the link to your web browser. Please note that you must be on the St. Anna CCRI or CeMM network for this to work.

### Usage

1. Copy the [`run_rstudio_apptainer_cemm.sbatch`](run_rstudio_apptainer_cemm.sbatch) script to your project directory.
2. Update the variables in the script to match your work directory (`workdir`), pulled image R version (`r_version`), and
 Apptainer image name (`rstudio_apptainer_image`).
3. Run `sbatch run_rstudio_apptainer_cemm.sbatch`.
4. Look into the `./logs/rstudio_apptainer_<job_id>.log` file for the link: "`http://<hostname>.int.cemm.at:<port>`".
  Note: The `<hostname>` is the node the job is running on (e.g., `d004`), and the `<port>` is the network port (between 8000
   and 9999 - these are available over the St. Anna CCRI network).
5. `cmd+click` or `ctrl+click` "`http://<hostname>.int.cemm.at:<port>`" link or copy-paste it into your web browser.
6. Log in with the username and password. You can find them in the slurm job logfile. Note: These are specified in the `run_rstudio_apptainer_cemm.sbatch` script (`APPTAINERENV_USER` and `APPTAINERENV_PASSWORD` variables).

#### Automatically loaded custom functions

You can use `./.Ractivate.R` to automatically load custom functions into RStudio Server at startup. An example `save_session()`
 function allows you to save both Rhistory (into `./.Rhistory`) and RData (into `./.RData`) with a single command. The saved
 history can be loaded into the next RStudio Server session to *reload* your previous progress and R objects.

### Provided RStudio Server images

You are not limited to the provided images. You can download your own.

Rocker tidyverse R v4.4 image, built by Aleks. Note: DESeq2 installs successfully with this:

- `/research/lab_ccri_bicu/public/apptainer_images/tidyverse-4.4-jdk.sif`

Apptainer/Singularity image of our Docker image dockrstudio_4.2.0. Note: DESeq2 cannot be installed in the image due to missing `zlib.h`:

- `/research/lab_ccri_bicu/public/apptainer_images/ccribioinf_dockrstudio_4.2.0-v1.sif`

## Extended information

- All the RStudio Server settings and files are saved in `<workdir>/.rstudio_server`. This includes the installed libraries.
 If you re-run the script from the same directory (with the same R version), all the previously installed libraries are
 automatically available.
- You might see `.cache`, `.config`, and `.local` directories, and `.Renviron` and `.Rhistory` files created in the directory from
     which you executed the script. These can be safely deleted as they are regenerated for each RStudio Server instance.
