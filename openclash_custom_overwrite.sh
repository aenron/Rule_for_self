#!/bin/sh
#===============================================================================
# OpenClash Custom Overwrite Script
# Path: /etc/openclash/custom/openclash_custom_overwrite.sh
#
# Purpose:
#   1. Keep subscription proxies / proxy-providers untouched.
#   2. Completely replace subscription proxy-groups.
#   3. Use low-overhead MetaCubeX MRS rule-providers, while preserving
#      OpenClash internal oc-* providers.
#   4. Use a default-direct rule model: only dedicated, GFW and custom proxy
#      rules use proxies.
#   5. Rebuild groups/rules according to:
#      https://raw.githubusercontent.com/aenron/Rule_for_self/refs/heads/main/Full_only_self_use.ini
#
# Target:
#   OpenClash + Mihomo / Meta core
#===============================================================================

. /usr/share/openclash/ruby.sh 2>/dev/null
. /usr/share/openclash/log.sh 2>/dev/null
. /lib/functions.sh 2>/dev/null

CONFIG_FILE="$1"
LOG_FILE="/tmp/openclash.log"
RUBY_LOG="/tmp/openclash_custom_overwrite.log"

log_msg() {
    if command -v LOG_OUT >/dev/null 2>&1; then
        LOG_OUT "$1"
    elif command -v LOG_TIP >/dev/null 2>&1; then
        LOG_TIP "$1"
    else
        echo "$(date '+%Y-%m-%d %H:%M:%S') $1" >> "$LOG_FILE"
    fi
}

log_msg "Custom overwrite: rebuilding proxy-groups, rule-providers and rules..."

if [ -z "$CONFIG_FILE" ]; then
    log_msg "Custom overwrite ERROR: CONFIG_FILE (\$1) is empty."
    exit 1
fi

if [ ! -f "$CONFIG_FILE" ]; then
    log_msg "Custom overwrite ERROR: config file not found: $CONFIG_FILE"
    exit 1
fi

# OpenClash currently provides Ruby/Psych for YAML processing.
if ! command -v ruby >/dev/null 2>&1; then
    log_msg "Custom overwrite ERROR: ruby command not found."
    exit 1
fi

ruby -ryaml -E UTF-8 - "$CONFIG_FILE" >"$RUBY_LOG" 2>&1 <<'RUBY'
config_file = ARGV[0]

begin
  config = YAML.load_file(config_file, aliases: true)
rescue => e
  warn "[custom-overwrite] Failed to load YAML: #{e.class}: #{e.message}"
  exit 10
end

unless config.is_a?(Hash)
  warn "[custom-overwrite] Top-level YAML object is not a Hash."
  exit 11
end

# -----------------------------------------------------------------------------
# Basic validation
# -----------------------------------------------------------------------------
static_proxies = config['proxies'].is_a?(Array) ? config['proxies'] : []
proxy_providers = config['proxy-providers'].is_a?(Hash) ? config['proxy-providers'] : {}

static_proxy_names = static_proxies.filter_map do |p|
  p.is_a?(Hash) ? p['name'] : nil
end.compact.map(&:to_s)

if static_proxy_names.empty? && proxy_providers.empty?
  warn "[custom-overwrite] No proxies or proxy-providers found; refusing to overwrite groups."
  exit 12
end

puts "[custom-overwrite] config=#{config_file}"
puts "[custom-overwrite] static proxies=#{static_proxy_names.length}"
puts "[custom-overwrite] proxy providers=#{proxy_providers.length}"

# -----------------------------------------------------------------------------
# Helpers
# -----------------------------------------------------------------------------
TEST_URL = 'http://www.gstatic.com/generate_204'
INTERVAL = 300

def select_group(name, proxies)
  {
    'name' => name,
    'type' => 'select',
    'proxies' => proxies
  }
end

def include_select_group(name, filter: nil, exclude_filter: nil)
  g = {
    'name' => name,
    'type' => 'select',
    'include-all' => true,
    'exclude-type' => 'direct',
    'empty-fallback' => 'DIRECT'
  }
  g['filter'] = filter if filter
  g['exclude-filter'] = exclude_filter if exclude_filter
  g
end

def include_url_test_group(name, filter: nil, exclude_filter: nil, tolerance: 50)
  g = {
    'name' => name,
    'type' => 'url-test',
    'include-all' => true,
    'exclude-type' => 'direct',
    'url' => TEST_URL,
    'interval' => INTERVAL,
    'lazy' => true,
    'tolerance' => tolerance,
    'empty-fallback' => 'DIRECT'
  }
  g['filter'] = filter if filter
  g['exclude-filter'] = exclude_filter if exclude_filter
  g
end

# All remote rule sets are fetched through the primary policy group. GitHub Raw
# often cannot be reached directly from the router, and a failed provider makes
# its RULE-SET silently ineffective under MATCH,DIRECT.
RULE_PROVIDER_PROXY = '🚀 节点选择'

def classical_provider(url, filename)
  {
    'type' => 'http',
    'behavior' => 'classical',
    'format' => 'text',
    'url' => url,
    'path' => "./rule_provider/#{filename}",
    'proxy' => RULE_PROVIDER_PROXY,
    'interval' => 86400
  }
end

def yaml_provider(url, behavior, filename)
  {
    'type' => 'http',
    'behavior' => behavior,
    'format' => 'yaml',
    'url' => url,
    'path' => "./rule_provider/#{filename}",
    'proxy' => RULE_PROVIDER_PROXY,
    'interval' => 86400
  }
end

def meta_domain(name)
  {
    'type' => 'http',
    'behavior' => 'domain',
    'format' => 'mrs',
    'url' => "https://raw.githubusercontent.com/MetaCubeX/meta-rules-dat/meta/geo/geosite/#{name}.mrs",
    'path' => "./rule_provider/#{name}-domain.mrs",
    'proxy' => RULE_PROVIDER_PROXY,
    'interval' => 86400
  }
end

def meta_ip(name)
  {
    'type' => 'http',
    'behavior' => 'ipcidr',
    'format' => 'mrs',
    'url' => "https://raw.githubusercontent.com/MetaCubeX/meta-rules-dat/meta/geo/geoip/#{name}.mrs",
    'path' => "./rule_provider/#{name}-ip.mrs",
    'proxy' => RULE_PROVIDER_PROXY,
    'interval' => 86400
  }
end

# -----------------------------------------------------------------------------
# Completely replace proxy-groups
#
# Note:
#   The original subconverter regex uses negative lookahead:
#     (?!.*实验.*)
#   Mihomo uses Go/RE2 style regex for filter, which does not support lookahead.
#   Therefore it is represented as:
#     filter: <country regex>
#     exclude-filter: 实验
# -----------------------------------------------------------------------------
config['proxy-groups'] = [
  select_group('🚀 节点选择', [
    '实验',
    '♻️ 自动选择',
    '🚀 手动切换',
    'DIRECT',
    '香港',
    '台湾',
    '新加坡',
    '日本',
    '美国',
    '韩国',
    '东南亚',
    '西欧',
    '小众'
  ]),

  # All subscription nodes; include-all also supports proxy-providers.
  include_select_group('🚀 手动切换'),

  include_url_test_group('♻️ 自动选择', tolerance: 50),

  select_group('🤖 AI 服务', [
    '美国',
    '新加坡',
    '台湾',
    '香港',
    '日本',
    '韩国',
    '东南亚',
    '西欧',
    '小众',
    '实验',
    '♻️ 自动选择',
    '🚀 手动切换',
    'DIRECT'
  ]),

  select_group('Telegram', [
    '实验',
    '♻️ 自动选择',
    '🚀 手动切换',
    'DIRECT',
    '香港',
    '台湾',
    '新加坡',
    '日本',
    '美国',
    '韩国',
    '东南亚',
    '西欧',
    '小众'
  ]),

  select_group('🎥 奈飞视频', [
    '小众',
    '🚀 节点选择',
    '🚀 手动切换',
    '实验',
    '♻️ 自动选择',
    'DIRECT',
    '新加坡',
    '香港',
    '台湾',
    '日本',
    '美国',
    '韩国',
    '东南亚',
    '西欧'
  ]),

  select_group('Ⓜ️ 微软服务', [
    'DIRECT',
    '实验',
    '🚀 节点选择',
    '🚀 手动切换',
    '美国',
    '香港',
    '台湾',
    '新加坡',
    '日本',
    '韩国',
    '东南亚',
    '西欧',
    '小众'
  ]),

  select_group('🍎 苹果服务', [
    'DIRECT',
    '实验',
    '🚀 节点选择',
    '🚀 手动切换',
    '美国',
    '香港',
    '台湾',
    '新加坡',
    '日本',
    '韩国',
    '东南亚',
    '西欧',
    '小众'
  ]),

  select_group('🎮 游戏平台', [
    '实验',
    'DIRECT',
    '🚀 节点选择',
    '🚀 手动切换',
    '美国',
    '香港',
    '台湾',
    '新加坡',
    '日本',
    '韩国',
    '东南亚',
    '西欧',
    '小众'
  ]),

  select_group('🎯 全球直连', [
    'DIRECT',
    '🚀 节点选择',
    '🚀 手动切换',
    '♻️ 自动选择'
  ]),

  # Region groups: preserve the regex logic from Full_only_self_use.ini.
  include_url_test_group(
    '实验',
    filter: '(实验)',
    tolerance: 50
  ),

  include_url_test_group(
    '香港',
    filter: '(港|HK|Hong Kong)',
    exclude_filter: '实验',
    tolerance: 50
  ),

  include_url_test_group(
    '台湾',
    filter: '(台|台湾)',
    exclude_filter: '实验',
    tolerance: 50
  ),

  include_url_test_group(
    '日本',
    filter: '(日本|川日|东京|大阪|泉日|埼玉|沪日|深日|日|JP|Japan)',
    exclude_filter: '实验',
    tolerance: 50
  ),

  include_url_test_group(
    '美国',
    filter: '(美|波特兰|达拉斯|俄勒冈|凤凰城|旧金山|费利蒙|拉斯维加斯|洛杉矶|圣何塞|西雅图|芝加哥|US)',
    exclude_filter: '实验',
    tolerance: 150
  ),

  include_url_test_group(
    '新加坡',
    filter: '(新加坡|坡|狮城|Singap)',
    exclude_filter: '实验',
    tolerance: 50
  ),

  include_url_test_group(
    '韩国',
    filter: '(KR|Korea|KOR|首尔|韩|韓)',
    exclude_filter: '实验',
    tolerance: 50
  ),

  # In the original INI these three are "select" groups.
  include_select_group(
    '东南亚',
    filter: '(马来西亚|马来|越南|菲律宾|泰国|印度)',
    exclude_filter: '实验'
  ),

  include_select_group(
    '西欧',
    filter: '(德国|匈牙利|荷兰|英国|意大利|新西兰)',
    exclude_filter: '实验'
  ),

  include_select_group(
    '小众',
    filter: '(澳大利亚|巴西|智利|阿根廷|巴基斯坦|南非|俄罗斯|土耳其|乌克兰|以色列|阿联酋)',
    exclude_filter: '实验'
  )
]

# -----------------------------------------------------------------------------
# Rebuild rule-providers, but PRESERVE OpenClash internal providers.
#
# OpenClash may inject providers such as oc-cn-domain and reference them from
# dns.fake-ip-filter (e.g. rule-set:oc-cn-domain). Removing these providers
# causes Mihomo to fail with: not found rule-set: oc-cn-domain
# -----------------------------------------------------------------------------
original_rule_providers = config['rule-providers'].is_a?(Hash) ? config['rule-providers'] : {}
oc_rule_providers = original_rule_providers.select do |name, _provider|
  name.to_s.start_with?('oc-')
end

custom_rule_providers = {
  # MetaCubeX precompiled MRS sets: lower download and parsing cost than text.
  'AI' => meta_domain('category-ai-!cn'),
  'GitHub' => meta_domain('github'),
  'OneDrive' => meta_domain('onedrive'),
  'Microsoft' => meta_domain('microsoft'),
  'ProxyGFWlist' => meta_domain('gfw'),
  'Telegram' => meta_domain('telegram'),
  'TelegramIP' => meta_ip('telegram'),
  'Apple' => meta_domain('apple'),
  'Netflix' => meta_domain('netflix'),
  'NetflixIP' => meta_ip('netflix'),
  'GoogleCN' => meta_domain('google@cn'),
  'SteamCN' => meta_domain('steam@cn'),
  'Epic' => meta_domain('epicgames'),
  'Sony' => meta_domain('sony'),
  'Steam' => meta_domain('steam'),
  'Nintendo' => meta_domain('nintendo'),

  # aenron/Rule_for_self stays readable and editable; no MRS compilation.
  'CustomProxyDomain' => yaml_provider(
    'https://raw.githubusercontent.com/aenron/Rule_for_self/main/Proxy_Domain.yaml',
    'domain', 'custom-proxy-domain.yaml'
  ),
  'CustomDirectDomain' => yaml_provider(
    'https://raw.githubusercontent.com/aenron/Rule_for_self/main/Direct_Domain.yaml',
    'domain', 'custom-direct-domain.yaml'
  ),
  'CustomDirectIp' => yaml_provider(
    'https://raw.githubusercontent.com/aenron/Rule_for_self/main/Direct_IP.yaml',
    'ipcidr', 'custom-direct-ip.yaml'
  ),
  'CustomProxyClassical' => classical_provider(
    'https://raw.githubusercontent.com/aenron/Rule_for_self/main/Proxy_Classical.list',
    'custom-proxy-classical.list'
  ),
  'CustomDirectClassical' => classical_provider(
    'https://raw.githubusercontent.com/aenron/Rule_for_self/main/Direct_Classical.list',
    'custom-direct-classical.list'
  )
}

# Keep every OpenClash-created oc-* provider exactly as generated, and then
# overlay our own providers. If names ever collide, our custom provider wins.
config['rule-providers'] = oc_rule_providers.merge(custom_rule_providers)

puts "[custom-overwrite] preserved OpenClash oc-* providers: #{oc_rule_providers.keys.join(', ')}" unless oc_rule_providers.empty?

# -----------------------------------------------------------------------------
# Completely replace rules.
#
# Default-direct design: only custom proxy rules, dedicated services and the
# GFW set use a proxy. Dedicated services are placed before the generic GFW
# set so their own policy group is effective.
# -----------------------------------------------------------------------------
config['rules'] = [
  'DOMAIN-SUFFIX,eastcom-sw.com,DIRECT',

  # Custom entries have the highest priority. Proxy rules intentionally precede
  # direct rules, so dl.tailscale.com can proxy while +.tailscale.com is direct.
  'RULE-SET,CustomProxyDomain,🚀 节点选择',
  'RULE-SET,CustomProxyClassical,🚀 节点选择',
  'RULE-SET,CustomDirectDomain,🎯 全球直连',
  'RULE-SET,CustomDirectIp,🎯 全球直连,no-resolve',
  'RULE-SET,CustomDirectClassical,🎯 全球直连',

  'RULE-SET,AI,🤖 AI 服务',

  # GitHub is also included in the broad Microsoft set; handle it first.
  'RULE-SET,GitHub,🚀 节点选择',
  'RULE-SET,OneDrive,Ⓜ️ 微软服务',
  'RULE-SET,Microsoft,Ⓜ️ 微软服务',

  'RULE-SET,GoogleCN,🎯 全球直连',
  'RULE-SET,SteamCN,🎯 全球直连',

  'RULE-SET,Telegram,Telegram',
  'RULE-SET,TelegramIP,Telegram',
  'RULE-SET,Apple,🍎 苹果服务',
  'RULE-SET,Epic,🎮 游戏平台',
  'RULE-SET,Sony,🎮 游戏平台',
  'RULE-SET,Steam,🎮 游戏平台',
  'RULE-SET,Nintendo,🎮 游戏平台',
  'RULE-SET,Netflix,🎥 奈飞视频',
  'RULE-SET,NetflixIP,🎥 奈飞视频',
  'RULE-SET,ProxyGFWlist,🚀 节点选择',

  'MATCH,DIRECT'
]

# -----------------------------------------------------------------------------
# DNS: domestic queries use AliDNS/Tencent DoH; proxy-oriented rule sets use
# Cloudflare/Google DoH through the primary policy group. Preserve unrelated
# OpenClash-generated DNS keys, including every oc-* provider reference.
# -----------------------------------------------------------------------------
dns = config['dns'].is_a?(Hash) ? config['dns'] : {}
domestic_dns = [
  'https://dns.alidns.com/dns-query',
  'https://doh.pub/dns-query'
]
overseas_dns = [
  'https://cloudflare-dns.com/dns-query#🚀 节点选择',
  'https://dns.google/dns-query#🚀 节点选择'
]

dns['enable'] = true
dns['default-nameserver'] = ['223.5.5.5', '119.29.29.29']
# Use independent Array objects. Psych otherwise writes YAML anchors when the
# same Array is reused by nameserver-policy, which older OpenClash Ruby builds
# may reject during validation.
dns['nameserver'] = domestic_dns.dup
dns['fallback'] = overseas_dns.dup
dns['proxy-server-nameserver'] = domestic_dns.dup
dns['fallback-filter'] = {
  'geoip' => true,
  'geoip-code' => 'CN'
}

existing_dns_policy = dns['nameserver-policy'].is_a?(Hash) ? dns['nameserver-policy'] : {}
dns['nameserver-policy'] = existing_dns_policy.merge(
  'rule-set:CustomProxyDomain' => overseas_dns.dup,
  'rule-set:AI' => overseas_dns.dup,
  'rule-set:GitHub' => overseas_dns.dup,
  'rule-set:OneDrive' => overseas_dns.dup,
  'rule-set:Microsoft' => overseas_dns.dup,
  'rule-set:ProxyGFWlist' => overseas_dns.dup,
  'rule-set:Telegram' => overseas_dns.dup,
  'rule-set:Netflix' => overseas_dns.dup,
  'rule-set:Epic' => overseas_dns.dup,
  'rule-set:Sony' => overseas_dns.dup,
  'rule-set:Steam' => overseas_dns.dup,
  'rule-set:Nintendo' => overseas_dns.dup,
  'rule-set:GoogleCN' => domestic_dns.dup,
  'rule-set:SteamCN' => domestic_dns.dup
)
config['dns'] = dns

# -----------------------------------------------------------------------------
# Validate internal references before writing
# -----------------------------------------------------------------------------
group_names = config['proxy-groups'].map { |g| g['name'] }.compact
builtins = ['DIRECT', 'REJECT', 'REJECT-DROP', 'PASS', 'COMPATIBLE']

missing_group_refs = []
config['proxy-groups'].each do |g|
  next unless g['proxies'].is_a?(Array)
  g['proxies'].each do |ref|
    next if builtins.include?(ref)
    next if group_names.include?(ref)
    # A literal node name may appear in a group. In this script all static
    # references are policy groups, so flag unknown references.
    missing_group_refs << "#{g['name']} -> #{ref}"
  end
end

unless missing_group_refs.empty?
  warn "[custom-overwrite] Invalid group references: #{missing_group_refs.join(', ')}"
  exit 13
end

provider_names = config['rule-providers'].keys
missing_providers = config['rules'].filter_map do |rule|
  next unless rule.start_with?('RULE-SET,')
  provider = rule.split(',', 3)[1]
  provider unless provider_names.include?(provider)
end

unless missing_providers.empty?
  warn "[custom-overwrite] Missing rule-providers: #{missing_providers.uniq.join(', ')}"
  exit 14
end

# -----------------------------------------------------------------------------
# Atomic write: write temp file first, then rename over original.
# -----------------------------------------------------------------------------
tmp_file = "#{config_file}.custom_overwrite.tmp"

begin
  File.open(tmp_file, 'w') do |f|
    f.write(YAML.dump(config))
  end

  # Parse once more before replacing the actual startup config.
  # Ruby/Psych 4 disables aliases by default.  Enable them for compatibility
  # with subscription YAML that already uses anchors, even though this script
  # avoids introducing new aliases in its own DNS configuration.
  YAML.load_file(tmp_file, aliases: true)

  File.rename(tmp_file, config_file)
rescue => e
  File.delete(tmp_file) if File.exist?(tmp_file)
  warn "[custom-overwrite] Failed to write YAML: #{e.class}: #{e.message}"
  exit 15
end

puts "[custom-overwrite] proxy-groups rebuilt: #{config['proxy-groups'].length}"
puts "[custom-overwrite] rule-providers rebuilt: #{config['rule-providers'].length}"
puts "[custom-overwrite] rules rebuilt: #{config['rules'].length}"
puts "[custom-overwrite] SUCCESS"
RUBY

rc=$?

if [ "$rc" -ne 0 ]; then
    log_msg "Custom overwrite ERROR: Ruby exited with code $rc. Original/startup config was not intentionally replaced on write failure."
    [ -f "$RUBY_LOG" ] && tail -20 "$RUBY_LOG" >> "$LOG_FILE"
    exit "$rc"
fi

log_msg "Custom overwrite SUCCESS. Detail log: $RUBY_LOG"
exit 0
