ARG BASE_IMAGE=registry.access.redhat.com/ubi9/openjdk-17-runtime
ARG BASE_IMAGE_TAG=1.21-1.1741781260

FROM ${BASE_IMAGE}:${BASE_IMAGE_TAG}

ARG BAZELISK_VERSION
ARG STARPLS_VERSION
ARG BUILDTOOLS_VERSION
ARG TARGET_USER=default

USER root

RUN set -ex \
    # Install required packages
    && microdnf install -y gzip tar gcc gcc-c++ make \
    # Clean up package manager cache
    && microdnf clean all \
    && rm -rf /var/cache/yum \
    # Set proper shell for the user
    && usermod -s /bin/bash ${TARGET_USER} \
    # Detect architecture and set appropriate binary architectures
    && ARCH=$(uname -m) \
    && if [ "${ARCH}" = "x86_64" ]; then \
         BAZELISK_ARCH="amd64"; \
         STARPLS_ARCH="amd64"; \
         BUILDTOOLS_ARCH="amd64"; \
       elif [ "${ARCH}" = "aarch64" ]; then \
         BAZELISK_ARCH="arm64"; \
         STARPLS_ARCH="aarch64"; \
         BUILDTOOLS_ARCH="arm64"; \
       else \
         echo "Unsupported architecture: ${ARCH}"; \
         exit 1; \
       fi \
    # Define function for installing tools
    && install_tool() { \
         local tool=$1 repo=$2 version=$3 arch=$4; \
         curl -fsSL -o "/usr/local/bin/${tool}" "https://github.com/${repo}/releases/download/v${version}/${tool}-linux-${arch}"; \
         chown $(id -u ${TARGET_USER}):$(id -g ${TARGET_USER}) "/usr/local/bin/${tool}"; \
         chmod u+x "/usr/local/bin/${tool}"; \
       } \
    # Download and setup tools
    && install_tool bazelisk bazelbuild/bazelisk ${BAZELISK_VERSION} ${BAZELISK_ARCH} \
    && install_tool starpls withered-magic/starpls ${STARPLS_VERSION} ${STARPLS_ARCH} \
    && install_tool buildifier bazelbuild/buildtools ${BUILDTOOLS_VERSION} ${BUILDTOOLS_ARCH} \
    && install_tool buildozer bazelbuild/buildtools ${BUILDTOOLS_VERSION} ${BUILDTOOLS_ARCH} \
    # Create symlinks
    && ln -s /usr/local/bin/bazelisk /usr/local/bin/bazel \
    && chown -h $(id -u ${TARGET_USER}):$(id -g ${TARGET_USER}) /usr/local/bin/bazel

USER ${TARGET_USER}

ENTRYPOINT ["/bin/bash"]
