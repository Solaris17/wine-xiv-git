#!/bin/bash

_exports_arm64() {
  CFLAGS="${CFLAGS//-msse3/}"
  CFLAGS="${CFLAGS//-mfpmath=sse/}"
  CXXFLAGS="${CXXFLAGS//-msse3/}"
  CXXFLAGS="${CXXFLAGS//-mfpmath=sse/}"
  export CFLAGS CXXFLAGS

  export arm64ec_CFLAGS="-O2 -pipe"
  export aarch64_CFLAGS="-O2 -pipe"
  export arm64ec_LDFLAGS=""
  export aarch64_LDFLAGS=""

  export i386_CFLAGS="${CROSSCFLAGS}"
  export x86_64_CFLAGS="${CROSSCFLAGS}"
  export i386_LDFLAGS="${CROSSLDFLAGS}"
  export x86_64_LDFLAGS="${CROSSLDFLAGS}"

  export AR="$(command -v llvm-ar)"
  export RANLIB="$(command -v llvm-ranlib)"
  export NM="$(command -v llvm-nm)"
  export OBJCOPY="$(command -v llvm-objcopy)"
  export STRIP="$(command -v llvm-strip)"
}

_configure_arm64() {
  msg2 'Configuring Wine ARM64/ARM64EC...'
  cd "${srcdir}/${pkgname}-64-build" || return 1
  chmod +x "../${_winesrcdir}/configure"

  "../${_winesrcdir}/configure" \
    --prefix="$_prefix" \
    --enable-archs=arm64ec,aarch64,i386 \
    --with-mingw=llvm-mingw \
    --disable-tests \
    "${_configure_args64[@]}" \
    "${_configure_args[@]}" || return 1

  if [ "$_pkg_strip" != "true" ]; then
    msg2 "Disable strip"
    sed 's|STRIP = strip|STRIP =|g' \
      "${srcdir}/${pkgname}-64-build/Makefile" -i
  fi
}

_build_arm64() {
  msg2 'Building Wine ARM64/ARM64EC...'
  cd "${srcdir}/${pkgname}-64-build" || return 1

  if [ "$_LOCAL_OPTIMIZED" = 'true' ]; then
    if [ "$_log_errors_to_file" = "true" ]; then
      make -j$(nproc) 2>"$_where/debug.log"
    else
      make -j$(nproc)
    fi
  else
    if [ "$_log_errors_to_file" = "true" ]; then
      make 2>"$_where/debug.log"
    else
      make
    fi
  fi
}

_build_serial() {
  if [ "$(uname -m)" != "aarch64" ]; then
    error "ARM64EC builds require an AArch64 host."
    return 1
  fi

  if [ "$_NOLIB32" != "wow64" ]; then
    error 'ARM64EC builds require _NOLIB32="wow64".'
    return 1
  fi

  _exports_arm64 || return 1
  _configure_arm64 || return 1
  _build_arm64 || return 1

  _protonify="false"
  _pkg_strip="false"
}
