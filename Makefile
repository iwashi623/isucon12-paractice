now = $(shell date "+%Y%m%d%H%M%S")

.PHONY: bn
bn:
	make re
	../bench run --enable-ssl

# アプリ､nginx､mysqlの再起動
.PHONY: re
re:
	make arestart
	make nrestart
	# make mrestart
	ssh 54.65.171.13 -A "cd webapp && make mrestart"

# アプリの再起動
.PHONY: arestart
arestart:
	sudo systemctl restart isupipe-go
	sudo systemctl status isupipe-go

# nginxの再起動
.PHONY: nrestart
nrestart:
	sudo rm /var/log/nginx/access.log
	sudo systemctl reload nginx
	sudo systemctl status nginx

# mysqlの再起動
.PHONY: mrestart
mrestart:
	sudo rm /var/log/mysql/slow.log
	sudo mysqladmin flush-logs -pisucon
	sudo systemctl restart mysql
	sudo systemctl status mysql
	echo "set global slow_query_log = 1;" | sudo mysql -pisucon
	echo "set global slow_query_log_file = '/var/log/mysql/slow.log';" | sudo mysql -pisucon
	echo "set global long_query_time = 0;" | sudo mysql -pisucon

# 分割後のMysqlの再起動(二代目でmrestartを実行する)
# .PHONY: mrestart
# mrestart:
# 	ssh 192.168.0.12 -A "cd webapp && make mrestart"

# アプリのログを見る
.PHONY: nalp
nalp:
	sudo cat /var/log/nginx/access.log | alp ltsv -m "/api/livestream/\d+/statistics","^/api/user/[\w\d]+$","/api/user/[\w\d]+/icon","/api/user/[\w\d]+/statistics","/api/livestream/\d+/ngwords","/api/livestream/\d+/reaction","/api/livestream/\d+/livecomment","/api/livestream/\d+/enter","/api/livestream/\d+/moderate","/api/livestream/\d+/report","/api/livestream/\d+/exit","/api/livestream/\d+$","/api/user/\d+$","/api/user/[\w\d]+/theme","/api/user/[\d\w]+/livestream","/assets/.+\.webp","/assets/.+\.js","/assets/.+\.css","/assets/.+\.png" --sort=sum --reverse

# mysqlのslowlogを見る
.PHONY: pt
pt:
	@now=$$(date +%Y%m%d%H%M%S); \
	sudo pt-query-digest /var/log/mysql/slow.log >> ~/pt$${now}.log

# pprofを実行する
.PHONY: pprof
pprof:
	go tool pprof http://localhost:6060/debug/pprof/profile?seconds=45


# Goのビルド
.PHONY: build
build:
	cd go && CGO_ENABLED=0 GOOS=linux GOARCH=amd64 go build -o isupipe -ldflags "-s -w"

# Goのビルドと1台目へのGoのバイナリアップロード
.PHONY: upload1
upload1: build
	ssh isucon@i1 'sudo systemctl stop isupipe-go'
	scp ./go/isupipe isucon@i1:/home/isucon/webapp/go/isupipe
	ssh isucon@i1 'sudo systemctl restart isupipe-go'
	ssh isucon@i1 'sudo systemctl status isupipe-go'

# Goのビルドと2台目へのGoのバイナリアップロード
.PHONY: upload2
upload2: build
	ssh isucon@i2 'sudo systemctl stop isupipe-go'
	scp ./go/isupipe isucon@i2:/home/isucon/webapp/go/isupipe
	ssh isucon@i2 'sudo systemctl restart isupipe-go'
	ssh isucon@i2 'sudo systemctl status isupipe-go'

# Goのビルドと3台目へのGoのバイナリアップロード
.PHONY: upload3
upload3: build
	ssh isucon@i3 'sudo systemctl stop isupipe-go'
	scp ./go/isupipe isucon@i3:/home/isucon/webapp/go/isupipe
	ssh isucon@i3 'sudo systemctl restart isupipe-go'
	ssh isucon@i3 'sudo systemctl status isupipe-go'

# 1台目､2台目､3台目へのGoのバイナリアップロード
.PHONY:
all:
	make upload1
	make upload2
	make upload3

.PHONY: zenbu
zenbu:
	make all
	ssh isucon@i1 -A 'cd webapp && make re'
	ssh isucon@i2 -A 'cd webapp && make re'
	ssh isucon@i3 -A 'cd webapp && make re'

.PHONY: pbnalp1
pbnalp1:
	ssh isucon@i1 -A "cd webapp && make nalp" | pbcopy

.PHONY: pbnalp2
pbnalp2:
	ssh isucon@i2 -A "cd webapp && make nalp" | pbcopy

.PHONY: pbnalp3
pbnalp3:
	ssh isucon@i3 -A "cd webapp && make nalp" | pbcopy

.PHONY: pbpt1
pbpt1:
	ssh isucon@i1 -A "now=$$(date +%Y%m%d%H%M%S); cd webapp && make pt && cat ~/pt$${now}.log" | pbcopy

.PHONY: pbpt1
pbpt2:
	ssh isucon@i2 -A "now=$$(date +%Y%m%d%H%M%S); cd webapp && make pt && cat ~/pt$${now}.log" | pbcopy

.PHONY: pbpt3
pbpt3:
	ssh isucon@i3 -A "now=$$(date +%Y%m%d%H%M%S); cd webapp && make pt && cat ~/pt$${now}.log" | pbcopy
