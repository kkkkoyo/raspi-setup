#!/usr/bin/env bash
set -e  # エラーが出たら停止
set -o pipefail

# ============================================================
# Raspberry Pi 環境セットアップスクリプト
#   - システム更新・依存パッケージのインストール
#   - dotfiles のクローン＆リンク
#   - Python 環境（pyenv / pipenv）の構築
#   - 各ステップの進行状況を自動表示
#   - 関数と配列で後から自由にステップを追加・削除可能
#
# 📘 使い方:
#   chmod +x setup_env.sh
#   ./setup_env.sh
#
# 🧩 ステップ追加方法:
#   1. 下に新しい関数を追加（例: step_install_extras）
#   2. 下部の STEPS 配列に "説明文:関数名" の形式で1行追加
#   3. 自動的にステップ数と進行率が調整される！
# ============================================================

DOTFILES_REPO="https://github.com/kkkkoyo/dotfiles"
DOTFILES_DIR="$HOME/dotfiles"

# ======== 各ステップ関数の定義 ========

step_update_upgrade() {
  sudo apt update -y
  sudo apt full-upgrade -y
}

step_install_dependencies() {
  # pyenv のビルド/一般利用に必要なツール + git を入れる
  sudo apt install -y \
    make build-essential libssl-dev zlib1g-dev \
    libbz2-dev libreadline-dev libsqlite3-dev wget curl llvm \
    libncursesw5-dev xz-utils tk-dev libxml2-dev libxmlsec1-dev \
    libffi-dev liblzma-dev libgdbm-dev libnss3-dev uuid-dev \
    git ca-certificates
}

step_clone_dotfiles() {
  if [ -d "$DOTFILES_DIR/.git" ]; then
    echo "dotfiles already exists. Pulling latest..."
    git -C "$DOTFILES_DIR" pull --ff-only
  else
    git clone "$DOTFILES_REPO" "$DOTFILES_DIR"
  fi
  # （必要ならサブモジュールも初期化）
  if [ -f "$DOTFILES_DIR/.gitmodules" ]; then
    git -C "$DOTFILES_DIR" submodule update --init --recursive
  fi
}

step_link_dotfiles() {
  cd "$DOTFILES_DIR"
  chmod +x ./dotfilesLink.sh || true
  if [ ! -f ./dotfilesLink.sh ]; then
    echo "⚠️ dotfilesLink.sh が見つかりませんでした: $DOTFILES_DIR"
    return 1
  fi
  # 対話無しで走らせたい場合: dotfilesLink.sh の仕様に合わせてオプションを渡す
  ./dotfilesLink.sh
}

step_clone_pyenv() {
  if [ ! -d "$HOME/.pyenv" ]; then
    git clone https://github.com/pyenv/pyenv.git ~/.pyenv
  else
    echo "pyenv already exists. Skipping clone."
  fi
}

step_configure_bashrc() {
  # dotfiles で .bashrc が張られてから追記チェックを行う
  if ! grep -q 'export PYENV_ROOT=' ~/.bashrc 2>/dev/null; then
    {
      echo 'export PYENV_ROOT="$HOME/.pyenv"'
      echo 'export PATH="$PYENV_ROOT/bin:$PATH"'
      echo 'if command -v pyenv >/dev/null 2>&1; then'
      echo '  eval "$(pyenv init -)"'
      echo 'fi'
    } >> ~/.bashrc
  fi
  export PYENV_ROOT="$HOME/.pyenv"
  export PATH="$PYENV_ROOT/bin:$PATH"
  eval "$(pyenv init -)"
}

step_install_python() {
  if ! pyenv versions --bare | grep -q "^3\.10\.5$"; then
    pyenv install 3.10.5
  else
    echo "Python 3.10.5 already installed."
  fi
  pyenv global 3.10.5
}

step_install_tools() {
  sudo apt install -y pipenv vim
}

step_cleanup() {
  sudo apt autoremove -y
  sudo apt clean
}

# ======== ステップ追加例（コメントとして残す） ========
# 例: 新しいパッケージを入れたい場合
# step_install_extras() {
#   sudo apt install -y tree htop bat
# }
# → 下の STEPS 配列に
#    "Installing extra tools:step_install_extras"
#   を追加すればOK！
# =========================================================

# ======== ステップ一覧（順番どおり実行される） ========
# dotfiles は bashrc 設定より前に実行しておくのが安全
STEPS=(
  "Updating and upgrading system packages:step_update_upgrade"
  "Installing build dependencies (incl. git):step_install_dependencies"
  "Cloning dotfiles:step_clone_dotfiles"
  "Linking dotfiles:step_link_dotfiles"
  "Cloning pyenv:step_clone_pyenv"
  "Configuring bashrc for pyenv:step_configure_bashrc"
  "Installing Python 3.10.5:step_install_python"
  "Installing pipenv and vim:step_install_tools"
  "Cleaning up:step_cleanup"
)

# ======== 実行ループ（進行状況表示） ========
TOTAL_STEPS=${#STEPS[@]}
CURRENT=0

for entry in "${STEPS[@]}"; do
  desc="${entry%%:*}"
  func="${entry##*:}"
  CURRENT=$((CURRENT + 1))
  PERCENT=$((CURRENT * 100 / TOTAL_STEPS))
  echo ""
  echo "🔹 [${CURRENT}/${TOTAL_STEPS}] (${PERCENT}%) ${desc}"
  echo "---------------------------------------------"
  ${func}
done

echo ""
echo "✅ All ${TOTAL_STEPS} steps completed successfully!"
echo "Please restart your terminal or run: source ~/.bashrc"
echo "Python version: $(python3 --version 2>/dev/null || echo 'not yet loaded')"
