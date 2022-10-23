VERSION="$1"
VERSION="${VERSION#[vV]}"

docker buildx build --load --platform linux/amd64 -t mcsmanager-daemon:${VERSION}-amd64 -f Dockerfile.daemon .
docker buildx build --load --platform linux/arm64 -t mcsmanager-daemon:${VERSION}-arm64 -f Dockerfile.daemon .
