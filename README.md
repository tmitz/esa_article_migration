# esa_article_migration
esa.ioでチーム間の記事のマイグレーション（雑です）

# SYNOPSIS

```
require './migration.rb'

m = Esa::Migration.new(from: "old-team", to: "new-team")
m.migration_posts(q: "category:サービス/サービス名")
```
