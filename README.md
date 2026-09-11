# Rule_for_self

面向 FiClash、OpenClash、Stash 与 Loon 的个人规则与覆写配置。FiClash、OpenClash 和 Stash 基于 Mihomo，共用“中国/私网直连 + 专用业务 / GFW / 自定义代理优先 + 其余流量代理”的策略：最终规则为 `MATCH,🐟 漏网之鱼`，默认项为 `🚀 节点选择`，`DIRECT` 仅作为手动回退。Loon 使用其原生规则格式，不能直接加载 Mihomo MRS。

## 使用入口

| 客户端 | 文件 | 作用 |
| --- | --- | --- |
| FiClash | `FIClash自定义代理组和规则组.js` | 后处理脚本；重建代理组、规则集和 DNS 分流。 |
| OpenClash | `openclash_custom_overwrite.sh` | 自定义覆写脚本；保留 OpenClash 的 `oc-*` DNS 规则集。 |
| Stash | `Full_only_self_use_Stash.stoverride` | 覆写配置；使用 MetaCubeX MRS 规则集。 |
| Loon | `Full_only_self_use_Loon_pure.conf` | 远程主配置；机场订阅仅在 Loon 本地添加，不写入仓库。 |

`Rule_for_self` 是 FiClash、OpenClash、Stash 与 Loon 配置的唯一维护源。客户端应配置本仓库 `main` 分支的远程文件，不保留 `D:\sync\服务器运维` 根目录中的本地副本，以免更新时发生版本漂移。

FiClash、OpenClash 与 Stash 会从本仓库 `main` 分支下载下列可读自定义规则；Loon 通过原生 `.list` 文件加载对应的自定义规则。应用脚本或覆写后重新加载配置（或更新订阅）即可生效。

## 可编辑自定义规则

| 文件 | `behavior` / `format` | 用途 |
| --- | --- | --- |
| `Proxy_Domain.yaml` | `domain` / `yaml` | 强制代理的域名；例如 `+.flower.yt`。 |
| `Gmail_Domain.yaml` | `domain` / `yaml` | Gmail 专用代理域名；优先于 GoogleCN。 |
| `Proxy_Classical.list` | `classical` / `text` | 强制代理的关键字、进程或端口等规则。 |
| `Direct_Domain.yaml` | `domain` / `yaml` | 强制直连的域名。 |
| `Direct_IP.yaml` | `ipcidr` / `yaml` | 强制直连的 IP CIDR。 |
| `Direct_Classical.list` | `classical` / `text` | 强制直连的关键字、进程或端口等规则。 |

YAML 域名规则中，裸域名表示精确匹配；`+.example.com` 表示该域名和全部子域名。IP 规则必须填写 CIDR。上述文件供 Mihomo 系客户端直接加载，无需编译为 `.mrs`；Loon 使用 `Loon_CustomProxy.list` 与 `Loon_CustomDirect.list`，修改自定义规则时应同步维护对应 Loon 语法。

## 规则优先级

FiClash、OpenClash 与 Stash 中，自定义直连 / 代理规则和专用业务规则优先，随后是 GFW 通用代理规则；再匹配 MetaCubeX 的 `private` 与 `cn` 域名/IP MRS 并直连；剩余境外或未知流量进入 `🐟 漏网之鱼`。GitHub 规则独立于微软服务规则，并排在微软规则之前；Telegram 和 Netflix 同时加载域名及官方 IP 段规则，以覆盖移动端直连 IP 的流量。已移除上游失效的 `ProxyMedia` / `🌍 国外媒体` 规则集与策略组，避免规则下载 404。

Loon 的服务规则来自 Blackmatrix7 的 Loon 原生 `.list`；其当前 `FINAL,DIRECT` 为独立的默认直连策略，不等同于 Mihomo 三端的 `🐟 漏网之鱼` 兜底。

`ProxyList.list` 和 `DirectList.list` 已迁移并移除；历史规则中的域名、IP、`DOMAIN-KEYWORD` 和 `PROCESS-NAME` 分别归入以上可读文件。
