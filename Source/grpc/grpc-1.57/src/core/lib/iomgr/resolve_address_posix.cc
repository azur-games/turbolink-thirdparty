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
#ifdef GRPC_POSIX_SOCKET_RESOLVE_ADDRESS

#include <string.h>
#include <sys/types.h>

#include <grpc/support/alloc.h>
#include <grpc/support/log.h>
#include <grpc/support/string_util.h>
#include <grpc/support/time.h>

#include "src/core/lib/event_engine/default_event_engine.h"
#include "src/core/lib/gpr/string.h"
#include "src/core/lib/gpr/useful.h"
#include "src/core/lib/gprpp/crash.h"
#include "src/core/lib/gprpp/host_port.h"
#include "src/core/lib/gprpp/thd.h"
#include "src/core/lib/iomgr/block_annotate.h"
#include "src/core/lib/iomgr/exec_ctx.h"
#include "src/core/lib/iomgr/executor.h"
#include "src/core/lib/iomgr/iomgr_internal.h"
#include "src/core/lib/iomgr/resolve_address.h"
#include "src/core/lib/iomgr/resolve_address_posix.h"
#include "src/core/lib/iomgr/sockaddr.h"
#include "src/core/lib/iomgr/unix_sockets_posix.h"
#include "src/core/lib/transport/error_utils.h"

namespace grpc_core {
namespace {

class NativeDNSRequest {
 public:
  NativeDNSRequest(
      absl::string_view name, absl::string_view default_port,
      std::function<void(absl::StatusOr<std::vector<grpc_resolved_address>>)>
          on_done)
      : name_(name), default_port_(default_port), on_done_(std::move(on_done)) {
    GRPC_CLOSURE_INIT(&request_closure_, DoRequestThread, this, nullptr);
    Executor::Run(&request_closure_, absl::OkStatus(), ExecutorType::RESOLVER);
  }

 private:
  // Callback to be passed to grpc Executor to asynch-ify
  // LookupHostnameBlocking
  static void DoRequestThread(void* rp, grpc_error_handle /*error*/) {
    NativeDNSRequest* r = static_cast<NativeDNSRequest*>(rp);
    auto result =
        GetDNSResolver()->LookupHostnameBlocking(r->name_, r->default_port_);
    // running inline is safe since we've already been scheduled on the executor
    r->on_done_(std::move(result));
    delete r;
  }

  const std::string name_;
  const std::string default_port_;
  const std::function<void(absl::StatusOr<std::vector<grpc_resolved_address>>)>
      on_done_;
  grpc_closure request_closure_;
};

}  // namespace

DNSResolver::TaskHandle NativeDNSResolver::LookupHostname(
    std::function<void(absl::StatusOr<std::vector<grpc_resolved_address>>)>
        on_done,
    absl::string_view name, absl::string_view default_port,
    Duration /* timeout */, grpc_pollset_set* /* interested_parties */,
    absl::string_view /* name_server */) {
  // self-deleting class
  new NativeDNSRequest(name, default_port, std::move(on_done));
  return kNullHandle;
}

#if defined(GPR_PLAYSTATION)
grpc_error_handle playstation_do_resolver_ntoa(const char* hostname,
                                               SceNetInAddr* addr) {
  SceNetId rid = -1;
  int memid = -1;
  int ret;
  grpc_error_handle err = absl::OkStatus();

  ret = sceNetPoolCreate(__FUNCTION__, 4 * 1024, 0);
  if (ret < 0) {
    err = grpc_error_set_int(GRPC_ERROR_CREATE("sceNetPoolCreate() failed"),
                             StatusIntProperty::kErrorNo, sce_net_errno);
    goto failed;
  }
  memid = ret;
  ret = sceNetResolverCreate("resolver", memid, 0);
  if (ret < 0) {
    err = grpc_error_set_int(GRPC_ERROR_CREATE("sceNetResolverCreate() failed"),
                             StatusIntProperty::kErrorNo, sce_net_errno);
    goto failed;
  }
  rid = ret;
  ret = sceNetResolverStartNtoa(rid, hostname, addr, 0, 0, 0);
  if (ret < 0) {
    err = grpc_error_set_int(
        GRPC_ERROR_CREATE("sceNetResolverStartNtoa() failed"),
        StatusIntProperty::kErrorNo, sce_net_errno);
    goto failed;
  }
  ret = sceNetResolverDestroy(rid);
  if (ret < 0) {
    err =
        grpc_error_set_int(GRPC_ERROR_CREATE("sceNetResolverDestroy() failed"),
                           StatusIntProperty::kErrorNo, sce_net_errno);
    goto failed;
  }
  ret = sceNetPoolDestroy(memid);
  if (ret < 0) {
    err = grpc_error_set_int(GRPC_ERROR_CREATE("sceNetPoolDestroy() failed"),
                             StatusIntProperty::kErrorNo, sce_net_errno);
    goto failed;
  }
  return err;

failed:
  sceNetResolverDestroy(rid);
  sceNetPoolDestroy(memid);
  return err;
}
#endif

absl::StatusOr<std::vector<grpc_resolved_address>>
NativeDNSResolver::LookupHostnameBlocking(absl::string_view name,
                                          absl::string_view default_port) {
  ExecCtx exec_ctx;
  grpc_error_handle err;
  std::vector<grpc_resolved_address> addresses;
  std::string host;
  std::string port;
  // parse name, splitting it into host and port parts
  SplitHostPort(name, &host, &port);
  if (host.empty()) {
    err = grpc_error_set_str(GRPC_ERROR_CREATE("unparseable host:port"),
                             StatusStrProperty::kTargetAddress, name);
    auto error_result = grpc_error_to_absl_status(err);
    return error_result;
  }
  if (port.empty()) {
    if (default_port.empty()) {
      err = grpc_error_set_str(GRPC_ERROR_CREATE("no port in name"),
                               StatusStrProperty::kTargetAddress, name);
      auto error_result = grpc_error_to_absl_status(err);
      return error_result;
    }
    port = std::string(default_port);
  }
#if defined(GPR_PLAYSTATION)
  SceNetInAddr sin_addr;
  if (sceNetInetPton(SCE_NET_AF_INET, host.c_str(), &sin_addr) == 0) {
    GRPC_SCHEDULING_START_BLOCKING_REGION;
    err = playstation_do_resolver_ntoa(host.c_str(), &sin_addr);
    GRPC_SCHEDULING_END_BLOCKING_REGION;
    if (!err.ok()) {
      auto error_result = grpc_error_to_absl_status(err);
      return error_result;
    }
  }

  // parse port
  char* endptr = nullptr;
  int port_num = strtol(port.c_str(), &endptr, 10);
  if (endptr == port.c_str()) {
    if (port == "http") {
      port_num = 80;
    } else if (port == "https") {
      port_num = 443;
    } else {
      err = grpc_error_set_str(GRPC_ERROR_CREATE("invalid port in name"),
                               StatusStrProperty::kTargetAddress, name);
      auto error_result = grpc_error_to_absl_status(err);
      return error_result;
    }
  }

  // struct sockaddr hints;
  grpc_sockaddr_in result;
  memset(&result, 0, sizeof(result));
  result.sin_len = sizeof(result);
  result.sin_family = SCE_NET_AF_INET;
  result.sin_port = sceNetHtons(port_num);
  result.sin_addr.s_addr = sin_addr.s_addr;

  grpc_resolved_address addr;
  memcpy(&addr.addr, &result, sizeof(result));
  addr.len = sizeof(result);
  addresses.push_back(addr);

  return addresses;
#else
  struct addrinfo hints;
  struct addrinfo *result = nullptr, *resp;
  int s;
  size_t i;
  // Call getaddrinfo
  memset(&hints, 0, sizeof(hints));
  hints.ai_family = AF_UNSPEC;      // ipv4 or ipv6
  hints.ai_socktype = SOCK_STREAM;  // stream socket
  hints.ai_flags = AI_PASSIVE;      // for wildcard IP address
  GRPC_SCHEDULING_START_BLOCKING_REGION;
  s = getaddrinfo(host.c_str(), port.c_str(), &hints, &result);
  GRPC_SCHEDULING_END_BLOCKING_REGION;
  if (s != 0) {
    // Retry if well-known service name is recognized
    const char* svc[][2] = {{"http", "80"}, {"https", "443"}};
    for (i = 0; i < GPR_ARRAY_SIZE(svc); i++) {
      if (port == svc[i][0]) {
        GRPC_SCHEDULING_START_BLOCKING_REGION;
        s = getaddrinfo(host.c_str(), svc[i][1], &hints, &result);
        GRPC_SCHEDULING_END_BLOCKING_REGION;
        break;
      }
    }
  }
  if (s != 0) {
    err = grpc_error_set_str(
        grpc_error_set_str(
            grpc_error_set_str(
                grpc_error_set_int(GRPC_ERROR_CREATE(gai_strerror(s)),
                                   StatusIntProperty::kErrorNo, s),
                StatusStrProperty::kOsError, gai_strerror(s)),
            StatusStrProperty::kSyscall, "getaddrinfo"),
        StatusStrProperty::kTargetAddress, name);
    goto done;
  }
  // Success path: fill in addrs
  for (resp = result; resp != nullptr; resp = resp->ai_next) {
    grpc_resolved_address addr;
    memcpy(&addr.addr, resp->ai_addr, resp->ai_addrlen);
    addr.len = resp->ai_addrlen;
    addresses.push_back(addr);
  }
  err = absl::OkStatus();
done:
  if (result) {
    freeaddrinfo(result);
  }
  if (err.ok()) {
    return addresses;
  }
  auto error_result = grpc_error_to_absl_status(err);
  return error_result;
#endif
}

DNSResolver::TaskHandle NativeDNSResolver::LookupSRV(
    std::function<void(absl::StatusOr<std::vector<grpc_resolved_address>>)>
        on_resolved,
    absl::string_view /* name */, Duration /* timeout */,
    grpc_pollset_set* /* interested_parties */,
    absl::string_view /* name_server */) {
  grpc_event_engine::experimental::GetDefaultEventEngine()->Run([on_resolved] {
    ApplicationCallbackExecCtx app_exec_ctx;
    ExecCtx exec_ctx;
    on_resolved(absl::UnimplementedError(
        "The Native resolver does not support looking up SRV records"));
  });
  return {-1, -1};
};

DNSResolver::TaskHandle NativeDNSResolver::LookupTXT(
    std::function<void(absl::StatusOr<std::string>)> on_resolved,
    absl::string_view /* name */, Duration /* timeout */,
    grpc_pollset_set* /* interested_parties */,
    absl::string_view /* name_server */) {
  // Not supported
  grpc_event_engine::experimental::GetDefaultEventEngine()->Run([on_resolved] {
    ApplicationCallbackExecCtx app_exec_ctx;
    ExecCtx exec_ctx;
    on_resolved(absl::UnimplementedError(
        "The Native resolver does not support looking up TXT records"));
  });
  return {-1, -1};
};

bool NativeDNSResolver::Cancel(TaskHandle /*handle*/) { return false; }

}  // namespace grpc_core

#endif
