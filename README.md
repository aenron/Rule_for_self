# Rule_for_self

用于 Mihomo / FlClash 的自定义规则。规则按类型拆分，便于阅读、维护和被 `rule-providers` 直接加载。

| 文件 | `behavior` / `format` | 用途 |
| --- | --- | --- |
| `Proxy_Domain.yaml` | `domain` / `yaml` | 强制代理的域名 |
| `Proxy_IP.yaml` | `ipcidr` / `yaml` | 强制代理的 IP CIDR |
| `Proxy_Classical.list` | `classical` / `text` | 强制代理的关键字、进程、端口等规则 |
| `Direct_Domain.yaml` | `domain` / `yaml` | 强制直连的域名 |
| `Direct_IP.yaml` | `ipcidr` / `yaml` | 强制直连的 IP CIDR |
| `Direct_Classical.list` | `classical` / `text` | 强制直连的关键字、进程、端口等规则 |

YAML 域名规则中，裸域名表示精确匹配；`+.example.com` 表示该域名及其子域。IP 规则必须填写 CIDR。规则文件可直接编辑与提交，不需要编译。

`ProxyList.list` 和 `DirectList.list` 已迁移并移除。旧规则中的域名、IP、`DOMAIN-KEYWORD` 和 `PROCESS-NAME` 均已保留在相应的新文件中。
