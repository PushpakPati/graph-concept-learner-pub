# Pretrain a graph concept learner
rule train_best_gcl_ERless_n_seeds:
    input:
        f"{root}/prediction_tasks/{prediction_target}/{normalized_with}/{split_how}/configs/train_model_configs", # Dependance w config gen
        paths_to_pretrain_configs=f"{root}/prediction_tasks/{prediction_target}/{normalized_with}/{split_how}/pretrain_results/best_model_per_concept/best_model_per_concept_ERless.yaml",
        path_to_train_config=f"{root}/prediction_tasks/{prediction_target}/{normalized_with}/{split_how}/configs/best_gcl_ERless_{{agg}}/{{config_id}}.yaml",
        path_to_datasets=f"{root}/prediction_tasks/{prediction_target}/{normalized_with}/{split_how}/processed_data",
        splits=f"{root}/prediction_tasks/{prediction_target}/{normalized_with}/{split_how}/meta_data/samples_splits.csv",
    output:
        expand(f"{root}/prediction_tasks/{prediction_target}/{normalized_with}/{split_how}/checkpoints/graph_concept_learners/"+"best_gcl_ERless_{{agg}}/{{config_id}}/test_conf_mat_from_best_val_{metric_name}.png", metric_name=config["follow_this_metrics"]),
        out_files=expand(f"{root}/prediction_tasks/{prediction_target}/{normalized_with}/{split_how}/checkpoints/graph_concept_learners/"+"best_gcl_ERless_{{agg}}/{{config_id}}/best_val_{metric_name}.pt", metric_name=config["follow_this_metrics"]),
    params:
        exclude=[
            "all_cells_contact",
            "all_cells_radius",
            "all_cells_ERless_contact",
            "all_cells_ERless_radius",
            "endothelial_contact",
            "endothelial_stromal_contact",
            "endothelial_tumor_contact",
            "immune_radius",
            "immune_endothelial_radius",
            "immune_stromal_radius",
            "immune_tumor_radius",
            "stromal_contact",
            "stromal_tumor_contact",
            "tumor_contact",
        ], # Concept/datasets present in path_to_datasets to exclude
        folder_name=normalized_with,
        split_strategy=split_how,
        run_type="train_ERless_gcl",
        randomize="False",
    resources:
        cores="1+1",
        mem="3G",
        queue="x86_6h",
    log:
        f"{root}/prediction_tasks/{prediction_target}/{normalized_with}/{split_how}/logs/train_gcl/best_gcl_ERless_{{agg}}/{{config_id}}"
    shell:
        "source scripts/setup_MLflow.sh && "
        "8_train/scripts/train_gcl.py "
        "{input.paths_to_pretrain_configs} {input.path_to_train_config} {input.path_to_datasets} {input.splits} "
        "{params.folder_name} {params.split_strategy} {params.randomize} "
        "{config[prediction_target]} {config[root]} {config[log_frequency]} "
        "{output.out_files} "
        "{params.run_type} "
        "{params.exclude}"
