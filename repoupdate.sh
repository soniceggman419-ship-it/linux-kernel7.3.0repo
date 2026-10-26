#!/usr/bin/env bash
set -Eeuo pipefail

# repoupdate.sh
# Regenerate APT package indexes for a Debian repository.

# Repository root: must contain dists/ and pool/

# Repository configuration
SUITES=(stable)
COMPONENTS=(main)
ARCHITECTURES=(amd64)

command -v apt-ftparchive >/dev/null || {
    echo "ERROR: Install apt-utils first." >&2
    exit 1
}

REPO="$(realpath "$REPO")"

[[ -d "$REPO/dists" && -d "$REPO/pool" ]] || {
    echo "ERROR: Expected dists/ and pool/ in $REPO" >&2
    exit 1
}

for SUITE in "${SUITES[@]}"; do
    DEST="$REPO/dists/$SUITE"

    [[ -d "$DEST" ]] || {
        echo "ERROR: Suite directory not found: $DEST" >&2
        exit 1
    }

    for COMPONENT in "${COMPONENTS[@]}"; do
        POOL="$REPO/pool/$COMPONENT"

        [[ -d "$POOL" ]] || {
            echo "ERROR: Pool component not found: $POOL" >&2
            exit 1
        }

        for ARCH in "${ARCHITECTURES[@]}"; do
            INDEX="$DEST/$COMPONENT/binary-$ARCH"
            mkdir -p "$INDEX"

            echo "Updating $SUITE/$COMPONENT/$ARCH"

            (
                cd "$REPO"
                apt-ftparchive -a "$ARCH" packages \
                    "pool/$COMPONENT"
            ) > "$INDEX/Packages"

            gzip -n -9 -c "$INDEX/Packages" \
                > "$INDEX/Packages.gz"

            xz -c "$INDEX/Packages" \
                > "$INDEX/Packages.xz"
        done
    done
done

echo "APT package indexes regenerated successfully."
echo "Run resign-repo.sh separately to regenerate and sign Release metadata."
