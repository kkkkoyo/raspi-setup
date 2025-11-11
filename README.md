# Raspberry Pi Environment Setup

Raspberry Pi で開発環境を一括構築するためのスクリプトです。  
以下を自動で実行します：

- システムの更新と依存パッケージのインストール  
- dotfiles のクローンとリンク  
- Python 環境（pyenv / pipenv）のセットアップ  
- 各ステップ進行状況の表示  

---

## 使い方

### リポジトリをクローン

```bash
git clone https://github.com/kkkkoyo/raspi-env-setup.git
cd raspi-env-setup
````

### スクリプトに実行権限を付与

```bash
chmod +x setup_env.sh
```

### セットアップを実行

```bash
./setup_env.sh
```

> sudo パスワードの入力が求められる場合があります。
> 実行後、`source ~/.bashrc` またはターミナル再起動で pyenv などの設定が反映されます。

---

## ステップの追加方法

1. `setup_env.sh` 内に新しい関数を追加します（例）：

   ```bash
   step_install_extras() {
     sudo apt install -y tree htop bat
   }
   ```

2. ファイル末尾付近の `STEPS` 配列に追加：

   ```bash
   STEPS=(
     ...
     "Installing extra tools:step_install_extras"
   )
   ```

> ステップ数・進行率は自動で更新されます。

---

## セットアップ完了後の確認

以下を実行して、環境が正しく構築されたか確認します。

```bash
source ~/.bashrc
python3 --version
```

> Python 3.10.5 が表示されれば成功です。

---

## ディレクトリ構成

```bash
raspi-env-setup/
├── setup_env.sh     # メインセットアップスクリプト
└── README.md        # このファイル
```
