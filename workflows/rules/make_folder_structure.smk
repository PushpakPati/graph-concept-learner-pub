rule make_folder_structure:
    input:
        main_cfg = "config/main_config.yaml",
        c1 = "default_configs/concept_1_radius.yaml",
        c2 = "default_configs/concept_2_knn.yaml",
        pretrain = "default_configs/pretrain_models_base_config.yaml",
        train = "default_configs/train_models_base_config.yaml",
        attributes = "default_configs/all_X_cols.yaml",
    resources:
        cores=1,
        mem="1G",
        queue="x86_1h",
    params:
        path_to_cfgs=f"{root}/prediction_tasks/{prediction_target}/{normalized_with}/configs"
    log:
        f"{root}/logs/make_folder_structure/make_folder_structure"
    shell:
        "scripts/make_folder_structure.py {input.main_cfg} && "
        "cp {input.c1} {input.c2} {params.path_to_cfgs}/concept_configs/ && "
        "cp {input.pretrain} {input.train} {params.path_to_cfgs}/base_configs/ && "
        "cp {input.attributes} {params.path_to_cfgs}/attribute_configs/"
