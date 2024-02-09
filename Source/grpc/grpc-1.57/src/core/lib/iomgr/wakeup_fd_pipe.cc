//
//
// Copyright 2015 gRPC authors.
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
//
//

#include <grpc/support/port_platform.h>

#include "src/core/lib/iomgr/port.h"

#ifdef GRPC_POSIX_WAKEUP_FD

#include <errno.h>
#include <string.h>
#include <unistd.h>

#include <grpc/support/log.h>

#include "src/core/lib/gprpp/crash.h"
#include "src/core/lib/gprpp/strerror.h"
#include "src/core/lib/iomgr/socket_utils_posix.h"
#include "src/core/lib/iomgr/wakeup_fd_pipe.h"
#include "src/core/lib/iomgr/wakeup_fd_posix.h"

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
}  // namespace

static grpc_error_handle pipe_init(grpc_wakeup_fd* fd_info) {
  int pipefd[2];
#if defined(GPR_PLAYSTATION)
  int r = playstation_create_pipe(pipefd);
#else
  int r = pipe(pipefd);
#endif
  if (0 != r) {
    gpr_log(GPR_ERROR, "pipe creation failed (%d): %s", errno,
            grpc_core::StrError(errno).c_str());
    return GRPC_OS_ERROR(errno, "pipe");
  }
  grpc_error_handle err;
  err = grpc_set_socket_nonblocking(pipefd[0], 1);
  if (!err.ok()) return err;
  err = grpc_set_socket_nonblocking(pipefd[1], 1);
  if (!err.ok()) return err;
  fd_info->read_fd = pipefd[0];
  fd_info->write_fd = pipefd[1];
  return absl::OkStatus();
}

static grpc_error_handle pipe_consume(grpc_wakeup_fd* fd_info) {
  char buf[128];
  ssize_t r;

  for (;;) {
    r = read(fd_info->read_fd, buf, sizeof(buf));
    if (r > 0) continue;
    if (r == 0) return absl::OkStatus();
    switch (errno) {
      case EAGAIN:
        return absl::OkStatus();
      case EINTR:
        continue;
      default:
        return GRPC_OS_ERROR(errno, "read");
    }
  }
}

static grpc_error_handle pipe_wakeup(grpc_wakeup_fd* fd_info) {
  char c = 0;
  while (write(fd_info->write_fd, &c, 1) != 1 && errno == EINTR) {
  }
  return absl::OkStatus();
}

static void pipe_destroy(grpc_wakeup_fd* fd_info) {
  if (fd_info->read_fd != 0) close(fd_info->read_fd);
  if (fd_info->write_fd != 0) close(fd_info->write_fd);
}

static int pipe_check_availability(void) {
  grpc_wakeup_fd fd;
  fd.read_fd = fd.write_fd = -1;

  if (pipe_init(&fd) == absl::OkStatus()) {
    pipe_destroy(&fd);
    return 1;
  } else {
    return 0;
  }
}

const grpc_wakeup_fd_vtable grpc_pipe_wakeup_fd_vtable = {
    pipe_init, pipe_consume, pipe_wakeup, pipe_destroy,
    pipe_check_availability};

#endif  // GPR_POSIX_WAKUP_FD
