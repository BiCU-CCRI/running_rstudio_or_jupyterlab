#!/bin/bash
#SBATCH --partition=interactiveq
#SBATCH --qos=interactiveq
#SBATCH --cpus-per-task=1
#SBATCH --mem=8G
#SBATCH --time=12:00:00
#SBATCH --job-name=jupyter-lab
#SBATCH --output=jupyter-lab-%j.log

# Unused port between 8000 and 9999
port="$(comm -23 <(seq 8000 9999) \
    <(ss -Htan | awk '{print $4}' | cut -d':' -f2 | grep "[0-9]\{1,5\}" | sort -u) | shuf -n 1)"
readonly port
if [[ -z "${port}" ]]; then
    echo "ERROR: no free port found between 8000 and 9999" >&2
    exit 1
fi
node="$(hostname).int.cemm.at"
readonly node
user=$(whoami)

host "${node}"

# Load modules
module load JupyterLab-R-autocomplete/4.9.0-foss-2023a-Python-3.11.3-R-4.2.3

# Start jupyterlab session
jupyter lab --no-browser --port="${port}" --ip="${node}"
