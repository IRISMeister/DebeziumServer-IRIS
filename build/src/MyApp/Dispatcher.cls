Class MyApp.Dispatcher Extends %CSP.REST
{

Parameter CONVERTINPUTSTREAM = 1;

XData UrlMap [ XMLNamespace = "http://www.intersystems.com/urlmap" ]
{
<Routes>
<Route Url="/post" Method="POST" Call='Post' Cors="true" />
</Routes>
}

ClassMethod Post() As %Status
{
#DEFINE DEBUGLOG 1

    Try {
        Set %response.ContentType="application/json"
        Set %response.CharSet=%request.CharSet

        If %request.Content="" { 
            // anything to do?
            return $$$OK
        }

        ; parse incoming json
        Set json={}.%FromJSON(%request.Content)
        Set op=json.payload.op // operation c:Create (INSERT), u:Update (UPDATE), d:Delete (DELETE), r:Read 

#ifdef DEBUGLOG
        Set id=$INCREMENT(^RestLog)
#endif
        #; op=""なら何もせず終了
        if op="" { 
#ifdef DEBUGLOG
            Set ^RestLog(id)=json.%ToJSON() 
#endif
            Quit 
        }

        Set connector=json.payload.source.connector
        Set source=json.payload.source
        Set table=source.table
        Set before=json.payload.before
        Set after=json.payload.after

#ifdef DEBUGLOG
        Set ^RestLog(id,"connector")=connector
        Set ^RestLog(id,"op")=op
        Set ^RestLog(id,"tbl")=table
        If $ISOBJECT(after) { Set ^RestLog(id,"a")=after.%ToJSON() }
        If $ISOBJECT(before) { Set ^RestLog(id,"b")=before.%ToJSON() }
#endif

        If table="orders" {
            if (op="c")!(op="u")!(op="r") {
                #; デモで使用しているMYSQL用とPOSTGRES用のサンプルDB上のカラム名がOrdersだけは一部異なったため必要になった例外的な処理。
                #; ソーステーブルの情報がそのまま伝わるので、カラム名の差異などがあればここで吸収する。
                Set id=after.id
                If connector="mysql" { Set id=after."order_number" }

                #; convert epoch time into $H format
                set orderdate=$ZDH($SYSTEM.SQL.Functions.DATEADD("day",after."order_date","1970-01-01"),3)

                &SQL(INSERT OR UPDATE inventory.orders (id,order_date,purchaser,quantity,product_id) values (:id,:orderdate,:after.purchaser,:after.quantity,:after."product_id"))
                If SQLCODE { throw ##class(%Exception.SQL).CreateFromSQLCODE(SQLCODE,%msg) }
            }
            ElseIf (op="d") {
                #; デモで使用しているMYSQL用とPOSTGRES用のサンプルDB上のカラム名がOrdersだけは一部異なったため必要になった例外的な処理。
                Set id=before.id
                If connector="mysql" { Set id=before."order_number" }
                &SQL(DELETE FROM inventory.orders WHERE id=:id)
                If SQLCODE { throw ##class(%Exception.SQL).CreateFromSQLCODE(SQLCODE,%msg) }
            }
        }
        ElseIf table="products" {
            if (op="c")!(op="u")!(op="r") {
                &SQL(INSERT OR UPDATE inventory.products (id, name, description, weight) values (:after.id,:after.name,:after.description,:after.weight))
                If SQLCODE { throw ##class(%Exception.SQL).CreateFromSQLCODE(SQLCODE,%msg) }
            }
        }
        ElseIf table="customers" {
            if (op="c")!(op="u")!(op="r") {
                &SQL(INSERT OR UPDATE inventory.customers (id, first_name, last_name, email) values (:after.id,:after."first_name",:after."last_name",:after.email))
                If SQLCODE { throw ##class(%Exception.SQL).CreateFromSQLCODE(SQLCODE,%msg) }
            }
        }
        Else {
            #; unhandled tables. Ignore.
            Set ^LOG($INCREMENT(^LOG))=$LISTBUILD($ZDATETIME($H),table)
        }
    }
    Catch(e) {
        Do e.Log()
        zw e
    }

    return $$$OK
}

}
