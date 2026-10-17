# Allow build scripts to be referenced without being copied into the final image
FROM scratch AS ctx
COPY build_files /

# Base Image
# quay.io/fedora/fedora-toolbox:43-aarch64
FROM quay.io/fedora/fedora-toolbox@sha256:1575e47fc098e4861af3aa8befee8b5d1c23567559eeb3d567d78ef804ffffc2 AS builder

# Build container
RUN --mount=type=cache,dst=/var/cache \
    --mount=type=cache,dst=/var/log \
    --mount=type=bind,from=ctx,source=/,target=/ctx \
    --mount=type=tmpfs,dst=/tmp \
    /ctx/build

# https://github.com/coreos/chunkah
FROM quay.io/jlebon/chunkah AS chunkah

# Rechunk
ARG SOURCE_DATE_EPOCH
ENV SOURCE_DATE_EPOCH=${SOURCE_DATE_EPOCH}
RUN --mount=from=builder,src=/,target=/chunkah,ro \
    --mount=type=bind,target=/run/src,rw \
    chunkah build > /run/src/out.ociarchive

# Deploy final chunked image
FROM oci-archive:out.ociarchive
