import java.sql.Connection;
import java.sql.DriverManager;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.sql.Statement;

public class TestDriver {
        static Connection conn = null;
        static Statement stmt = null;
        static ResultSet rset = null;

        static String url = "jdbc:postgresql://localhost:5432/postgres";
        static String user = "postgres";
        static String password = "postgres";
        static String sql = "";
        static String sql2= "";

    public static void main(String[] args) {
        int cnt=100000;
        prep(cnt);
    }

    public static void prep(int cnt) {
        try{
            conn = DriverManager.getConnection(url, user, password);

            conn.setAutoCommit(true);

            stmt = conn.createStatement();
            sql = "CREATE TABLE inventory.bench (pkey INTEGER Primary Key, ts TIMESTAMP, ts2 TIMESTAMP)";
            sql2 = "ALTER TABLE inventory.bench  REPLICA IDENTITY DEFAULT" ;
            try {
                stmt.executeUpdate(sql);
                stmt.executeUpdate(sql2);
            }
            catch (SQLException e) {
            }

            sql = "INSERT INTO inventory.bench (pkey,ts,ts2) VALUES (?,now(),now())";
            PreparedStatement pstmt = conn.prepareStatement(sql);
            for (int i=0; i<cnt; i++) {
                pstmt.setInt(1, i);
                pstmt.executeUpdate();
            }

            sql = "SELECT count(*) from inventory.bench";
            rset = stmt.executeQuery(sql);

            while(rset.next()){
                String col = rset.getString(1);
                System.out.println(col);
            }

            sql = "DELETE from inventory.bench";
            stmt.executeUpdate(sql);

            System.out.println("hit any key to continue.");
            System.in.read();

            pstmt.clearParameters();
            for (int i=0; i<cnt; i++) {
                pstmt.setInt(1, i);
                pstmt.executeUpdate();
            }

            sql = "SELECT count(*) from inventory.bench";
            rset = stmt.executeQuery(sql);

            while(rset.next()){
                String col = rset.getString(1);
                System.out.println(col);
            }

        }
        catch (Exception e){
            e.printStackTrace();
        }
        finally {
            try {
                if(rset != null)rset.close();
                if(stmt != null)stmt.close();
                if(conn != null)conn.close();
            }
            catch (SQLException e){
                e.printStackTrace();
            }

        }
    }

}
