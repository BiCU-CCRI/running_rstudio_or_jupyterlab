# Running JupyterLab sessions on the CeMM cluster

How to run JupyterLab sessions on the CeMM cluster.


## Running JupyterLab with a standard Python 3 / R kernel

Patricia provides a sample sbatch submission script `jupyterlab.sbatch` to run a JupyterLab session on the CeMM cluster. This is also available on the CeMM Sharepoint.

1. Connect to a login node using ssh.

2. Copy the template JupyterLab sbatch submission script `jupyterlab.sbatch` to your project work directory.

3. Update the `#SBATCH` parameters in the script (`--mem`, `--time`, `--cpus-per-task`).

4. Run the script.
`sbatch jupyterlab.sbatch`

5. Scroll to the bottom of the `jupyter-lab-<jobID>.log` file to find the link starting with "`http//d0...`"

6. Copy and paste the link starting with "`http//d0...`" into your web browser. This should work from either the CCRI or the CeMM network.

7. Open your Jupyter notebook and choose your kernel.


## Running JupyterLab with your own environment as a kernel and/or using GPU nodes with JupyterLab

To use your own environment as a kernel and/or to access the CeMM GPU nodes via JupyterLab, you need to run Jupyter from your environment rather than using the module system. This is so that Jupyter can access the environment's kernels, and to ensure compatibility between your environment and Jupyter (the packages which are part of the standard JupyterLab module may be incompatible with other packages in your environment).

1. Connect to a login node using ssh.

2. Activate your conda/mamba environment.
`mamba activate <your-env-name`

3. Install `jupyterlab` in your conda/mamba environment.
`mamba install jupyterlab`

4. Check that ipykernel was also installed as a dependency of `jupyterlab` (should be listed when running this command).
`mamba list ipykernel` 

5. To add your environment as a kernel, run the following command.
`python -m ipykernel install --user --name <your-env-name> --display-name "<Your Env Name>"`

6. Copy the relevant sbatch submission script to your project work directory.
CPU usage only: `jupyterlab_customenv.sbatch`
GPU usage: `jupyterlab_customenv_gpu.sbatch`
The `#SBATCH` parameters in the GPU script are set up to allow access to 1 L4 GPU node. For more information on accessing GPU nodes on the CeMM cluster, check the relevant pages on the CeMM Sharepoint.

7. Update the `miniconda_path` and `env` variables in the script to match your environment, and update the `#SBATCH` parameters in the script (`--mem`, `--time`, `--cpus-per-task`).

8. Run the script.
CPU usage only: `sbatch jupyterlab_customenv.sbatch`
GPU usage: `sbatch jupyterlab_customenv_gpu.sbatch`

9. Scroll to the bottom of the `jupyter-lab-<jobID>.log` file to find the link starting with "`http//d0...`"

10. Copy and paste the link starting with "`http//d0...`" into your web browser. This should work from either the CCRI or the CeMM network.

11. Open your Jupyter notebook and choose your kernel. You should see your environment listed under the display name you chose.

Optional (GPU only):
12. For a quick test to see if you can access the GPU nodes via your JupyterLab session, use the `gpu_test.ipynb` notebook. If this doesn't work, check the `jupyter-lab-<jobID>.log` for detailed error messages which will help you to troubleshoot.

## Example environment

Building an environment in which to run Jupyter is dependent on what other packages your project requires. For an example of an environment which is used for training deep learning models using PyTorch via a JuptyerLab session on the CeMM cluster, check `example_env.yml` (you do not need to install all the packages in this environment for your project to run, but it might help you identify which versions of specific packages are compatible with each other.)