## What this repository is about?
This repository is meant to be collection of small tools to improve neuro- and medical imaging. We collect scripts, notebooks or pipelines that help achieve that goal.


## Interesting things to look at
This is a growing list of resources that might help us in our task. At best once someone took a look, we create directory for each where we document what was learned:
 - datasets:
     - acute https://openneuro.org/datasets/ds004889/versions/1.1.2  described here https://pubmed.ncbi.nlm.nih.gov/39095364/
     - chronic https://openneuro.org/datasets/ds004884/versions/1.0.2 described here https://pubmed.ncbi.nlm.nih.gov/39251640/ -> already on HuggingFace: https://huggingface.co/datasets/hugging-science/arc-aphasia-bids
 - code:
     - https://github.com/Project-MONAI: a GitHub org that wants to improve all things AI related to healthcare imaging.
     - https://github.com/Project-MONAI/tutorial: Tutorials for MONAI models and transformations
     - lesion segmentation:
         - ISLES22:
            - https://isles22.grand-challenge.org/home/ a challenge to segment lesion after strokes
            - https://github.com/ezequieldlrosa/DeepIsles: more recent algorithm that bootstraps multiple previous solutions from the isles22 challenge, e.g. includes the one from mahfuzmohammad and others. Published in Nature.
            - https://github.com/mahfuzmohammad/isles22: A submitted solution for isles22, not actively maintained
     - fMRI foundation model: https://github.com/MedARC-AI/fmri-fm
     - Skull stripping: https://surfer.nmr.mgh.harvard.edu/docs/synthstrip/, for code see links below
 - papers:
     - SOTA lesion segmentation with few parameters: https://arxiv.org/html/2503.05531v1
