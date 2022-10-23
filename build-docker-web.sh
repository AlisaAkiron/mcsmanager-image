VERSION="$1"
VERSION="${VERSION#[vV]}"

docker buildx build --load --platform linux/amd64 -t mcsmanager-web:${VERSION}-amd64 -f Dockerfile.web .
docker buildx build --load --platform linux/arm64 -t mcsmanager-web:${VERSION}-arm64 -f Dockerfile.web .
