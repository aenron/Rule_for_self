// ============================================================
// FlClash / Mihomo 自定义覆写脚本
//
// 目标：
// 1. 保留机场订阅提供的 proxies
// 2. 完全替换机场 proxy-groups
// 3. 完全替换机场 rules
// 4. 使用自己的 ACL4SSR / Rule_for_self 规则集
//
// 对应：
// Full_only_self_use.ini
// ============================================================

function main(config) {
  // ----------------------------------------------------------
  // 1. 获取机场节点
  // ----------------------------------------------------------

  const proxies = Array.isArray(config.proxies) ? config.proxies : [];
  const proxyNames = proxies.map(p => p.name).filter(Boolean);

  if (proxyNames.length === 0) {
    throw new Error("订阅中没有找到任何代理节点");
  }

  // ----------------------------------------------------------
  // 2. 节点过滤工具
  // ----------------------------------------------------------

  function matchNodes(regex) {
    const result = proxyNames.filter(name => regex.test(name));

    // 防止策略组为空导致 Mihomo 配置错误。
    // 未匹配到指定地区时回退到全部订阅节点，不在地区组内意外直连；
    // DIRECT 仅由上层业务/主策略组作为最后兜底选项提供。
    return result.length > 0 ? result : proxyNames;
  }

  const experimentalNodes = matchNodes(
    /实验/i
  );

  const hkNodes = matchNodes(
    /^(?!.*实验).*(港|HK|Hong\s*Kong)/i
  );

  const twNodes = matchNodes(
    /^(?!.*实验).*(台|台湾|TW|Taiwan)/i
  );

  const jpNodes = matchNodes(
    /^(?!.*实验).*(日本|川日|东京|東京|大阪|泉日|埼玉|沪日|深日|JP|Japan)/i
  );

  const usNodes = matchNodes(
    /^(?!.*实验).*(美国|美國|美|波特兰|達拉斯|达拉斯|俄勒冈|凤凰城|旧金山|費利蒙|费利蒙|拉斯维加斯|洛杉矶|洛杉磯|圣何塞|聖何塞|西雅图|芝加哥|US|USA|United States)/i
  );

  const sgNodes = matchNodes(
    /^(?!.*实验).*(新加坡|坡|狮城|獅城|SG|Singapore|Singap)/i
  );

  const krNodes = matchNodes(
    /^(?!.*实验).*(KR|Korea|KOR|首尔|首爾|韩|韓)/i
  );

  const seaNodes = matchNodes(
    /^(?!.*实验).*(马来西亚|馬來西亞|马来|馬來|越南|菲律宾|菲律賓|泰国|泰國|印度|Malaysia|Vietnam|Philippines|Thailand|India)/i
  );

  const westEuropeNodes = matchNodes(
    /^(?!.*实验).*(德国|德國|匈牙利|荷兰|荷蘭|英国|英國|意大利|義大利|新西兰|新西蘭|Germany|Hungary|Netherlands|UK|United Kingdom|Italy|New Zealand)/i
  );

  const nicheNodes = matchNodes(
    /^(?!.*实验).*(澳大利亚|澳大利亞|澳洲|巴西|智利|阿根廷|巴基斯坦|南非|俄罗斯|俄羅斯|土耳其|乌克兰|烏克蘭|以色列|阿联酋|阿聯酋|Australia|Brazil|Chile|Argentina|Pakistan|South Africa|Russia|Turkey|Ukraine|Israel|UAE)/i
  );


  // ----------------------------------------------------------
  // 3. 公共参数
  // ----------------------------------------------------------

  const TEST_URL = "http://www.gstatic.com/generate_204";

  const urlTestBase = {
    type: "url-test",
    url: TEST_URL,
    interval: 300,
    lazy: true
  };


  // ----------------------------------------------------------
  // 4. 完全覆盖 proxy-groups
  // ----------------------------------------------------------

  config["proxy-groups"] = [

    // ========================
    // 主代理选择
    // ========================

    {
      name: "🚀 节点选择",
      type: "select",
      proxies: [
        "实验",
        "♻️ 自动选择",
        "🚀 手动切换",
        "DIRECT",
        "香港",
        "台湾",
        "新加坡",
        "日本",
        "美国",
        "韩国",
        "东南亚",
        "西欧",
        "小众"
      ]
    },


    // ========================
    // 全部节点
    // ========================

    {
      name: "🚀 手动切换",
      type: "select",
      proxies: proxyNames
    },

    {
      name: "♻️ 自动选择",
      ...urlTestBase,
      tolerance: 50,
      proxies: proxyNames
    },


    // ========================
    // 专用业务策略
    // ========================

    {
      name: "🤖 AI 服务",
      type: "select",
      proxies: [
        "美国",
        "新加坡",
        "台湾",
        "香港",
        "日本",
        "韩国",
        "东南亚",
        "西欧",
        "小众",
        "实验",
        "♻️ 自动选择",
        "🚀 手动切换",
        "DIRECT"
      ]
    },

    {
      name: "Telegram",
      type: "select",
      proxies: [
        "实验",
        "♻️ 自动选择",
        "🚀 手动切换",
        "DIRECT",
        "香港",
        "台湾",
        "新加坡",
        "日本",
        "美国",
        "韩国",
        "东南亚",
        "西欧",
        "小众"
      ]
    },

    {
      name: "🎥 奈飞视频",
      type: "select",
      proxies: [
        "小众",
        "🚀 节点选择",
        "🚀 手动切换",
        "实验",
        "♻️ 自动选择",
        "DIRECT",
        "新加坡",
        "香港",
        "台湾",
        "日本",
        "美国",
        "韩国",
        "东南亚",
        "西欧"
      ]
    },

    {
      name: "Ⓜ️ 微软服务",
      type: "select",
      proxies: [
        "DIRECT",
        "实验",
        "🚀 节点选择",
        "🚀 手动切换",
        "美国",
        "香港",
        "台湾",
        "新加坡",
        "日本",
        "韩国",
        "东南亚",
        "西欧",
        "小众"
      ]
    },

    {
      name: "🍎 苹果服务",
      type: "select",
      proxies: [
        "DIRECT",
        "实验",
        "🚀 节点选择",
        "🚀 手动切换",
        "美国",
        "香港",
        "台湾",
        "新加坡",
        "日本",
        "韩国",
        "东南亚",
        "西欧",
        "小众"
      ]
    },

    {
      name: "🎮 游戏平台",
      type: "select",
      proxies: [
        "实验",
        "DIRECT",
        "🚀 节点选择",
        "🚀 手动切换",
        "美国",
        "香港",
        "台湾",
        "新加坡",
        "日本",
        "韩国",
        "东南亚",
        "西欧",
        "小众"
      ]
    },

    {
      name: "🎯 全球直连",
      type: "select",
      proxies: [
        "DIRECT",
        "🚀 节点选择",
        "🚀 手动切换",
        "♻️ 自动选择"
      ]
    },

    // ========================
    // 地区测速组
    // ========================

    {
      name: "实验",
      ...urlTestBase,
      tolerance: 50,
      proxies: experimentalNodes
    },

    {
      name: "香港",
      ...urlTestBase,
      tolerance: 50,
      proxies: hkNodes
    },

    {
      name: "台湾",
      ...urlTestBase,
      tolerance: 50,
      proxies: twNodes
    },

    {
      name: "日本",
      ...urlTestBase,
      tolerance: 50,
      proxies: jpNodes
    },

    {
      name: "美国",
      ...urlTestBase,
      tolerance: 150,
      proxies: usNodes
    },

    {
      name: "新加坡",
      ...urlTestBase,
      tolerance: 50,
      proxies: sgNodes
    },

    {
      name: "韩国",
      ...urlTestBase,
      tolerance: 50,
      proxies: krNodes
    },


    // 原 ini 中这三个是 select
    {
      name: "东南亚",
      type: "select",
      proxies: seaNodes
    },

    {
      name: "西欧",
      type: "select",
      proxies: westEuropeNodes
    },

    {
      name: "小众",
      type: "select",
      proxies: nicheNodes
    }

  ];


  // ----------------------------------------------------------
  // 5. 完全覆盖机场 rule-providers
  // ----------------------------------------------------------

  // 规则源位于 GitHub Raw，统一经主代理组下载，避免直连失败后规则集为空。
  const RULE_PROVIDER_PROXY = "🚀 节点选择";

  const classicalProvider = (url) => ({
    type: "http",
    behavior: "classical",
    format: "text",
    url,
    proxy: RULE_PROVIDER_PROXY,
    interval: 86400
  });

  // MetaCubeX 的 .mrs 是 Mihomo 预编译规则集：域名与 IP 规则分别加载。
  // classical 规则（如 DOMAIN-KEYWORD）不能转换为 .mrs，保留为文本规则集。
  const mrsProvider = (url, behavior, path) => ({
    type: "http",
    behavior,
    format: "mrs",
    path,
    url,
    proxy: RULE_PROVIDER_PROXY,
    interval: 86400
  });

  // 自定义规则保持 YAML / 文本，便于直接在 aenron/Rule_for_self 仓库维护。
  const yamlProvider = (url, behavior, path) => ({
    type: "http",
    behavior,
    format: "yaml",
    path,
    url,
    proxy: RULE_PROVIDER_PROXY,
    interval: 86400
  });

  const metaDomain = (name) => mrsProvider(
    `https://raw.githubusercontent.com/MetaCubeX/meta-rules-dat/meta/geo/geosite/${name}.mrs`,
    "domain",
    `./ruleset/${name}-domain.mrs`
  );

  const metaIp = (name) => mrsProvider(
    `https://raw.githubusercontent.com/MetaCubeX/meta-rules-dat/meta/geo/geoip/${name}.mrs`,
    "ipcidr",
    `./ruleset/${name}-ip.mrs`
  );

  config["rule-providers"] = {

    // MetaCubeX / MetaRulesDat：常用业务和基础直连规则。
    AI: metaDomain("category-ai-!cn"),
    GitHub: metaDomain("github"),
    OneDrive: metaDomain("onedrive"),
    Microsoft: metaDomain("microsoft"),
    ProxyGFWlist: metaDomain("gfw"),
    Telegram: metaDomain("telegram"),
    TelegramIP: metaIp("telegram"),
    Apple: metaDomain("apple"),
    Netflix: metaDomain("netflix"),
    // aenron/Rule_for_self：直接读取可编辑的 YAML / 文本自定义规则。
    // 规则模板见本目录的 Rule_for_self_meta 文件夹。
    CustomProxyDomain: yamlProvider(
      "https://raw.githubusercontent.com/aenron/Rule_for_self/main/Proxy_Domain.yaml",
      "domain",
      "./ruleset/custom-proxy-domain.yaml"
    ),
    CustomDirectDomain: yamlProvider(
      "https://raw.githubusercontent.com/aenron/Rule_for_self/main/Direct_Domain.yaml",
      "domain",
      "./ruleset/custom-direct-domain.yaml"
    ),
    CustomDirectIp: yamlProvider(
      "https://raw.githubusercontent.com/aenron/Rule_for_self/main/Direct_IP.yaml",
      "ipcidr",
      "./ruleset/custom-direct-ip.yaml"
    ),
    CustomProxyClassical: classicalProvider(
      "https://raw.githubusercontent.com/aenron/Rule_for_self/main/Proxy_Classical.list"
    ),
    CustomDirectClassical: classicalProvider(
      "https://raw.githubusercontent.com/aenron/Rule_for_self/main/Direct_Classical.list"
    ),

    GoogleCN: metaDomain("google@cn"),
    SteamCN: metaDomain("steam@cn"),
    Epic: metaDomain("epicgames"),
    Sony: metaDomain("sony"),
    Steam: metaDomain("steam"),
    Nintendo: metaDomain("nintendo")

  };


  // ----------------------------------------------------------
  // 6. 完全覆盖机场 rules
  //
  // 顺序基本保持你的 Full_only_self_use.ini
  // ----------------------------------------------------------

  config.rules = [
  
    // eastcom-sw.com 兜底直连
    "DOMAIN-SUFFIX,eastcom-sw.com,DIRECT",

    // 自定义规则：始终拥有最高业务优先级。
    "RULE-SET,CustomProxyDomain,🚀 节点选择",
    "RULE-SET,CustomProxyClassical,🚀 节点选择",
    "RULE-SET,CustomDirectDomain,🎯 全球直连",
    "RULE-SET,CustomDirectIp,🎯 全球直连,no-resolve",
    "RULE-SET,CustomDirectClassical,🎯 全球直连",

    // 专用业务规则必须在 GFW 通用规则前，以便独立策略组实际生效。
    // AI
    "RULE-SET,AI,🤖 AI 服务",

    // Microsoft
    // GitHub 已从 Microsoft 聚合规则中拆出，必须优先于 Microsoft。
    "RULE-SET,GitHub,🚀 节点选择",
    "RULE-SET,OneDrive,Ⓜ️ 微软服务",
    "RULE-SET,Microsoft,Ⓜ️ 微软服务",

    // 国内服务
    "RULE-SET,GoogleCN,🎯 全球直连",
    "RULE-SET,SteamCN,🎯 全球直连",

    // Telegram
    "RULE-SET,Telegram,Telegram",
    "RULE-SET,TelegramIP,Telegram",

    // Apple
    "RULE-SET,Apple,🍎 苹果服务",

    // 游戏
    "RULE-SET,Epic,🎮 游戏平台",
    "RULE-SET,Sony,🎮 游戏平台",
    "RULE-SET,Steam,🎮 游戏平台",
    "RULE-SET,Nintendo,🎮 游戏平台",

    // Netflix
    "RULE-SET,Netflix,🎥 奈飞视频",

    // GFW：通用代理兜底，放在所有专用业务规则之后。
    "RULE-SET,ProxyGFWlist,🚀 节点选择",


    // 未命中专用业务、GFW 或自定义代理规则的流量默认直连。
    "MATCH,DIRECT"
  ];


// ----------------------------------------------------------
// 7. DNS：国内默认阿里/腾讯 DoH，国外和代理业务使用 Cloudflare/Google DoH。
// ----------------------------------------------------------

config.dns = config.dns || {};

const domesticDns = [
  "https://dns.alidns.com/dns-query",
  "https://doh.pub/dns-query"
];

// #🚀 节点选择 让国外 DoH 经主代理组连接，避免其在国内网络中被阻断。
const overseasDns = [
  "https://cloudflare-dns.com/dns-query#🚀 节点选择",
  "https://dns.google/dns-query#🚀 节点选择"
];

config.dns.enable = true;
// 仅用于解析 DoH 服务器域名的启动 DNS，必须为 IP 地址。
config.dns["default-nameserver"] = ["223.5.5.5", "119.29.29.29"];
config.dns.nameserver = domesticDns;
config.dns.fallback = overseasDns;
config.dns["proxy-server-nameserver"] = domesticDns;
config.dns["fallback-filter"] = {
  geoip: true,
  "geoip-code": "CN"
};

// nameserver-policy 优先级高于 nameserver/fallback：明确代理的业务直接使用国外 DoH。
config.dns["nameserver-policy"] = {
  "rule-set:CustomProxyDomain": overseasDns,
  "rule-set:AI": overseasDns,
  "rule-set:GitHub": overseasDns,
  "rule-set:OneDrive": overseasDns,
  "rule-set:Microsoft": overseasDns,
  "rule-set:ProxyGFWlist": overseasDns,
  "rule-set:Telegram": overseasDns,
  "rule-set:Netflix": overseasDns,
  "rule-set:Epic": overseasDns,
  "rule-set:Sony": overseasDns,
  "rule-set:Steam": overseasDns,
  "rule-set:Nintendo": overseasDns,
  "rule-set:GoogleCN": domesticDns,
  "rule-set:SteamCN": domesticDns
};

const oldFakeIpFilter = Array.isArray(config.dns["fake-ip-filter"])
  ? config.dns["fake-ip-filter"]
  : [];

const extraFakeIpFilter = [
  "eastcom-sw.com",
  "*.eastcom-sw.com"
];

config.dns["fake-ip-filter"] = [
  ...oldFakeIpFilter,
  ...extraFakeIpFilter.filter(
    item => !oldFakeIpFilter.includes(item)
  )
];


// ----------------------------------------------------------
// 8. 返回修改后的配置
// ----------------------------------------------------------

  return config;
}
