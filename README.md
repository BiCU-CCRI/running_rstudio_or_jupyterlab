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


