#!/bin/bash
docker compose up -d iris mysql
docker compose exec -T iris bash -c "\$ISC_PACKAGE_INSTALLDIR/dev/Cloud/ICM/waitISC.sh '' 60"

# mysqlの初期化が完了するまで待つ。もっと他に堅牢な方法ありそう？
sleep 10
docker compose up -d debezium-server
