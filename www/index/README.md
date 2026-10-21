# LUMA Beam — 单品落地页（Cloudflare Pages）

一个单 SKU、单报价的海外投放页。整页只有一个 `index.html`，没有任何外部依赖（字体、图片、脚本全在文件里），所以传到 Cloudflare 就能跑，不需要服务器、不需要证书。

```
luma-beam/
├── index.html        页面本体（约 70 KB，gzip 后 17 KB）
├── _headers          Cloudflare 专用：安全响应头 + 缓存策略
├── _redirects        Cloudflare 专用：/lp/meta、/lp/tiktok 等渠道短链
├── 404.html          自定义 404（Pages 会自动识别并返回 404 状态码）
├── favicon.svg
├── robots.txt
└── deploy-cf.sh      一条命令发布
```

---

## 1. 本地看效果

直接双击 `index.html` 就能打开，交互全都能用（加购、抽屉、颜色切换、FAQ）。

想更接近线上环境（`_headers` 才会生效）：

```bash
npx serve .
# 或 python -m http.server 8080
```

> `_headers` 和 `_redirects` **只有 Cloudflare 会读**，本地静态服务器会忽略它们，这是正常的。

---

## 2. 发布到 Cloudflare Pages

### 方式 A：命令行（最快，改完就发）

```bash
bash deploy-cf.sh
```

首次会打开浏览器登录。发布完会打印 `https://luma-beam.pages.dev`。

CI 里用 API Token：

```bash
export CLOUDFLARE_API_TOKEN=...      # 权限：Account → Cloudflare Pages → Edit
export CLOUDFLARE_ACCOUNT_ID=...
bash deploy-cf.sh
```

### 方式 B：面板拖拽（不想碰命令行）

Cloudflare 面板 → Workers & Pages → Create → Pages → **Upload assets** → 把 `luma-beam` 整个文件夹拖进去。免费版支持直接上传，不用 Git。

### 方式 C：连 GitHub 自动部署

把仓库推到 GitHub，面板里选 **Connect to Git**。构建配置：

| 项 | 值 |
|---|---|
| Framework preset | None |
| Build command | 留空 |
| Build output directory | `luma-beam` |

之后每次 push 自动发布，每次 PR 还会生成独立的预览链接（方便给客户看改版）。

---

## 3. 绑定自己的域名

Pages 项目 → Custom domains → Set up a domain。

如果域名已经托管在 Cloudflare，它会自动加一条 CNAME 并签发证书，几分钟生效；不在 CF 的话，按提示到域名商加 CNAME 指向 `<项目名>.pages.dev`。

绑定后建议顺手在 SSL/TLS 里开 **Always Use HTTPS**（Pages 本身已经强制 HTTPS，双保险）。

---

## 4. 接支付

页面里的 `Checkout` 现在只弹提示。两种接法：

**A. 单件直接卖（最简单，不用后端）**

在 Stripe 建三个 Payment Link，分别对应三个套装，然后填进 `index.html` 里的：

```js
const CHECKOUT_URLS = {
  solo:   "https://buy.stripe.com/xxxx",
  cinema: "https://buy.stripe.com/yyyy",
  home:   "https://buy.stripe.com/zzzz"
};
```

购物车只有一行时，点 Checkout 会直接跳到对应收银台。卡号不经过你的页面，也就不需要过 PCI-DSS。

**B. 多件合并结算**

静态页算不了价，得加一层：

- **Cloudflare Worker** 调 Stripe API 动态创建 Checkout Session（推荐，和 Pages 同一个账号，能直接绑在 `/api/checkout`）
- 或者用 **Shopify Buy Button** 直接把商品嵌进来，购物车交给 Shopify

**C. 合规绕不过去的一点**：卖到欧盟要处理 VAT，卖到英国要处理 UK VAT。自己注册申报很麻烦，用 Paddle / Lemon Squeezy 这类 MoR（Merchant of Record）可以让他们代收代缴。

---

## 5. 改成自己的商品

全部集中在两个地方，改完不用动 HTML 结构。

### 商品与价格

`index.html` 底部 `<script>` 开头：

```js
const BUNDLES = {
  solo:   { name:"Solo",   price:299, was:399, desc:"LUMA Beam projector" },
  cinema: { name:"Cinema", price:339, was:417, desc:"Beam + tripod + 80-inch screen" },
  home:   { name:"Home",   price:359, was:446, desc:"Beam + tripod + screen + carry case" }
};

const COLORS = {
  obsidian: { name:"Obsidian", top:"#3A4249", mid:"#1B2024", bot:"#0C0F11" },
  chalk:    { name:"Chalk",    top:"#F2EFE8", mid:"#D5D0C6", bot:"#A9A398" }
};
```

`price` 是现价，`was` 是划线价，`Save $xx` 和 CTA 里的金额都会自动算。

### 品牌色

`:root` 里改三个就够：`--accent`（主按钮/强调）、`--accent-2`（价格标签/星星）、`--dark`（深色区背景）。

### 商品图换成真图

搜 `class="stage"` 那一段，把里面的 `.screen` / `.beam` / `.projector` 三个 div 整体换成：

```html
<img src="product.jpg" alt="LUMA Beam" style="width:100%;height:auto;border-radius:16px">
```

真图建议 1200×1200 的 WebP，控制在 200 KB 内 —— 这是 LCP 元素，直接影响广告的落地页体验评分。

### 换成真实文案时别漏了

页面上所有数字（4.8 分、1,926 条评价、1,840 sold、倒计时）都是**示例**，页脚已标注 Demo。上线前必须换成真实数据：

- 虚构评价和"1,840 sold this month"：FTC 的 Review Rule（2024 年生效）和 EU UCPD 都明确认定为欺诈性广告，罚款按次计
- 倒计时：`PROMO_ENDS` 是硬编码的活动截止时间，活动结束就自动隐藏。别做成「每次刷新重新计时」——那是虚假紧迫感
- 医疗/性能宣称：投影仪讲亮度没问题，但"护眼""不伤视力"这类需要临床依据

---

## 6. Cloudflare 上必须知道的四件事

**① `_headers` 只在 CF 生效**
换到 nginx 托管时它不会被读，得把响应头搬到 nginx 配置里（`deploy/nginx/security-headers.conf` 已经有一份对应的）。这是我没有把两套配置混在一起的原因。

**② CSP 会静默拦掉埋点**
`_headers` 里的 CSP 只放行了 `'self'`。接 Meta / TikTok 像素时如果不把域名加进 `script-src` / `connect-src`，表现是「像素加载正常、后台一个事件都收不到」。文件末尾已经写好了替换版本，照着改。

**③ HTML 不缓存，静态资源长缓存**
`/` 和 `/index.html` 是 `max-age=0, must-revalidate`，所以改完发布立刻生效，不需要手动清缓存。`favicon.svg` 这类带哈希的可以设一年。

**④ Pages 免费版的边界**
无限带宽和请求，每月 500 次构建，单文件上限 25 MB。这个页面 70 KB，怎么都够。真正要注意的是**图片**：以后加商品图、场景图，务必先压缩，否则 LCP 会掉到 3 秒以上，广告的落地页体验分会被拉低。

---

## 7. 上线前检查

- [ ] 手机 4G 实机走一遍：切套装 → 加购 → 抽屉加减 → Checkout
- [ ] [PageSpeed Insights](https://pagespeed.web.dev/) 移动端 LCP < 2.5s、CLS < 0.1
- [ ] 三个渠道短链 `/lp/meta`、`/lp/tiktok`、`/lp/ig` 都能跳到首页且带 302
- [ ] 404 路径返回的是 404 状态码而不是 200（用 `curl -I https://域名/xxx` 确认）
- [ ] 埋点用 Meta Event Manager 的 Test Events 验证事件真的到达
- [ ] 页脚邮箱、退货政策、公司主体换成真的（欧盟还要求 Impressum）

**一处说明**：这个页面没有做 Cookie 同意条。只投美国市场问题不大，投欧盟/英国必须有 —— `overseas/index.html` 里有一个现成的实现可以搬过来。
