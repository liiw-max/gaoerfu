#!/usr/bin/env bash
# ============================================================================
#  一键发布到 Cloudflare Pages
#  ---------------------------------------------------------------------------
#  前置：
#    1. 装 Node.js 18+（带 npx）
#    2. 首次运行会打开浏览器让你登录 Cloudflare；CI 里改用环境变量：
#         export CLOUDFLARE_API_TOKEN=...
#         export CLOUDFLARE_ACCOUNT_ID=...
#
#  用法：
#    bash deploy-cf.sh
#    PROJECT=luma-prod bash deploy-cf.sh     # 换项目名
#
#  发布产物：https://<项目名>.pages.dev
# ============================================================================
set -euo pipefail

cd "$(dirname "${BASH_SOURCE[0]}")"

PROJECT="${PROJECT:-luma-beam}"
BRANCH="${BRANCH:-main}"

if ! command -v npx >/dev/null 2>&1; then
  echo "找不到 npx。先装 Node.js 18+（https://nodejs.org），或者用面板拖拽上传。" >&2
  exit 1
fi

echo "==> 发布目录：$(pwd)"
echo "==> 项目：$PROJECT   分支：$BRANCH"
echo

# 项目不存在就建一个；已存在时这条会报错，忽略即可
npx --yes wrangler@latest pages project create "$PROJECT" \
  --production-branch "$BRANCH" >/dev/null 2>&1 || true

npx --yes wrangler@latest pages deploy . \
  --project-name "$PROJECT" \
  --branch "$BRANCH" \
  --commit-dirty=true

echo
echo "==> 完成。上面 Deployment 那一行的链接就是预览地址；"
echo "    正式地址：https://${PROJECT}.pages.dev"
