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

}
