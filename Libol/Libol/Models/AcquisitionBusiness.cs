using System;
using System.Collections.Generic;
using System.Linq;
using System.Web;

namespace Libol.Models
{
    public class AcquisitionBusiness
    {
        LibolEntities db = new LibolEntities();
        public List<FPT_GET_LIQUIDBOOKS_Result> FPT_GET_LIQUIDBOOKS_LIST(string LiquidCode, int LibID, int LocID, string DateFrom, string DateTo, int UserID)
        {
            List<FPT_GET_LIQUIDBOOKS_Result> list = db.Database.SqlQuery<FPT_GET_LIQUIDBOOKS_Result>("FPT_GET_LIQUIDBOOKS {0}, {1}, {2}, {3}, {4}, {5}",
                new object[] { LiquidCode, LibID, LocID, DateFrom, DateTo, UserID }).ToList();
            return list;
        }
        public List<FPT_ACQ_YEAR_STATISTIC_Result> FPT_ACQ_YEAR_STATISTIC_LIST(int LibID, int LocID, string FromYear, string ToYear, int UserID)
        {
            List<FPT_ACQ_YEAR_STATISTIC_Result> list = db.Database.SqlQuery<FPT_ACQ_YEAR_STATISTIC_Result>("FPT_ACQ_YEAR_STATISTIC {0}, {1}, {2}, {3}, {4}",
                new object[] { LibID, LocID, FromYear, ToYear, UserID }).ToList();
            return list;
        }
        public List<FPT_ACQ_MONTH_STATISTIC_Result> FPT_ACQ_MONTH_STATISTIC_LIST(int LibID, int LocID, string InYear, int UserID)
        {
            List<FPT_ACQ_MONTH_STATISTIC_Result> list = db.Database.SqlQuery<FPT_ACQ_MONTH_STATISTIC_Result>("FPT_ACQ_MONTH_STATISTIC {0}, {1}, {2}, {3}",
                new object[] { LibID, LocID, InYear, UserID }).ToList();
            return list;
        }
    }
}