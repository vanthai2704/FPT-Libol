using Libol.EntityResult;
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

        // STATISTIC BOOKIN
        public List<FPT_SP_GET_ITEM_Result> FPT_SP_GET_ITEM_LIST(string DateFrom, string DateTo, int LocID, int LibID)
        {
            List<FPT_SP_GET_ITEM_Result> list = db.Database.SqlQuery<FPT_SP_GET_ITEM_Result>("FPT_SP_GET_ITEM {0}, {1}, {2}, {3}",
                new object[] { DateFrom, DateTo, LocID, LibID }).ToList();
            return list;
        }
        public List<FPT_COUNT_COPYNUMBER_BY_ITEMID_Result> FPT_COUNT_COPYNUMBER_BY_ITEMID_LIST(int ItemID, int LocID, int LibID)
        {
            List<FPT_COUNT_COPYNUMBER_BY_ITEMID_Result> list = db.Database.SqlQuery<FPT_COUNT_COPYNUMBER_BY_ITEMID_Result>("FPT_COUNT_COPYNUMBER_BY_ITEMID {0}, {1}, {2}",
                new object[] { ItemID, LocID, LibID }).ToList();
            return list;
        }

        public List<SP_GET_ITEM_INFOR_Result> SP_GET_ITEM_INFOR_LIST(int ItemID)
        {
            List<SP_GET_ITEM_INFOR_Result> list = db.Database.SqlQuery<SP_GET_ITEM_INFOR_Result>("SP_GET_ITEM_INFOR {0}",
                new object[] { ItemID }).ToList();
            return list;
        }

        public List<FPT_COUNT_COPYNUMBER_ONLOAN_Result> FPT_COUNT_COPYNUMBER_ONLOAN_LIST(int ItemID, int LocID, int LibID)
        {
            List<FPT_COUNT_COPYNUMBER_ONLOAN_Result> list = db.Database.SqlQuery<FPT_COUNT_COPYNUMBER_ONLOAN_Result>("FPT_COUNT_COPYNUMBER_ONLOAN {0}, {1}, {2}",
                new object[] { ItemID, LocID, LibID }).ToList();
            return list;
        }

        //list liquid copynumber
        public List<FPT_SP_GET_ITEM_INFOR_Result> FPT_SP_GET_ITEM_INFOR_LIST(int ItemID, int LocID, int LibID)
        {
            List<FPT_SP_GET_ITEM_INFOR_Result> list = db.Database.SqlQuery<FPT_SP_GET_ITEM_INFOR_Result>("FPT_SP_GET_ITEM_INFOR {0}, {1}, {2}",
                new object[] { ItemID, LocID, LibID }).ToList();
            return list;
        }

        // Inventory
        public List<FPT_SP_GET_GENERAL_LOC_INFOR_DUCNV_Result> FPT_SP_GET_GENERAL_LOC_INFOR_DUCNV_LIST(int LibID, int LocID, string strShelf, int intMode)
        {
            List<FPT_SP_GET_GENERAL_LOC_INFOR_DUCNV_Result> list = db.Database.SqlQuery<FPT_SP_GET_GENERAL_LOC_INFOR_DUCNV_Result>("FPT_SP_GET_GENERAL_LOC_INFOR_DUCNV {0}, {1}, {2}, {3}",
                new object[] { LibID, LocID, strShelf, intMode }).ToList();
            return list;
        }

    }
}