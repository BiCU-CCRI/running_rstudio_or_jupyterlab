#!/bin/bash
#SBATCH --partition=interactiveq
#SBATCH --qos=interactiveq
#SBATCH --cpus-per-task=1
#SBATCH --mem=8G
#SBATCH --time 12:00:00
#SBATCH --job-name jupyter-lab
#SBATCH --output jupyter-lab-%j.log

# update these variables before running the script
miniconda_path=/path/to/your/miniconda3
env=example_env

# get tunneling info
port=$(shuf -i8000-9999 -n1)
node=$(hostname).int.cemm.at
user=$(whoami)

host ${node}

# activate your environment - no need to update this command
echo "Activating environment"
source ${miniconda_path}/bin/activate ${env}

# start jupyterlab session
jupyter lab --no-browser --port=${port} --ip=${node}

