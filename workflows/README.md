# Workflow Tutorial

This workflow allows users to train and compare different Graph Concept Learners (GCLs). Make sure you have:

1. Setup the environment
2. Setup the working directory and placed the raw data inside it
3. Setup the configuration files

Once this is done run the following:

```bash
snakemake -c all pretrain_all // This will prepossess and pretrains
```

TODO: Write instruction for the rest of the workflow. E.g

```bash
snakemake -c 6 get_best_pretrain_models // TODO: must adjust this step/
snakemake -c 6 train_all
```

Depending on the size of the dataset, the type of graphs you are building, the number of models you are testing, and the computational resources you have available this might take from a few hours to more than a week.

One can also run specific parts of the workflow individually, which might be useful for debugging. To do so replace `<rule>` in the code below with one of the following.

- Make `SpatialOmics` object: `make_so`
- Filter out ill defined images: `filter_samples`
- Split samples `split_basel_leave_zurich_as_external` | `split_both_cohorts` | `split_zurich_leave_basel_as_external`
- Normalize data: `normalize_all_folds`
- Generates all concept graph datasets.: `gen_all_datasets`  # this does not produce any rules
- Attribute graphs: `gen_all_attributed_graphs`
- Pretrains all models: `pretrain_all`
- Train all models: `pretrain_all`

```bash
cd <path_to_local_graph_concept_learner_package>/workflows
snakemake <rule>
```

Take a look at the `<path_to_local_graph_concept_learner_package>/workflows/rules` for additional rules which might be useful.

---

# Setting-up the environment
## Software
Create a virtual environment with Python 3.8 and activate it (e.g. `conda create -n gcl python=3.8 && conda activate gcl`). Then install the following packages:

```bash
# Varia
pip install einops
pip install ruamel.yaml
pip install mlflow
pip3 install torch
pip install torch_geometric
pip install pre-commit
# pip install ai4scr-athena TODO: Until release this needs to be installed manually
pip install "PuLP<2.8"
conda install anaconda::pytables  # for arm64 install pytables with conda
pip install ai4scr-spatial-omics
pip install snakemake
```

If you have GPUs available install this:

```bash
pip install pyg_lib torch_scatter torch_sparse -f https://data.pyg.org/whl/torch-1.12.0+cu117.html
```

Otherwise this:

```bash
pip install pyg_lib torch_scatter torch_sparse torch_cluster torch_spline_conv -f https://data.pyg.org/whl/torch-2.0.0+cpu.html
```

Additionally, this workflow makes use of the `graph-concept-learner` packages that is not available through pip or conda so you need to be installed "manually". Clone this repo.

```bash
git clone <address_to_graph_concept-learner_package>
```
If you want to run things on a cluster, you can scp the repo into your home directory in the remote server.

```bash
cd $HOME
scp -r <path_to_local_graph_concept_learner_package> <path_to_$HOME_in_cluster>
```

Then proceed to install it.

```bash
cd $HOME/graph-concept-learner
pip install --upgrade pip setuptools wheel
pip install -r requirements.txt
pip install -e .
pre-commit install # In case you want to make commits and PRs
```

TODO: erase this comment when the repo name is changed `graph-concept-learner`
Note that `graph-concept-learner` also exists as `graph-concept-learner-pub`. You may have to adjust the above and below code correspondingly.

## Additional software
You need to install `q` a CLT that is used to pre-process the Jackson dataset. It is only available through brew or as a zip file. Zip file is the way to go if you want to install it in the cluster where brew is often not available. In your local machine...

```bash
wget https://github.com/harelba/q/archive/refs/tags/v3.1.6.tar.gz
```

Unzip it and then

```bash
scp -r q-3.1.6 <path_to_$HOME_in_cluster>
```

On the other hand, if you will only run things locally (not in the cluster) you can simply

```bash
brew install harelba/q/q
```

or

```bash
wget https://github.com/harelba/q/archive/refs/tags/v3.1.6.tar.gz
tar -xvf v3.1.6.tar.gz
sudo ln -s $(readlink -f q-3.1.6)/bin/q.py /usr/local/bin/q
```

> **The rest of the set-up is only for cluster use. Omit in case you want to run things in your local machine.**

## Cluster setup
### Your .bashrc

You can run the workflow either on a cluster setup or on you local machine.
For local runs no further configuration is required except for running the snakemake commands with the `--cores N` flag, where `N` is the number of cores you want to use on your local machine

If you want to run the workflow on a cluster you need to configure the submission of the cluster runs in a profile.
An example profile is provided in `$HOME/graph-concept-learner/workflows/profile`.  Adding the following to your `$HOME/.bashrc` will enable cluster execution:

```bash
export SNAKEMAKE_PROFILE=$HOME/graph-concept-learner/workflows/profile
```

### Adjust the workflow depending on the batch system of your cluster

The workflow supports SLURM and LSF batch systems. Users must specify in `$HOME/graph-concept-learner/workflows/profile/config.yaml` which one will be used.

For LSF in `$HOME/graph-concept-learner/workflows/profile/config.yaml`:

```bash
# Specify custom job submission wrapper
cluster: "../scripts/LSF_cluster_job.py"
```

For SLURM:

```bash
# Specify custom job submission wrapper
cluster: "../scripts/SLURM_cluster_job.py"

# Specify custom job status command wrapper
cluster-status: "../scripts/SLURM_cluster_status.py"
```

---

# Setup working directory and data
## Main configuration file
`<path_to_local_graph_concept_learner_package>/graph-concept-learner/workflows/config/main_config.yaml` is the main configuration file for the workflow. It looks like this:

```yaml
# Config file defining the location of the data and other information. No / at the end of the path.
root: "<local_path>/jackson"

# Prediction target. Must be a column present in the so.spl data frame.
prediction_target: "ERStatus"

# Normalization strategy to be used. Supported options: "min_max", "standard" or "None" (no normalization).
normalize_with: "min_max"

# Splitting strategy to be used (e.g. test and train/validation).
# Supported options: "both_cohorts", "split_zurich_leave_basel_as_external" or "split_basel_leave_zurich_as_external"
split_how: "split_basel_leave_zurich_as_external"

# Number of cross-validation folds to use
n_folds: 3

# Define metrics that should be used to save checkpoints. Supported options are: balanced_accuracy, weighted_f1_score, weighted_recall, weighted_precision, loss.
follow_this_metrics:
  - "balanced_accuracy"
  - "weighted_f1_score"

# Log frequency. The metrics will be logged into mlflow every n epochs.
log_frequency: 1

# Log the mlflow experiments to a remote server or in the local file system? (False = local, True = remote)
mlflow_on_remote_server: False
```

This configuration shown above is an example for th Jackson dataset on a ER-status prediction task. All the inputs, outputs, and intermediate files will be created inside the `root` folder specified here. You can find descriptions of the other fields in the example config above.

Several design choices are defined here and therefore users must modify this file according to their needs before proceeding. Notably you should already know:

1. the prediction target/task
2. how you want to split the data (into different cohorts) and how many cross-validation splits you wish to create.
3. the normalization strategy you which to use for the raw data
4. what metrics are you interested in (checkpoints will be saved according to these metrics) and how often you wish to log them
5. weather you will be logging to a remote server or locally

Once determined you can run the following command:

```bash
cd <path_to_local_graph_concept_learner_package>/workflows
snakemake -c 1 make_folder_structure
```

This will create the following folder structure with some example config files that must be adapted according to the user's needs. Folders names enclosed in `<>` represent fields that are specified in the `main_config.yaml`.

```bash
.
└── <root>
    ├── raw_data
    │   ├── unzipped
    │   └── zipped
    └── prediction_tasks
        └── <prediction_task>
            └── normalized_with_<normalize_with>
                └── configs
                    ├── attribute_configs
                    │   └── all_X_cols.yaml
                    ├── base_configs
                    │   ├── pretrain_models_base_config.yaml
                    │   └── train_models_base_config.yaml
                    ├── concept_configs
                    │   ├── concept_1_radius.yaml
                    │   └── concept_2_knn.yaml
                    └── pretrain_model_configs
                        ├── model_1.yaml
                        └── model_2.yaml
```

The default config files provide the user with an easy way to get started, however depending on the dataset that will be used the `concept_configs` might not be compatible. Therefore they do not provide a fail safe minimal working example. For the Jackson dataset they are in deed a minimal working example.

## The data

> The workflow takes care of gathering the raw data into a single object with all of the relevant information for GCL training and selection. In other words, given a raw spatial omics dataset a `SpatialOmics` object can be produced using the workflow. Since each dataset will be distributed differently (the data will be located in different folders and files with different names), this part of the workflow will be different for every dataset one wishes to use. As of now, we provide a sub-workflow for gathering data from the Jackson dataset.

Download the Jackson dataset from [here](https://zenodo.org/records/4607374) (all five files shown below). Unzip it and place the contents in `<root>/raw_data/zipped/`. The folder structure should look like this:

```bash
<root>/raw_data/zipped/
.
├── OMEandSingleCellMasks.zip
├── SingleCell_and_Metadata.zip
├── TumorStroma_masks.zip
├── singlecell_cluster_labels.zip
└── singlecell_locations.zip

```

All you need to do is place the data into the `<root>/raw_data/zipped/` directory. The workflow will then take care of unzipping the data (and placing it into the `<root>/raw_data/unzipped/` directory), and gathering it into a `SpatialOmics` object which will be placed in a folder that will be created by the workflow (`<root>/intermediate_data/so.pkl`).

> If you wish to use a different dataset see the Costume dataset section (TODO: reference section)

---

# Costume dataset

In case one wants to apply the workflow to a new dataset one needs to add a sub-workflow analogous to  `<path_to_local_graph_concept-learner_package>/graph-concept-learner/workflows/0_make_so_jackson` such that it produced a `<root>/intermediate_data/so.pkl` file (a `SpatialOmics` object) with the specifications described at the in the section bellow. Once created the `<path_to_local_graph_concept-learner_package>/graph-concept-learner/workflows/Snakefile` must be modified such that the correct sub-workflow is loaded. Namely, add the sub-workflow to the Python dictionary in `<path_to_local_graph_concept-learner_package>/graph-concept-learner/workflows/Snakefile`:

```python
import os
import pandas as pd

##### Set up #####
configfile: "./config/main_config.yaml"
include: "rules/make_folder_structure.smk"

# Make sure the dataset exists and a workflow for creating a so object also
supported_datasets = {
    "jackson": "0_make_so_jackson/Snakefile",
    "<name_of_dataset>": "0_make_so_<name_of_dataset>/Snakefile", # <- Subworkflow for new dataset
}
```

Notably, the key in this dictionary must be the name for the last directory in `<root>`.

## `SpatialOmics` object

The `SpatialOmics` class is implemented in ATHENA and allows us to conveniently and efficiently store the data in the same object for downstream preprocessing and graph construction. The relevant attributes of the `SpatialOmics` object that should be filled with the corresponding raw data are the following.

- The `X` attribute, a dictionary where every key-value pair corresponds to the sample id, and a pandas data frame where rows represent cells in the sample, and columns represent markers.
- The `obs` attribute, a dictionary where every key-value pair corresponds to the sample id, and a pandas data frame where rows represent cells in the sample and columns represent additional information about the cells (e.g. location, cell type).
- The `spl` attribute, a pandas data frame containing sample metadata (including the prediction labels for the intended prediction task).
- and `masks`, a nested dictionary supporting different types of segmentation cell masks. Each entry in the outer dictionary corresponds to a type of mask, and each key-value pair in the inner dictionary corresponds to the sample ID and binary numpy array, the mask.

---

# Configuration files
## Concepts configuration files

Each concept is fully defined by a config file. These configs should be placed in `<root>/prediction_tasks/<prediction_task>/normalized_with_<normalize_with>/configs/concept_configs`. The reason for this name is that each config will define a concept dataset, a collection of graphs constructed with a specific construction algorithm and a subset of the cells.

Each config should be named `<name_of_concept>.yaml` and should have the following structure.

```yaml
# Name of the concept
concept_name: <name_of_concept>

# Type of algorithm to use for graph construction. Supported options: "contact", "radius" and "knn"
builder_type: contact

# Depending on the builder_type chosen there will be a need to specify different building parameters. These here are the ones for the "contact" option.
builder_params:
  dilation_kernel: disk
  radius: 4
  include_self: true

# Name of the columns in the so.obs[<spl>] which hold the spatial location of the cell centroid.
coordinate_keys:
- location_center_x
- location_center_y

# Key in so.masks[<spl>] indicating the type of cell masks to use for the graph construction.
mask_key: cellmasks

# Boolean flag indicating whether the graphs will be constructed on all of the cells (false) or on a subset (true).
# Set to true and specify all cell types to avoid including cells without marker information.
build_concept_graph: true

# Parameters for subset graph construction. Only relevant if build_concept_graph is true.
concept_params:
  # Column name in so.obs[<spl>] to use to select the subset of the cell to be included in the graph
  filter_col: cell_class
  # Labels in the entries of so.obs[<spl>][<filter_col>] to include in the graph
  labels:
  - Vessel
  - Immune
  - Stroma
  - Tumor
```

For `radius` the `builder_params` are:

```yaml
builder_params:
  radius: 30
  mode: connectivity
  metric: minkowski
  p: 2
  metric_params:
  include_self: false
  n_jobs: -1
```

For `knn`:

```yaml
builder_params:
  n_neighbors: 4
  mode: connectivity
  metric: minkowski
  p: 2
  metric_params:
  include_self: false
  n_jobs: -1
```

## Attribution configuration files

Because the graph construction takes a considerable amount of time, it is more practical to first create the graphs and in a second step attribute them. This is especially useful in case one wishes to use cross-validation in which case, the attributes will be normalized separately for each fold leading to graph datasets with different attributes but the same connectivity in the individual graphs.

To attribute graphs the user must specify one config for each subset of attributes on whiches to use. For example:

```yaml
# Type of attributes to add to nodes in the graph. Supported options: "so"
attrs_type: so

# How to attribute the graph?
attrs_params:
  # Add attributes from so.obs[<spl>]?
  from_obs: false
  # If from_obs is true, which columns (specify a list of column names) from so.obs[<spl>] to add as attributes.
  obs_cols:

  # Add attributes from so.X[<spl>]?
  from_X: true
  # If from_X is true, which columns (specify a list of column names) from so.X[<spl>] to add as attributes.
  X_cols:
  - Ir193
  - Yb174
```

In the example above nodes would have two attributes, namely the expression from marker "Ir193" and "Yb174", information which is contained in the (fold-wise-normalized) `so.X[<spl>]`. Alternatively one can use all columns from either `so.obs` or `so.X` by setting `obs_cols: all` and `X_cols: all` respectively.

## Pretraining Models and hyperparameters configuration files

Before training a full GCL model individual GNNs are pretrained. This serves a double purpose; on one hand, we can define a zoo of models-hyperparameter combinations and choose the best-performing ones for our GCL. On the other hand, by saving checkpoints of these models we can train our GCL models with the best performing-pretrained GNN models, and fine-tune them while training the aggregator from scratch. This was shown to improve performance.

To define a zoo of models-hyperparameter combinations all a user needs to do is to specify a `<root>/prediction_tasks/<prediction_task>/normalized_with_<normalize_with>/configs/base_configs/pretrain_models_base_config.yaml`. Here is an example:

```yaml
# Pooling strategy to use to combine the processed node embeddings into a graph-level embedding. (str: {global_add_pool, global_mean_pool, global_max_pool})
# Look at https://pytorch-geometric.readthedocs.io/en/latest/modules/nn.html#pooling-layers for details.
pool:
  - "global_mean_pool"

# GNN model to use. (str: {GCN, SAGE, GAT, GIN})
# There are more models available. Should I consider more?
# Look at https://pytorch-geometric.readthedocs.io/en/latest/modules/nn.html#models for details.
gnn:
  - "PNA"
  - "GIN"

### GNN model parameters ###
# scalar * in_cheannels = hidden_channels = out_channels
# in_channels: the dimension of the initial node feature vectors, derived from the input.
# out_channels: should be the same as the hidden dimensions for our use case, derived from the input.
# scaler: integer that scales the in_cheannels to compute the hidden_channels.
scaler:
  - 1

# Number of hops/neighborhood layers to consider in the GNN model. (int >= 1)
num_layers:
  - 2

# Whether to use dropout or not. (bool)
dropout:
  - False

# Activation function to use within the GNN model. (str: {'ReLU6', 'PReLU', 'SiLU', 'Softmax2d', 'ReLU', 'Hardshrink', 'NonDynamicallyQuantizableLinear', 'SELU', 'swish', 'LeakyReLU', 'CELU', 'GELU', 'RReLU', 'Softplus', 'LogSigmoid', 'GLU', 'ELU', 'Threshold', 'Softmin', 'Hardswish', 'LogSoftmax', 'Sigmoid', 'Hardtanh', 'Tanh', 'Hardsigmoid', 'Module', 'MultiheadAttention', 'Softmax', 'Softshrink', 'Mish', 'Tanhshrink', 'Softsign'})
act:
  - "ReLU"

# Whether to apply the activation is applied before normalization (True), or after (False).
act_first:
  - False

# Normalization function to use within the GNN model. (str: {'GraphSizeNorm', 'BatchNorm', 'GraphNorm', 'PairNorm', 'MeanSubtractionNorm', 'InstanceNorm', 'LayerNorm', 'DiffGroupNorm', 'MessageNorm'})
norm:
  - "BatchNorm"
  - "LayerNorm"

# The Jumping Knowledge mode. If specified, the model will additionally apply a final linear transformation to transform node embeddings to the expected output feature dimensionality. (None, "last", "cat", "max", "lstm").
jk:
  - # None. Must leave the entry empty for it to be read as none when loading this file.

### Classification head parameters ###
# Number of layers in the MLP classifier
num_layers_MLP:
  - 2
  - 4

### Training parameters ###
# Batch size
batch_size:
  - 8

# Learning rate
lr:
  - 0.0001

# Optimizer (str).
# Only Adam and SGD are supported.
optim:
  - "Adam"

# Number of epochs
n_epoch:
  - 100

# Learning rate decay strategy to use.
# For ExponentialLR, the second value in the list corresponds to the gamma parameter.
# For LambdaLR, the second value in the list corresponds to the divisor by which the lr is divided each every x epochs,
# where x is the third value in the list. Only these two strategies are supported.
scheduler:
  - ["ExponentialLR", 0.98]

# Seed. Specifying multiple seeds will result in multiple runs with the same configuration but different initialization.
seed:
  - 1
```

Each field must have at least one non-empty entry (except for `jk` which accepts an empty entry as shown above). The cross product of all options specified is computed (automatically by the workflow) and a config for each combination is generated and stored as `<root>/prediction_tasks/<prediction_task>/normalized_with_<normalize_with>/configs/pretrain_configs/<confgi_id>.yaml`.

## Training models and hyperparameters configuration files

Similar to the way we specified `pretrain_models_base_config.yaml` we must specify a `<root>/prediction_tasks/<prediction_task>/normalized_with_<normalize_with>/configs/base_configs/train_models_base_config.yaml`. The cross product of all options specified will be computed (automatically by the workflow) generating a config file for each model-hyperparameter combination to be trained. Here is an example base config file.

TODO: Update this...
```yaml
### Training parameters ###
# Batch size
batch_size:
  - 8

# Learning rate for the aggregator
agg_lr:
  - 0.0001

# Learning rate for the concept gnn's
gnns_lr:
  - 0.00001

# Optimizer (str).
# Only Adam and SGD are supported.
optim:
  - "Adam"

# Number of epochs
n_epoch:
  - 200

# Learning rate decay strategy to use.
# For ExponentialLR, the second value in the list corresponds to the gamma parameter.
# For LambdaLR, the second value in the list corresponds to the divisor by which the lr is divided each every x epochs,
# where x is the third value in the list. Only these two strategies are supported.
scheduler:
  - ["ExponentialLR", 0.98]

# Seed. Specifying multiple seeds will result in multiple runs with the same configuration but different initialization.
seed:
  - 1

### Agregator parameters ###
# Type of aggregator. str: (transformer, concat, linear)
aggregator:
  - "transformer"

# Number of layers in the final mlp classifier
mlp_num_layers:
  - 2

# String representation of the activation function to use in the final mlp classifier. str (relu, tanh)
mlp_act_key:
  - "relu"

### Parameters for transformer ###
# If aggregator != "transformer" then these are ignored
# Number or MultiHeadAttention heads.
n_heads:
  - 8

# Number of staked TransformerEncoderLayer stacked.
depth:
  - 1
  - 2

# Define a scalar that computes the dimension of the feedforward network model, s.t.
# scaler * output_graph_embedding = dim_feedforward
scaler:
  - 4
  - 8
```

Once all of the inputs are set, we are ready to run the workflow.
