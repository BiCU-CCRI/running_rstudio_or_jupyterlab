#!/bin/bash
#SBATCH --partition=interactiveq
#SBATCH --qos=interactiveq
#SBATCH --cpus-per-task=1
#SBATCH --mem=8G
#SBATCH --time=12:00:00
#SBATCH --job-name=jupyter-lab
#SBATCH --output=jupyter-lab-%j.log

# get tunneling info
port=$(shuf -i8000-9000 -n1)
node=$(hostname).int.cemm.at
user=$(whoami)

host ${node}

# load modules
module load JupyterLab-R-autocomplete/4.9.0-foss-2023a-Python-3.11.3-R-4.2.3

# start jupyterlab session
jupyter lab --no-browser --port=${port} --ip=${node}