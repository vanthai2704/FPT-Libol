using System;
using System.Collections.Generic;
using System.Linq;
using System.Web;

namespace Libol.Models
{
    public class PatronBusiness
    {
        LibolEntities le = new LibolEntities();

        public List<FPT_SP_STAT_PATRONMAX_Result>
            FPT_SP_STAT_PATRONMAX_LIST(String UserID, String strDateFrom, String strDateTo,
            String NumPat, String HireTimes, String OptItemID, String LocID, String LibID)
        {
            List<FPT_SP_STAT_PATRONMAX_Result> list =
            le.Database.SqlQuery<FPT_SP_STAT_PATRONMAX_Result>(
                "FPT_SP_STAT_PATRONMAX {0},{1},{2},{3},{4},{5},{6},{7}",
                new object[] { UserID, strDateFrom, strDateTo, NumPat, HireTimes, OptItemID, LocID, LibID }
            ).ToList();
            return list;
        }

        public List<PATRON_GROUP>
            PATRON_GROUP_NOW(String UserID, String strDateFrom, String strDateTo, String Type, String strLibID)
        {
            List<PATRON_GROUP> list_now =
                le.Database.SqlQuery<PATRON_GROUP>(
                    "FPT_SP_STAT_PATRONGROUP {0},{1},{2},{3},{4},{5}",
                    new object[] { UserID, strDateFrom, strDateTo, Type, 0, strLibID}
                    ).ToList();
            return list_now;
        }

        public List<PATRON_GROUP>
            PATRON_GROUP_PASS(String UserID, String strDateFrom, String strDateTo, String Type, String strLibID)
        {
            List<PATRON_GROUP> list_pass =
                le.Database.SqlQuery<PATRON_GROUP>(
                    "FPT_SP_STAT_PATRONGROUP {0},{1},{2},{3},{4},{5}",
                    new object[] { UserID, strDateFrom, strDateTo, Type, 1, strLibID }
                    ).ToList();
            return list_pass;
        }

        public List<ITEMMAX>
            TOP_COPY(String UserID, String strDateFrom, String strDateTo, String strNumPatron, String strHireTimes, String strLibID)
        {
            List<ITEMMAX> list =
                le.Database.SqlQuery<ITEMMAX>(
                    "FPT_SP_STAT_ITEMMAX {0},{1},{2},{3},{4},{5}",
                    new object[] { UserID, strDateFrom, strDateTo, strNumPatron, strHireTimes, strLibID }
                    ).ToList();
            return list;
        }

    }
}