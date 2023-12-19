# Debezium ご存じでしょうか

Debeziumをご存じでしょうか？グローバルサミット2023にて、Debeziumを題材としたセッション「Near Real Time Analytics with InterSystems IRIS & Debezium Change Data Capture」がありましたので、ご覧になられた方もおられるかと思います。

> ご興味がありましたら、グローバルサミット2023の[録画アーカイブ](https://www.intersystems.com/near-real-time-analytics-with-intersystems-iris-debezium-change-data-capture-intersystems/)をご覧ください。

CDC(Change data capture)という分野のソフトウェアです。

外部データベースでの変更を追跡して、自身のシステムに反映したいという要望は、インターオペラビリティ機能導入の動機のひとつになっています。一般的には、定期的にSELECT文のポーリングをおこなって、変更対象となるレコード群(差分取得。対象が少なければ全件取得)を外部システムから取得する方法が、お手軽で汎用性も高いですが、タイムスタンプや更新の都度に増加するようなバージョンフィールドが元テーブルに存在しない場合、どうしても、各ポーリング間で重複や見落としがでないように、受信側で工夫する必要があります。また、この方法ではデータの削除を反映することはできませんので、代替案として削除フラグを採用するといったアプリケーションでの対応が必要になります。

CDCは、DBMSのトランザクションログをキャプチャすることで、この課題への解決策を提供しています。[Debezium](https://github.com/debezium/debezium/blob/main/README_JA.md)はIBM, RedHatが中心となっているCDCのオープンソースプロジェクトです。

# CDCの何が良いのか

CDCにはいくつかの利点があります。

- ポーリングではないので、更新が瞬時に伝わる

- DELETEも反映できる

- ソースになるDBMSに対して非侵襲的

    > テーブル定義を変更したり専用のテーブルを作成しなくて済む。パフォーマンスへの影響が軽微。

- 受信側(アプリケーション側)の設計が楽

下記は受信側の仕組みに依存する話ですが、例えばIRISで受信する場合

- ひとつのハンドラ(Restのディスパッチクラス)で、複数のテーブルを処理できる

    > このことはSQLインバウンドサービスがテーブル単位であることと対照的です

一方、トランザクションログのメカニズムは各DBMS固有なので、DBMSやそのバージョン毎に振る舞い、特性が異なる可能性があるというマイナス面があります。

> セットアップ作業は、SQLインバウンドアダプタほど簡単ではありません

# Kafkaのコネクタとしての用法
DebeziumはKafkaのSourceコネクタとして使用する用法が一般的です。

![](https://debezium.io/documentation/reference/stable/_images/debezium-architecture.png)

引用元: https://debezium.io/documentation/reference/stable/architecture.html

> Kafkaのコネクタとしての用法は本稿では扱いません。

今回のメインテーマはKafkaではありませんが、関連するいくつかのKafka用語を確認をしておきたいと思います。

## ProducerとConsumer

Kakfaにメッセージを送信するデータの発生元のことをProducer、メッセージを消費する送信先のことをConsumerと呼びます。

![](https://github.com/IRISMeister/DebeziumServer-IRIS/blob/main/images/1.png?raw=true)

## SourceとSink
外部システムとの連携用のフレームワークをKafkaコネクトと呼びます。Kafkaコネクトにおいて、外部システムと接続する部分をコネクタと呼び、Producer 側の コネクタ は Sourceコネクタ、Consumer 側の コネクタ は Sinkコネクタと、それぞれ呼ばれます。

![](https://github.com/IRISMeister/DebeziumServer-IRIS/blob/main/images/2.png?raw=true)

> DebeziumはKafkaのSourceコネクタです。

# Debeziumのスタンドアロン環境

Kafkaが提供するエンタープライズ級の機能を使いたければ、Kafkaの構成・運用を含めて検討する価値があります。一方、そうでない場合、Debeziumを[単体](https://debezium.io/documentation/reference/stable/operations/debezium-server.html)で動作させることが出来ます。

> Debeziumサーバと言います

![](https://github.com/IRISMeister/DebeziumServer-IRIS/blob/main/images/3.png?raw=true)

随分とすっきりします。

KafkaのSinkコネクタを経由しなくても、Debezium自身が様々な[送信先](https://debezium.io/documentation/reference/stable/operations/debezium-server.html#_sink_configuration)に対応しています。

> Debeziumから見ると、Kafkaは送信先のひとつです。

例えば、「POSTGRES上でのデータ更新をCDCして、その内容をhttp serverに送信」したい場合、
[POSTGRES用のSourceコネクタ](https://debezium.io/documentation/reference/stable/connectors/postgresql.html)と、[http Client](https://debezium.io/documentation/reference/stable/operations/debezium-server.html#_http_client)を使うことになります。

Debeziumは[これら](https://debezium.io/documentation/reference/stable/connectors/index.html)のDBMSに対応しています。

> 残念ながらIRISはソースになれません。IRISからIRISへのデータの同期であれば非同期ミラリングがお勧めです。

# Debeziumサーバの起動

今回使用するソースコード一式は[こちら](https://github.com/IRISMeister/DebeziumServer-IRIS)にあります。
IRIS環境はコミュニティエディションにネームスペースMYAPPの作成と、3個の空のテーブル作成(build/sql/01_createtable.sqlを使用)を行ったものになります。

```
$ git clone https://github.com/IRISMeister/DebeziumServer-IRIS
$ cd DebeziumServer-IRIS
$ cd postgres   (POSTGRESを試す場合。以降POSTGRESを使用します)
あるいは
$ cd mysql      (MYSQLを試す場合)
$ ./up.sh
```

正常に起動した場合、3個のサービスが稼働中になります。
```
$ docker composeps ps
NAME                         IMAGE                       COMMAND                                                     SERVICE           CREATED          STATUS                    PORTS
iris                         postgres-iris               "/tini -- /iris-main --ISCAgent false --monitorCPF false"   iris              12 minutes ago   Up 12 minutes (healthy)   2188/tcp, 53773/tcp, 0.0.0.0:1972->1972/tcp, :::1972->1972/tcp, 54773/tcp, 0.0.0.0:52873->52773/tcp, :::52873->52773/tcp
postgres-debezium-server-1   debezium/server:2.4         "/debezium/run.sh"                                          debezium-server   12 minutes ago   Up 12 minutes             8080/tcp, 8443/tcp, 8778/tcp
postgres-postgres-1          debezium/example-postgres   "docker-entrypoint.sh postgres"                             postgres          12 minutes ago   Up 12 minutes             0.0.0.0:5432->5432/tcp, :::5432->5432/tcp
```

# 動作確認

初期状態を確認します。起動直後に、POSTGRES上の既存のレコード群がIRISに送信されますのでそれを確認します。
> 端末を2個ひらいておくと便利です。以下(端末1)をPOSTGRESの, (端末2)をIRISのSQL実行に使用します。

(端末1)
```
$ docker compose exec -u postgres postgres psql
psql (15.2 (Debian 15.2-1.pgdg110+1))
Type "help" for help.

postgres=# select * from inventory.orders;
  id   | order_date | purchaser | quantity | product_id
-------+------------+-----------+----------+------------
 10001 | 2016-01-16 |      1001 |        1 |        102
 10002 | 2016-01-17 |      1002 |        2 |        105
 10003 | 2016-02-19 |      1002 |        2 |        106
 10004 | 2016-02-21 |      1003 |        1 |        107
(4 rows)

postgres=# select * from inventory.products;
 id  |        name        |                       description                       | weight
-----+--------------------+---------------------------------------------------------+--------
 101 | scooter            | Small 2-wheel scooter                                   |   3.14
 102 | car battery        | 12V car battery                                         |    8.1
 103 | 12-pack drill bits | 12-pack of drill bits with sizes ranging from #40 to #3 |    0.8
 104 | hammer             | 12oz carpenter's hammer                                 |   0.75
 105 | hammer             | 14oz carpenter's hammer                                 |  0.875
 106 | hammer             | 16oz carpenter's hammer                                 |      1
 107 | rocks              | box of assorted rocks                                   |    5.3
 108 | jacket             | water resistent black wind breaker                      |    0.1
 109 | spare tire         | 24 inch spare tire                                      |   22.2

(9 rows)
postgres=# select * from inventory.customers;
  id  | first_name | last_name |         email
------+------------+-----------+-----------------------
 1001 | Sally      | Thomas    | sally.thomas@acme.com
 1002 | George     | Bailey    | gbailey@foobar.com
 1003 | Edward     | Walker    | ed@walker.com
 1004 | Anne       | Kretchmar | annek@noanswer.org
(4 rows)

postgres=# \q
$
```

IRIS上のレコードは下記のコマンドで確認できます。POSTGRES上のレコードと同じになっているはずです。

(端末2)
```
$ docker compose exec iris iris sql iris -Umyapp
[SQL]MYAPP>>set selectmode=odbc
[SQL]MYAPP>>select * from inventory.orders
[SQL]MYAPP>>select * from inventory.products
[SQL]MYAPP>>select * from inventory.customers
```

次に、POSTGRESで各種DMLを実行します。

(端末1)
```
update inventory.orders set quantity=200 where id=10001;
UPDATE 1
postgres=# delete from inventory.orders where id=10002;
DELETE 1
insert into inventory.orders (order_date,purchaser,quantity,product_id) values ('2023-01-01',1003,10,105);
INSERT 0 1
update inventory.products set description='商品説明' where id=101;
UPDATE 1
```

その結果がIRISに伝わり反映されます。

(端末2)
```
[SQL]MYAPP>>select * from inventory.orders
3.      select * from inventory.orders

id      order_date      purchaser   quantity    product_id
10001   2016-01-16      1001        300         102
10003   2016-02-19      1002        2           106
10004   2016-02-21      1003        1           107
10005   2023-01-01      1003        10          105

4 Rows(s) Affected

[SQL]MYAPP>>select * from inventory.products where id=101
4.      select * from inventory.products where id=101

id      name    description     weight
101     scooter 商品説明        3.14

1 Rows(s) Affected
```

# IRIS側の仕組み

Debeziumサーバのhttp clientは、指定したエンドポイントにREST+JSON形式で内容を送信してくれます。エンドポイントにIRISのRESTサービスを指定することで、IRISでその内容をパースし、必要な処理を実行(今回は単純にSQLの実行)しています。

INSERT時には、[こちら](https://github.com/IRISMeister/DebeziumServer-IRIS/blob/main/examples/sink-insert-request-example.json)、UPDATE時には、[こちら](https://github.com/IRISMeister/DebeziumServer-IRIS/blob/main/examples/sink-update-request-example.json)のようなJSONがPOSTされます。

payload.opにPOSTGRESへの操作の値であるc:Create, u:Update, d:Delete, r:Readが伝わりますので、その内容に基づいて、IRISのRESTディスパッチャークラス(build/src/MyApp/Dispatcher.cls)にて、SQL文を組み立てて実行しています。

> r:Readは、初回接続時に実行されるスナップショット取得作業の際に既存のレコード群を読み込み(READ)、それらが送信される場合に使用されます。詳細は[こちら](https://debezium.io/documentation/reference/stable/connectors/postgresql.html#postgresql-snapshots)をご覧ください。

# Debeziumサーバについて
Debeziumサーバの詳細は[公式ドキュメント](https://debezium.io/documentation/reference/stable/operations/debezium-server.html)をご覧ください。

ドキュメントを見ると大量のコーディング例(Java)と構成例が載っており、これ全部理解してプログラムを書かないと使えないのかと思ってしまいますが、幸いコンテナイメージとして[公開](https://hub.docker.com/r/debezium/server)されていますので、今回はそれを利用しています。ソースコードも[公開](https://github.com/debezium/debezium-server)されています。

> 明言はされていませんでしたが、グローバルサミット2023のデモは、JavaベースのカスタムアプリケーションサーバからJava APIを使用してDebeziumの機能を使用するスタイルかもしれません

# その他

Debeziumサーバの欠点といいますか特徴として、送信先が未達になると直ぐ落ちるというのがあります。例えばIRISが停止すると、Debeziumサーバのコンテナが停止してしまいます。それらの機能はKafka本体にマネージしてもらう前提になっているためだと思います。ただ、どこまで処理したかをO/Sファイル(本例ではdata/offsets.dat)に保存していますので、IRIS起動後に、Debeziumサーバのコンテナを再開すれば、停止中に発生した更新をキャプチャしてくれます。

> 本例であればコンテナ再開は下記コマンドで行います
> ```
> docker compose up -d debezium-server
> ```

MYSQLもほぼ同じ操作で動作確認が出来ます(./mysqlに必要なファイルがあります。mysql.txtを参照ください)。

また、今回は、SQLを実行しているだけですが、何某かのビジネスロジックを実行したり、インターオペラビリティ機能に連動させたりといった応用も考えられます。

