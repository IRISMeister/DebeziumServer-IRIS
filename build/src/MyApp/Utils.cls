Class MyApp.Utils [ Abstract ]
{

/// App level initialization if any
ClassMethod Init() As %Status
{
	Set tSC=..runSQL()
	Return $$$OK
}

ClassMethod runSQL(ByRef tVars) As %Status
{
  Set rs=##class(%ResultSet).%New("%File:FileSet") 
  Do rs.Execute("/home/irisowner/sql","*.sql")
  While(rs.Next()) { 
    Do $SYSTEM.SQL.Schema.ImportDDL(rs.Name,"/home/irisowner/import_Errors.log")
  }
  Return $$$OK
}

ClassMethod Export() As %Status
{
  Set file=##class(%File).%New("/home/irisowner/share/bench.csv") Do file.Open("WSN")
  Do file.WriteLine("seq,ts,ts2")
  Set stmt=##class(%SQL.Statement).%New()
  Set tSC=stmt.%Prepare("SELECT pkey,ts,ts2 from inventory.bench")
  Set rs=stmt.%Execute()
  While(rs.%Next()) { 
    Do file.WriteLine(rs.pkey_","_rs.ts_","_rs.ts2)
  }
  Return $$$OK
}

}
