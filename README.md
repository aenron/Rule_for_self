# Rule_for_self

面向 Mihomo 系客户端的个人规则与覆写脚本：FiClash、OpenClash 和 Stash 使用同一套“默认直连 + 专用业务 / GFW / 自定义代理规则”的策略。只有命中代理规则的流量才走代理，最终规则为 `MATCH,DIRECT`。

## 使用入口

| 客户端 | 文件 | 作用 |
| --- | --- | --- |
| FiClash | `FIClash自定义代理组和规则组.js` | 后处理脚本；重建代理组、规则集和 DNS 分流。 |
| OpenClash | `openclash_custom_overwrite.sh` | 自定义覆写脚本；保留 OpenClash 的 `oc-*` DNS 规则集。 |
| Stash | `Full_only_self_use_Stash.stoverride` | 覆写配置；使用 MetaCubeX MRS 规则集。 |

脚本会从本仓库的 `main` 分支下载下列可读自定义规则，并使用 `🚀 节点选择` 代理下载所需的 FiClash / OpenClash 规则集。应用脚本或覆写后重新加载配置（或更新订阅）即可生效。

## 可编辑自定义规则

| 文件 | `behavior` / `format` | 用途 |
| --- | --- | --- |
| `Proxy_Domain.yaml` | `domain` / `yaml` | 强制代理的域名；例如 `+.flower.yt`。 |
| `Proxy_Classical.list` | `classical` / `text` | 强制代理的关键字、进程或端口等规则。 |
| `Direct_Domain.yaml` | `domain` / `yaml` | 强制直连的域名。 |
| `Direct_IP.yaml` | `ipcidr` / `yaml` | 强制直连的 IP CIDR。 |
| `Direct_Classical.list` | `classical` / `text` | 强制直连的关键字、进程或端口等规则。 |

YAML 域名规则中，裸域名表示精确匹配；`+.example.com` 表示该域名和全部子域名。IP 规则必须填写 CIDR。上述文件可直接编辑和提交，无需编译为 `.mrs`。

`Proxy_IP.yaml` 仅保留为可选模板，当前三个客户端都未加载它；需要新增强制代理 IP 规则时，应先同步调整对应覆写脚本。

## 规则优先级

自定义直连 / 代理规则和专用业务规则优先，随后是 GFW 通用代理规则，最后默认直连。GitHub 规则独立于微软服务规则，并排在微软规则之前；Telegram 和 Netflix 同时加载域名及官方 IP 段规则，以覆盖移动端直连 IP 的流量。已移除上游失效的 `ProxyMedia` / `🌍 国外媒体` 规则集与策略组，避免规则下载 404。

`ProxyList.list` 和 `DirectList.list` 已迁移并移除；历史规则中的域名、IP、`DOMAIN-KEYWORD` 和 `PROCESS-NAME` 分别归入以上可读文件。
