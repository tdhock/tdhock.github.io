---
layout: post
title: Cloud Storage
description: Different options for internal and external sharing
---

## Sherbrooke

At Sherbrooke we have a couple of options,

- [OneDrive](https://www.usherbrooke.ca/services-informatiques/repertoire/collaboration/microsoft-365/onedrive): 1TB, maybe use [DriveToWeb](https://www.drv.tw/#how) for sharing results on public web pages?
- [Alliance Canada project
  space](https://docs.alliancecan.ca/wiki/Storage_and_file_management#Filesystem_quotas_and_policies):
  1TB, [shareable with collaborators via copy to globus shared
  endpoint](https://docs.alliancecan.ca/wiki/Sharing_data).
- [EspaceWeb](https://www.usherbrooke.ca/services-informatiques/repertoire/applications/espace-web#acc-4085-1131): 1GB, web access.

## NAU

Here is a summary of my current understanding of cloud storage options
available to NAU researchers, and to our collaborators. [Link to official
docs](https://in.nau.edu/its/filesharing-storage/).

- [OneDrive](https://in.nau.edu/its/onedrive-for-business/): 1TB free,
  unable to share with anyone on the internet (only with NAU or people
  on a list who login, called to confirm this with ITS on 5 Sep 2023).
- [GoogleDrive](https://in.nau.edu/its/google-drive/): 25GB free (able
  to share with anyone on the internet without having them login).
- [Dropbox](https://nau.service-now.com/sp?id=kb_article&article=KB0014469):
  unlimited for $180 per year.
- [Bonsai](https://in.nau.edu/its/bonsai/): NAU students have access
  to 6 gigabytes of free storage, and faculty and staff have access to
  25 gigabytes of free storage. Only you have access (no
  sharing). Backed up daily for over a month and are accessible from
  any computer with an Internet connection.
- [NAUShares](https://in.nau.edu/its/naushares/) can be accessed by
  any student, faculty, or staff member if they have been given proper
  permission to access their departments' NAUShares. (but no access by
  outside collaborators)

On Monsoon PIs have 1TB free storage under their /project directory,
and those files can be shared via:

- [Globus](https://www.globus.org/): collaborators can send you files
  too, setup group in globus, then setup a share, then collaborators
  can upload to some directory on your monsoon project space.
- [rcdata](https://in.nau.edu/arc/data-portal/): Monsoon projects web
  sharing. You do `cd /projects/genomic-ml` on monsoon, then run
  `publish_data path/to/folder` then others can access at
  <https://rcdata.nau.edu/genomic-ml/>

## Anybody

- Another publishing option is github pages, but there are space
  limitations:
  - [max of 100MiB per file](https://docs.github.com/en/repositories/working-with-files/managing-large-files/about-large-files-on-github),
  - [git large file
    storage](https://docs.github.com/en/repositories/working-with-files/managing-large-files/about-storage-and-bandwidth-usage)
    can be used to store files larger than that, but there is a limit
    of 1GB of storage and monthly bandwidth per repo.
  - [max number of repositories per user/org is 100,000](https://docs.github.com/en/repositories/creating-and-managing-repositories/repository-limits#organization-limits)
  - I have not seen any limits on the number of files.
  - [This SO
    post](https://stackoverflow.com/questions/38768454/repository-size-limits-for-github-com)
    has a nice discussion of the limits, including links to limits of
    other services like
    [GitLab](https://docs.gitlab.com/user/storage_usage_quotas/) and
    [Bitbucket](https://www.atlassian.com/blog/it-teams/important-changes-coming-to-bitbucket-clouds-free-plan).
- Google Drive: 10GB.
- Hugging Face (can be used by github commands): a total storage capacity of 300 GB per repo, with a maximum file size of 20 GB and a limit of 100,000 files per repo. For example, my student repository contains genome sequences, such as the one found here: [chipseq](https://huggingface.co/datasets/lamtung16/compressed_chipseq).
