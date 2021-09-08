Node-REDで作る空メール登録システム
================

# 概要

SendGridとNode-REDを利用した空メール登録システムのサンプルアプリケーションです。記事は[SendGridのブログ](https://sendgrid.kke.co.jp/blog/)にて公開しています。

# 環境構築

## 前提条件

今回利用したツールとそのバージョンは次の通りです。

- [Node.js](https://nodejs.org/ja/)：v16.5.0
- [Node-RED](https://nodered.org/)：v2.0.6
- [Gitクライアント](https://git-scm.com/)：v2.31.1
- [ngrok](https://ngrok.com/)：v2.3.35
- [Docker Engine](https://www.docker.com/)：v20.10.8
- [docker-compose](https://docs.docker.jp/compose/toc.html)：v2.0.0-rc.2

MacOSおよびAmazon Linux上で動作確認しています。各ツールのインストールを完了させます。

## 手順
### ngrokの起動
まずはじめに、Inbound Parse Webhookを受信するためにngrokを起動します。1880はNode-REDの待ち受けポート番号です。

```
$ ngrok http 1880
```

起動すると自動的にホスト名が付与されるのでメモしておきます。このホスト名は後でいくつかの場所に設定していきます。

|<img src="docs/images/ngrok1.png" width="75%">|
|:-|

### Inbound Parse Webhookの設定
[ドキュメントの手順](https://sendgrid.kke.co.jp/docs/Tutorials/E_Receive_Mail/receive_mail.html)に従ってInbound Parse Webhookを設定します。ポイントは以下のとおりです。

- **Receiving Domain**
    - メールの宛先ドメイン
- **Destination URL**
    - 「https://＋ngrokの待受ホスト名＋/inbound 」のフォーマットで指定します
    - 例：https://5eae-101-110-33-89.ngrok.io/inbound
- **Additional Option**
    - チェックはすべてOFFにします

|<img src="docs/images/inbound-parse1.png" width="50%">|
|:-|

### APIキーの作成
[ドキュメントの手順](https://sendgrid.kke.co.jp/docs/Tutorials/A_Transaction_Mail/manage_api_key.html)に沿ってAPIキーを作成します。必要なパーミッションは「**Mail Send**」の「**Full Access**」です。

|<img src="docs/images/apikey1.png" width="75%">|
|:-|

作成したAPIキーは、次の手順で使用するためクリップボードにコピーしておきます。

|<img src="docs/images/apikey2.png" width="75%">|
|:-|

### 環境変数の登録
環境変数に以下のキーと値を登録します。

|  キー  |  値  |
| ---- | ---- |
|  HTTP_HOSTNAME  |  ngrokのホスト名<br>例：5eae-101-110-33-89.ngrok.io  |
|  API_KEY  |  SendGridのAPIキー<br>例：SG.xxxxxxxxxxxxx.xxxxxxxxxxxxxx  |

以下は「**~/.bash_profile**」に登録する例です。`source`コマンドで設定したファイルの内容を読み込んでおきます。

```
$ less ~/.bash_profile

export HTTP_HOSTNAME="5eae-101-110-33-89.ngrok.io"
export API_KEY="SG.xxxxxxxxxxxxx.xxxxxxxxxxxxxx"

$ source ~/.bash_profile
```

### Node-REDの起動
Node-REDを起動して設定ファイルなどを自動生成します。ポート番号1880がngrokの待ち受けポートと一致することを確認します。

```
$ cd ~
$ node-red
〜〜省略〜〜
6 Sep 18:10:05 - [info] フローを開始します
6 Sep 18:10:05 - [info] フローを開始しました
6 Sep 18:10:05 - [info] サーバは http://127.0.0.1:1880/ で実行中です
```

起動したらCtrl+Cキーで一旦Node-REDを停止します。

```
^C6 Sep 18:12:07 - [info] フローを停止します
6 Sep 18:12:07 - [info] フローを停止しました
```

### Node-REDのプロジェクトを有効化
Node-REDの**settings.js**ファイルを編集します。

```
$ vi ~/.node-red/settings.js
```

「**editorTheme > projects > enabled**」の値を「**true**」に変更して[プロジェクト機能を有効化](https://nodered.jp/docs/user-guide/projects/#%E3%83%97%E3%83%AD%E3%82%B8%E3%82%A7%E3%82%AF%E3%83%88%E3%82%92%E6%9C%89%E5%8A%B9%E5%8C%96%E3%81%99%E3%82%8B)します。

```
  editorTheme: {
       projects: {
           enabled: true
       }
   },
```

**settings.js**ファイルを編集ししたらNode-REDをもう一度起動します。

```
$ node-red
〜〜省略〜〜
6 Sep 18:10:05 - [info] フローを開始します
6 Sep 18:10:05 - [info] フローを開始しました
6 Sep 18:10:05 - [info] サーバは http://127.0.0.1:1880/ で実行中です
```

### プロジェクトの初期設定
ブラウザから「http://localhost:1880/ 」にアクセスしてNode-REDのフローエディタを表示します。プロジェクトの初期設定画面が表示されるので「**Clone Repository**」を選択します。

![](docs/images/node-red2.png)

GitHubの「**Username**」と「**Email**」を設定して「**Next**」を選択します。

|<img src="docs/images/node-red3.png" width="75%">|
|:-|

以下のように設定して「**Clone project**」を選択します。

- **Project name**
    - node-red-example
- **Git repository URL**
    - https://github.com/SendGridJP/node-red-example

|<img src="docs/images/node-red4.png" width="75%">|
|:-|

いくつかのノードタイプがない旨エラーメッセージが表示されますが、ここではひとまず「**Close**」を選択して閉じます。

|![](docs/images/node-red5.png)|
|:-|

画面右上のメニューから「**Projects > Project Settings**」を選択します。

|<img src="docs/images/node-red6.png" width="75%">|
|:-|

「**Dependencies**」を選択して、それぞれの依存関係をインストールします。

|<img src="docs/images/node-red7.png" width="75%">|
|:-|

「**Close**」を選択して設定画面を閉じます。

|<img src="docs/images/node-red8.png" width="75%">|
|:-|

一度ブラウザの画面をリロードします。

|![](docs/images/node-red1.png)|
|:-|

以下のコマンドでMySQL環境を構築します。

```
$ cd ~/.node-red/projects/node-red-example/
$ docker-compose up -d --force-recreate --build
Building mysql
Step 1/4 : FROM mysql
 ---> 0716d6ebcc1a
Step 2/4 : EXPOSE 3306
 ---> Using cache
 ---> ac70f8c41da4
Step 3/4 : ADD ./my.cnf /etc/mysql/conf.d/my.cnf
 ---> Using cache
 ---> dc43457ed364
Step 4/4 : CMD ["mysqld"]
 ---> Using cache
 ---> ef69d0e239e3
Successfully built ef69d0e239e3
Successfully tagged mysql:inbound
Recreating noderedexample_mysql_1 ... done
```

MySQL環境構築のために1分ほど待ってから、以下のコマンドでMySQLが起動していることを確認します。

```
$ docker-compose logs
〜〜省略〜〜
mysql_1  | 2021-09-08T08:24:40.537761Z 0 [System] [MY-011323] [Server] X Plugin ready for connections. Bind-address: '::' port: 33060, socket: /var/run/mysqld/mysqlx.sock
mysql_1  | 2021-09-08T08:24:40.538093Z 0 [System] [MY-010931] [Server] /usr/sbin/mysqld: ready for connections. Version: '8.0.26'  socket: '/var/run/mysqld/mysqld.sock'  port: 3306  MySQL Community Server - GPL.
```

# 動作確認

## 空メール送信
Inbound Parse Webhookで設定した受信ドメイン宛に空メールを送ります。ローカルパートは適当な文字列を指定します。

|<img src="docs/images/mail1.png" width="75%">|
|:-|

ngrokがInbound Parse Webhookを受信すると「**200 OK**」が表示されます。

|<img src="docs/images/ngrok2.png" width="75%">|
|:-|

Node-REDの画面上で「**debug**」ボタンを選択すると、デバッグログが確認できます。この中に「**statusCode: 202**」の表示があれば、SendGridに対するメール送信リクエストが成功しています。

|<img src="docs/images/node-red9.png" width="50%">|
|:-|

しばらく待つとユーザー登録用メールが届くので、メール本文内のURLにアクセスします。

|<img src="docs/images/mail2.png" width="75%">|
|:-|

ブラウザ上にユーザー登録フォームが表示されるので、適当なニックネームを入力して「**送信**」を選択します。

|<img src="docs/images/form1.png" width="50%">|
|:-|

登録に成功すると以下のようなメッセージが表示されます。

|<img src="docs/images/form2.png" width="50%">|
|:-|

一方、既に同じメールアドレスが登録済みなど、登録に失敗した場合は以下のようなメッセージが表示されます。

|<img src="docs/images/form3.png" width="50%"><br>|
|:-|

|<img src="docs/images/form4.png" width="50%">|
|:-|

以上で動作確認完了です。

# 注意点
このサンプルを利用する際の注意点は以下の通りです。

- データベースのパスワードはdocker-compose.ymlに直書きしてあるので、環境変数から読み込むようにするなど、パスワードが晒されないようにしてください
- ノードのプロパティに保存する認証情報を暗号化する場合は、Node-REDのセキュアパラメータ暗号化機能を有効化してください
