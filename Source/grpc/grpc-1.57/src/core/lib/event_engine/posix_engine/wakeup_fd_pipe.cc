// Copyright 2022 The gRPC Authors
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//     http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

#include <grpc/support/port_platform.h>

#include <memory>
#include <utility>

#include "absl/strings/str_cat.h"
#include "absl/strings/string_view.h"

#include "src/core/lib/gprpp/crash.h"  // IWYU pragma: keep
#include "src/core/lib/iomgr/port.h"

#ifdef GRPC_POSIX_WAKEUP_FD
#include <errno.h>
#include <fcntl.h>
#include <unistd.h>

#if defined(GPR_PLAYSTATION)
#include <kernel.h>
#include <sys/socket.h>
#endif

#include "src/core/lib/event_engine/posix_engine/wakeup_fd_posix.h"
#endif

#include "src/core/lib/event_engine/posix_engine/wakeup_fd_pipe.h"
#include "src/core/lib/gprpp/strerror.h"

namespace grpc_event_engine {
namespace experimental {

#ifdef GRPC_POSIX_WAKEUP_FD

namespace {

#if defined(GPR_PLAYSTATION)
int playstation_create_pipe(int pipefd[2]) {
  //
  // https://trac.transmissionbt.com/browser/trunk/libtransmission/trevent.c
  //
  pipefd[0] = pipefd[1] = -1;

  SceNetId s = sceNetSocket("pipe", AF_INET, SOCK_STREAM, IPPROTO_TCP);
  if (s < 0) {
    return sce_net_errno;
  }

  SceNetSockaddrIn serv_addr;
  memset(&serv_addr, 0, sizeof(serv_addr));
  serv_addr.sin_len = sizeof(serv_addr);
  serv_addr.sin_family = SCE_NET_AF_INET;
  serv_addr.sin_port = sceNetHtons(0);
  serv_addr.sin_addr.s_addr = sceNetHtonl(INADDR_LOOPBACK);

  for (;;) {
    if (0 != sceNetBind(s, (SceNetSockaddr*)&serv_addr, sizeof(serv_addr)))
      break;
    if (0 != sceNetListen(s, 8)) break;

    SceNetSocklen_t server_addr_len = sizeof(serv_addr);
    if (0 !=
        sceNetGetsockname(s, (SceNetSockaddr*)&serv_addr, &server_addr_len))
      break;

    pipefd[1] = sceNetSocket("pipe_1", AF_INET, SOCK_STREAM, IPPROTO_TCP);
    if (pipefd[1] < 0) break;

    // if (GRPC_ERROR_NONE != grpc_set_socket_nonblocking(pipefd[1], 1)) break;

    if (0 != sceNetConnect(pipefd[1], (SceNetSockaddr*)&serv_addr,
                           sizeof(serv_addr)))
      break;

    SceNetSockaddrIn sin_accept;
    SceNetSocklen_t sin_len = sizeof(sin_accept);
    pipefd[0] = sceNetAccept(s, (SceNetSockaddr*)&sin_accept, &sin_len);
    if (pipefd[0] < 0) break;

    // if (GRPC_ERROR_NONE != grpc_set_socket_nonblocking(pipefd[0], 1)) break;

    sceNetSocketClose(s);
    return 0;
  }
  int error_code = sce_net_errno;
  // error case
  if (pipefd[0] != -1) sceNetSocketClose(pipefd[0]);
  if (pipefd[1] != -1) sceNetSocketClose(pipefd[1]);
  sceNetSocketClose(s);
  pipefd[0] = pipefd[1] = -1;
  return error_code;
}
#endif

absl::Status SetSocketNonBlocking(int fd) {
#if defined(GPR_PLAYSTATION)
  int non_blocking = 1;
  int ret = sceNetSetsockopt(fd, SCE_NET_SOL_SOCKET, SCE_NET_SO_NBIO,
                             &non_blocking, sizeof(non_blocking));
  if (ret < 0) {
    return absl::Status(absl::StatusCode::kInternal,
                        absl::StrCat("sceNetSetsockopt(SO_NBIO) ",
                                     grpc_core::StrError(sce_net_errno)));
  }
#else
  int oldflags = fcntl(fd, F_GETFL, 0);
  if (oldflags < 0) {
    return absl::Status(absl::StatusCode::kInternal,
                        absl::StrCat("fcntl: ", grpc_core::StrError(errno)));
  }

  oldflags |= O_NONBLOCK;

  if (fcntl(fd, F_SETFL, oldflags) != 0) {
    return absl::Status(absl::StatusCode::kInternal,
                        absl::StrCat("fcntl: ", grpc_core::StrError(errno)));
  }
#endif
  return absl::OkStatus();
}
}  // namespace

absl::Status PipeWakeupFd::Init() {
  int pipefd[2];
#if defined(GPR_PLAYSTATION)
  int r = playstation_create_pipe(pipefd);
#else
  int r = pipe(pipefd);
#endif
  if (0 != r) {
    return absl::Status(absl::StatusCode::kInternal,
                        absl::StrCat("pipe: ", grpc_core::StrError(errno)));
  }
  auto status = SetSocketNonBlocking(pipefd[0]);
  if (!status.ok()) return status;
  status = SetSocketNonBlocking(pipefd[1]);
  if (!status.ok()) return status;
  SetWakeupFds(pipefd[0], pipefd[1]);
  return absl::OkStatus();
}

absl::Status PipeWakeupFd::ConsumeWakeup() {
  char buf[128];
  ssize_t r;

  for (;;) {
    r = read(ReadFd(), buf, sizeof(buf));
    if (r > 0) continue;
    if (r == 0) return absl::OkStatus();
    switch (errno) {
      case EAGAIN:
        return absl::OkStatus();
      case EINTR:
        continue;
      default:
        return absl::Status(absl::StatusCode::kInternal,
                            absl::StrCat("read: ", grpc_core::StrError(errno)));
    }
  }
}

absl::Status PipeWakeupFd::Wakeup() {
  char c = 0;
  while (write(WriteFd(), &c, 1) != 1 && errno == EINTR) {
  }
  return absl::OkStatus();
}

PipeWakeupFd::~PipeWakeupFd() {
  if (ReadFd() != 0) {
    close(ReadFd());
  }
  if (WriteFd() != 0) {
    close(WriteFd());
  }
}

bool PipeWakeupFd::IsSupported() {
  PipeWakeupFd pipe_wakeup_fd;
  return pipe_wakeup_fd.Init().ok();
}

absl::StatusOr<std::unique_ptr<WakeupFd>> PipeWakeupFd::CreatePipeWakeupFd() {
  static bool kIsPipeWakeupFdSupported = PipeWakeupFd::IsSupported();
  if (kIsPipeWakeupFdSupported) {
    auto pipe_wakeup_fd = std::make_unique<PipeWakeupFd>();
    auto status = pipe_wakeup_fd->Init();
    if (status.ok()) {
      return std::unique_ptr<WakeupFd>(std::move(pipe_wakeup_fd));
    }
    return status;
  }
  return absl::NotFoundError("Pipe wakeup fd is not supported");
}

#else  //  GRPC_POSIX_WAKEUP_FD

absl::Status PipeWakeupFd::Init() { grpc_core::Crash("unimplemented"); }

absl::Status PipeWakeupFd::ConsumeWakeup() {
  grpc_core::Crash("unimplemented");
}

absl::Status PipeWakeupFd::Wakeup() { grpc_core::Crash("unimplemented"); }

bool PipeWakeupFd::IsSupported() { return false; }

absl::StatusOr<std::unique_ptr<WakeupFd>> PipeWakeupFd::CreatePipeWakeupFd() {
  return absl::NotFoundError("Pipe wakeup fd is not supported");
}

#endif  //  GRPC_POSIX_WAKEUP_FD

}  // namespace experimental
}  // namespace grpc_event_engine
