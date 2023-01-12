#!/bin/bash
set -e

ENV_DEST_DIR='deployments/epp/previews'
REPO='elifesciences/enhanced-preprints-client'
DOCKER_REPO="ghcr.io/elifesciences/enhanced-preprints-client"
ORG='elifesciences'

# First, remove all envs. They will be recreated, and there's no race issues because they will be in a single commit, which is atomic
if [ -d $ENV_DEST_DIR ]; then
    rm -r $ENV_DEST_DIR/* || true
else
    mkdir -p $ENV_DEST_DIR
fi

server_image=$(yq '.spec.images[] | select(.name=="ghcr.io/elifesciences/enhanced-preprints") | .newTag' deployments/epp/staging/epp-kustomization.yaml)

# now create all envs related to current open and labelled PRs
for pr in "$(gh pr list --repo $REPO --label preview --json number,potentialMergeCommit,mergeable,author | jq -c '.[]')"; do
    pr_mergable="$(echo $pr | jq .mergeable)"

    author="$(echo $pr | jq -r .author.login)"
    pr_id="$(echo $pr | jq .number)"
    pr_commit="$(echo $pr | jq -r .potentialMergeCommit.oid)"

    image_tag="preview-${pr_commit}"

    if ! docker manifest inspect $DOCKER_REPO:$image_tag > /dev/null; then
        echo "skipping PR $pr_id, image doesn't exist yet"
        continue;
    fi

    if curl -sqfL "https://api.github.com/orgs/${ORG}/members/${author}"; then
        echo "Creating env for PR $pr_id"

        ./scripts/build-epp-preview.sh "$pr_id" "$server_image" "$image_tag"
    else
        echo "Skipping PR with preview label when author ${author} isn't a member of ${ORG} org on github"
    fi
done

# now commit
# Done in script, so that if there is an error, the whole script exits (set -e), and nothing is committed.
git add $ENV_DEST_DIR
