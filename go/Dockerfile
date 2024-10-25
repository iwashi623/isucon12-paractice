FROM golang:1.18.4-bullseye

# 作業ディレクトリを指定
WORKDIR /tmp

# 非対話モードの設定
ENV DEBIAN_FRONTEND=noninteractive

# 必要なパッケージをインストール
RUN apt-get update && \
    apt-get -y upgrade && \
    apt-get install -y wget gcc g++ make sqlite3 gnupg && \
    curl -fsSL https://repo.mysql.com/RPM-GPG-KEY-mysql-2023 | gpg --dearmor -o /usr/share/keyrings/mysql.gpg && \
    echo "deb [signed-by=/usr/share/keyrings/mysql.gpg] http://repo.mysql.com/apt/debian bullseye mysql-apt-config" | tee /etc/apt/sources.list.d/mysql.list && \
    apt-get update && \
    apt-get -y install default-mysql-client && \
    apt-get clean

# ユーザーの作成と権限の変更
RUN useradd --uid=1001 --create-home isucon
USER isucon

# 作業ディレクトリを移動し、コードをコピー
RUN mkdir -p /home/isucon/webapp/go
WORKDIR /home/isucon/webapp/go
COPY --chown=isucon:isucon ./ /home/isucon/webapp/go/

# Goの環境変数を設定
ENV GOPATH=/home/isucon/tmp/go
ENV GOCACHE=/home/isucon/tmp/go/.cache

# 実行コマンド
CMD ["./isuports"]
