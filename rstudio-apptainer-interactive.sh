#!/bin/bash
#SBATCH --job-name rstudio-apptainer-interactive
#SBATCH --partition=interactiveq
#SBATCH --qos=interactiveq
#SBATCH --nodes=1
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=1
#SBATCH --mem=32000
#SBATCH --time 12:00:00
#SBATCH --output rstudio-apptainer-%j.log

# Other common SLURM variables https://docs.hpc.shef.ac.uk/en/latest/referenceinfo/scheduler/SLURM/SLURM-environment-variables.html#gsc.tab=0
echo "======================"
echo "Working directory:     $SLURM_SUBMIT_DIR"
echo "Job name:              $SLURM_JOB_NAME"
echo "Job id:                $SLURM_JOB_ID"
echo "Job queue (partition): $SLURM_JOB_PARTITION"
echo "Job nodes, tasks, CPUs: $SLURM_JOB_NUM_NODES, $SLURM_NTASKS, $SLURM_NPROCS"
echo "Job node name:         $SLURM_NODELIST"
echo "Job node address:      $(nslookup $(hostname) | grep Name: | cut -f2)"
echo "Job node IP address:   $(nslookup $(hostname) | grep Address: | tail -1 | cut -d' ' -f2)"
echo "Node allocated CPUs:   $SLURM_CPUS_ON_NODE"
echo "======================"

module load apptainer/1.1.9

WORKDIR=$(pwd)
R_VERSION="4.4"
R_APPTAINER_IMG="/nobackup/lab_ccri_bicu/public/apptainer_images/tidyverse-4.4-jdk.sif"

mkdir -p -m 700 "${WORKDIR}/run" "${WORKDIR}/tmp" "${WORKDIR}/var/lib/rstudio-server" "${WORKDIR}/R/$R_VERSION"

cat > "${WORKDIR}/rsession.conf" <<END
# R Session Configuration File

r-libs-user="${WORKDIR}/R/%v"
session-timeout-minutes=0
END

# Set R_LIBS_USER to a path specific to rocker/rstudio to avoid conflicts with
# personal libraries from any R installation in the host environment

export APPTAINER_BIND="${WORKDIR}/run:/run,${WORKDIR}/tmp:/tmp,${WORKDIR}/rsession.conf:/etc/rstudio/rsession.conf,\
${WORKDIR}/var/lib/rstudio-server:/var/lib/rstudio-server,${WORKDIR}/run:/var/run,/nobackup:/nobackup,/research:/research,\
${WORKDIR}:/home/${USER}"

# Do not suspend idle sessions
# Alternative to setting session-timeout-minutes=0 in /etc/rstudio/rsession.conf
# https://github.com/rstudio/rstudio/blob/v1.4.1106/src/cpp/server/ServerSessionManager.cpp#L126
export APPTAINERENV_RSTUDIO_SESSION_TIMEOUT=0
export APPTAINERENV_USER="${USER}"
export APPTAINERENV_PASSWORD="test1"

# Get unused socket per https://unix.stackexchange.com/a/132524
readonly PORT=$(python -c 'import socket; s=socket.socket(); s.bind(("", 0)); print(s.getsockname()[1]); s.close()')
readonly ADD=$(nslookup $(hostname) | grep -i "address" | awk -F" " '{print $2}' | awk -F# '{print $1}' | tail -n 1)

cat 1>&2 <<END
Running RStudio at ${ADD}:${PORT}
Connect with: 
ssh -N -f -L localhost:${PORT}:localhost:${PORT} ${USER}@${ADD} 
on your local machine and paste:
localhost:${PORT}
to your web browser.
END

echo "======================"
echo "Job started at: $(date)"

apptainer exec \
    --cleanenv ${R_APPTAINER_IMG} \
    rserver --www-port ${PORT} \
            --server-user=${USER} \
            --auth-none=0 \
            --auth-pam-helper-path=pam-helper

echo "Job finished at: $(date)"

echo "Job stats:"
seff $SLURM_JOB_ID
echo "======================"
