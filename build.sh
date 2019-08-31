#!/usr/bin/env bash

set -euxfo pipefail;

build () {
  declare -r dockerfile_name="${1}";
  declare -r base_image="${2}";
  declare -r installer_url="${3}";
  declare -r version="${4}";
  declare -r variant="${5}";

  declare tag="jackfirth/racket:${version}"
  case "${variant}" in
      "-minimal") ;;

      "") tag="${tag}-full"
          ;;

      *) echo "error: unexpected variant '${variant}'"
         exit 1
         ;;
  esac

  docker image build \
      --file "${dockerfile_name}.Dockerfile" \
      --tag "${tag}" \
      --build-arg "BASE_IMAGE=${base_image}" \
      --build-arg "RACKET_INSTALLER_URL=${installer_url}" \
      --build-arg "RACKET_VERSION=${version}" \
      .;
};

installer_url () {
  declare -r version="${1}";
  declare -r installer_path="${2}";
  echo "http://mirror.racket-lang.org/installers/${version}/${installer_path}";
};

build_6x_7x () {
  declare -r version="${1}";
  for variant in "" "-minimal"; do
      installer_path="racket${variant}-${version}-x86_64-linux-natipkg.sh";
      installer=$(installer_url "${version}" "${installer_path}") || exit "${?}";
      build "racket" "buildpack-deps:stable" "${installer}" "${version}" "${variant}";
  done
};

build_6x_old () {
  declare -r version="${1}";
  declare -r installer_path="racket-minimal-${version}-x86_64-linux-natipkg-debian-squeeze.sh";
  declare -r installer=$(installer_url "${version}" "${installer_path}") || exit "${?}";
  build "racket" "buildpack-deps:wheezy" "${installer}" "${version}";
};

build_6x_old_ospkg () {
  declare -r version="${1}";
  declare -r installer_path="racket-minimal-${version}-x86_64-linux-debian-squeeze.sh";
  declare -r installer=$(installer_url "${version}" "${installer_path}") || exit "${?}";
  build "racket" "buildpack-deps:wheezy" "${installer}" "${version}";
};

foreach () {
  declare -r command="${1}";
  declare -r args="${@:2}";
  for _arg in ${args}; do
    "${command}" "${_arg}";
  done;
};

foreach build_6x_7x "7.4" "7.3" "7.2" "7.1" "7.0" "6.12" "6.11" "6.10.1" "6.10" "6.9" "6.8" "6.7" "6.6" "6.5";
foreach build_6x_old "6.4" "6.3" "6.2.1" "6.2" "6.1.1";
foreach build_6x_old_ospkg "6.1" "6.0.1" "6.0";
