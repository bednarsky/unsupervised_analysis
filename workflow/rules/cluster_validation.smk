        
# clustree analysis
rule clustree_analysis:
    input:
        unpack(get_clustree_paths),
    output:
        plot = report(os.path.join(config["result_path"],'unsupervised_analysis','{sample}','clustree','{content}.png'),
                               caption="../report/clustree.rst", 
                               category="{}_{}".format(config["project_name"], module_name),
                               subcategory="{sample}",
                      labels={
                          "method": "clustree",
                          "parameters": "-",
                          "dimensions": "-",
                          "type": "clustree",
                          "content": "{content}",
                      }
                     ),
    resources:
        mem_mb=config.get("mem", "16000"),
    threads: config.get("threads", 1)
    conda:
        "../envs/clustree.yaml"
    log:
        os.path.join("logs","rules","clustree_{sample}_{content}.log"),
    params:
        content = lambda w: "{}".format(w.content),
        count_filter = config["clustree"]["count_filter"],
        prop_filter = config["clustree"]["prop_filter"],
        layout = config["clustree"]["layout"],
        categorical_label_option = config["clustree"]["categorical_label_option"],
        numerical_aggregation_option = config["clustree"]["numerical_aggregation_option"],
        custom_metadata = config["metadata_of_interest"],
    script:
        "../scripts/clustree.R"
        
# clustree analysis for highlighting individual metadata and features
rule clustree_analysis_metadata:
    input:
        unpack(get_clustree_paths),
    output:
        plot = report(directory(os.path.join(config["result_path"],'unsupervised_analysis','{sample}','clustree','{content}')),
                      patterns=["{metadata}.png"],
                      caption="../report/clustree.rst", 
                               category="{}_{}".format(config["project_name"], module_name),
                               subcategory="{sample}",
                      labels={
                          "method": "clustree",
                          "parameters": "-",
                          "dimensions": "-",
                          "type": "{content}",
                          "content": "{metadata}",
                      }
                     ),
    resources:
        mem_mb=config.get("mem", "16000"),
    threads: config.get("threads", 1)
    conda:
        "../envs/clustree.yaml"
    log:
        os.path.join("logs","rules","clustree_{sample}_{content}.log"),
    params:
        content = lambda w: "{}".format(w.content),
        count_filter = config["clustree"]["count_filter"],
        prop_filter = config["clustree"]["prop_filter"],
        layout = config["clustree"]["layout"],
        categorical_label_option = config["clustree"]["categorical_label_option"],
        numerical_aggregation_option = config["clustree"]["numerical_aggregation_option"],
        custom_metadata = config["metadata_of_interest"],
    script:
        "../scripts/clustree.R"

# determine external cluster indices
rule validation_external:
    input:
        unpack(get_external_validation_paths),
    output:
        expand(os.path.join(config["result_path"],"unsupervised_analysis","{{sample}}", "cluster_validation", "external_index_{index}.csv"), index=indices_external),
    resources:
        mem_mb=config.get("mem", "16000"),
    threads: config.get("threads", 1)
    conda:
        "../envs/umap_leiden.yaml"
    log:
        os.path.join("logs","rules","validation_external_{sample}.log"),
    script:
        "../scripts/validation_external.py"
        
# determine internal cluster indices
rule validation_internal:
    input:
        unpack(get_internal_validation_paths),
    output:
        internal_indices = os.path.join(config["result_path"],"unsupervised_analysis","{sample}", "cluster_validation", "internal_index_{internal_index}.csv"),
    resources:
        mem_mb=2*int(config.get("mem", "16000")),
    threads: config.get("threads", 1)
    conda:
        "../envs/clusterCrit.yaml"
    log:
        os.path.join("logs","rules","validation_internal_{internal_index}_{sample}.log"),
    params:
        internal_index = lambda w: "{}".format(w.internal_index),
        sample_proportion = config["sample_proportion"],
        metadata_of_interest = config["metadata_of_interest"],
    script:
        "../scripts/validation_internal.R"
        
# rank internal cluster indices using MCDM method TOPSIS
rule aggregate_rank_internal:
    input:
        expand(os.path.join(config["result_path"],"unsupervised_analysis","{{sample}}", "cluster_validation", "internal_index_{index}.csv"), index=indices_internal),
    output:
        internal_indices_ranked = os.path.join(config["result_path"],"unsupervised_analysis","{sample}", "cluster_validation", "internal_indices_ranked.csv"),
    resources:
        mem_mb=config.get("mem", "16000"),
    threads: config.get("threads", 1)
    conda:
        "../envs/pymcdm.yaml"
    log:
        os.path.join("logs","rules","rank_internal_{sample}.log"),
    script:
        "../scripts/mcdm_topsis.py"


# plot cluster indices as hierarchically clustered heatmaps
rule plot_indices:
    input:
        unpack(get_validation_paths),
    output:
        plot = report(directory(os.path.join(config["result_path"],'unsupervised_analysis','{sample}','cluster_validation','plots','{type}')),
                      patterns=["{index}.png"],
                      caption="../report/cluster_validation.rst", 
                               category="{}_{}".format(config["project_name"], module_name),
                               subcategory="{sample}",
                      labels={
                          "method": "cluster validation",
                          "parameters": "-",
                          "dimensions": "-",
                          "type": "{type}",
                          "content": "{index}",
                      }
                     ),
    resources:
        mem_mb=config.get("mem", "16000"),
    threads: config.get("threads", 1)
    conda:
        "../envs/ggplot.yaml"
    log:
        os.path.join("logs","rules","plot_{type}_indices_{sample}.log"),
    script:
        "../scripts/plot_indices.R"