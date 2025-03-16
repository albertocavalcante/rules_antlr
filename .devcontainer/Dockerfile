ARG BASE_IMAGE=registry.access.redhat.com/ubi9/ubi-minimal
ARG BASE_IMAGE_TAG=9.5-1741850109

FROM ${BASE_IMAGE}:${BASE_IMAGE_TAG}

ARG BAZELISK_VERSION
ARG STARPLS_VERSION
ARG BUILDTOOLS_VERSION
ARG BAZEL_LSP_VERSION
ARG CONTAINER_USER=default
ARG CONTAINER_USER_ID=999

USER root

RUN set -ex \
    # Install required packages
    && microdnf install -y gzip tar gcc gcc-c++ make \
    # Clean up package manager cache
    && microdnf clean all \
    && rm -rf /var/cache/yum \
    # Ensure target user exists with specified UID/GID
    && if ! getent passwd ${CONTAINER_USER} > /dev/null; then \
         # Check if GID already used
         if getent group ${CONTAINER_USER_ID} > /dev/null; then \
           echo "GID ${CONTAINER_USER_ID} already exists, using a different GID"; \
           groupadd ${CONTAINER_USER}; \
         else \
           groupadd -g ${CONTAINER_USER_ID} ${CONTAINER_USER}; \
         fi; \
         # Check if UID already used
         if getent passwd ${CONTAINER_USER_ID} > /dev/null; then \
           echo "UID ${CONTAINER_USER_ID} already exists, using a different UID"; \
           useradd -g ${CONTAINER_USER} -m -s /bin/bash ${CONTAINER_USER}; \
         else \
           useradd -u ${CONTAINER_USER_ID} -g ${CONTAINER_USER} -m -s /bin/bash ${CONTAINER_USER}; \
         fi; \
       fi \
    # Set proper shell for the user
    && usermod -s /bin/bash ${CONTAINER_USER} \
    # Detect architecture and set appropriate binary architectures
    && ARCH=$(uname -m) \
    && if [ "${ARCH}" = "x86_64" ]; then \
         BAZELISK_ARCH="amd64"; \
         STARPLS_ARCH="amd64"; \
         BUILDTOOLS_ARCH="amd64"; \
         BAZEL_LSP_ARCH="amd64"; \
       elif [ "${ARCH}" = "aarch64" ]; then \
         BAZELISK_ARCH="arm64"; \
         STARPLS_ARCH="aarch64"; \
         BUILDTOOLS_ARCH="arm64"; \
         BAZEL_LSP_ARCH="arm64"; \
       else \
         echo "Unsupported architecture: ${ARCH}"; \
         exit 1; \
       fi \
    # Define function for installing tools
    && install_tool() { \
         local tool=$1 repo=$2 version=$3 arch=$4; \
         curl -fsSL -o "/usr/local/bin/${tool}" "https://github.com/${repo}/releases/download/v${version}/${tool}-linux-${arch}"; \
         chown $(id -u ${CONTAINER_USER}):$(id -g ${CONTAINER_USER}) "/usr/local/bin/${tool}"; \
         chmod u+x "/usr/local/bin/${tool}"; \
       } \
    # Download and setup tools
    && install_tool bazelisk bazelbuild/bazelisk ${BAZELISK_VERSION} ${BAZELISK_ARCH} \
    && install_tool starpls withered-magic/starpls ${STARPLS_VERSION} ${STARPLS_ARCH} \
    && install_tool buildifier bazelbuild/buildtools ${BUILDTOOLS_VERSION} ${BUILDTOOLS_ARCH} \
    && install_tool buildozer bazelbuild/buildtools ${BUILDTOOLS_VERSION} ${BUILDTOOLS_ARCH} \
    # Handle bazel-lsp separately
    && curl -fsSL -o /usr/local/bin/bazel-lsp "https://github.com/cameron-martin/bazel-lsp/releases/download/v${BAZEL_LSP_VERSION}/bazel-lsp-${BAZEL_LSP_VERSION}-linux-${BAZEL_LSP_ARCH}" \
    && chown $(id -u ${CONTAINER_USER}):$(id -g ${CONTAINER_USER}) /usr/local/bin/bazel-lsp \
    && chmod u+x /usr/local/bin/bazel-lsp \
    # Create symlinks
    && ln -s /usr/local/bin/bazelisk /usr/local/bin/bazel \
    && chown -h $(id -u ${CONTAINER_USER}):$(id -g ${CONTAINER_USER}) /usr/local/bin/bazel

USER ${CONTAINER_USER}

ENTRYPOINT ["/bin/bash"]
