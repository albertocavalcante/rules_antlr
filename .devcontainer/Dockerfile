ARG BASE_IMAGE=registry.access.redhat.com/ubi9/openjdk-17-runtime
ARG BASE_IMAGE_TAG=1.21-1.1741781260

FROM ${BASE_IMAGE}:${BASE_IMAGE_TAG}

ARG BAZELISK_VERSION
ARG STARPLS_VERSION
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
       elif [ "${ARCH}" = "aarch64" ]; then \
         BAZELISK_ARCH="arm64"; \
         STARPLS_ARCH="aarch64"; \
       else \
         echo "Unsupported architecture: ${ARCH}"; \
         exit 1; \
       fi \
    # Download and setup Bazelisk
    && curl -fsSL -o /usr/local/bin/bazelisk https://github.com/bazelbuild/bazelisk/releases/download/v${BAZELISK_VERSION}/bazelisk-linux-${BAZELISK_ARCH} \
    # Download and setup Starpls
    && curl -fsSL -o /usr/local/bin/starpls https://github.com/withered-magic/starpls/releases/download/v${STARPLS_VERSION}/starpls-linux-${STARPLS_ARCH} \
    # Set up permissions and create symlinks
    && chown $(id -u ${TARGET_USER}):$(id -g ${TARGET_USER}) /usr/local/bin/bazelisk \
    && chown $(id -u ${TARGET_USER}):$(id -g ${TARGET_USER}) /usr/local/bin/starpls \
    && chmod u+x /usr/local/bin/bazelisk \
    && chmod u+x /usr/local/bin/starpls \
    && ln -s /usr/local/bin/bazelisk /usr/local/bin/bazel \
    && chown -h $(id -u ${TARGET_USER}):$(id -g ${TARGET_USER}) /usr/local/bin/bazel

USER ${TARGET_USER}

ENTRYPOINT ["/bin/bash"]
