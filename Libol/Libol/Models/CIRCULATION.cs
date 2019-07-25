
//namespace Libol.Models
//{
//    using System;
//    using System.Data.Entity;
//    using System.Data.Entity.Infrastructure;
//    using System.Data.Entity.Core.Objects;
//    using System.Collections.Generic;

//    public partial class CirculationEntities : DbContext
//    {
//        public CirculationEntities()
//            : base("name=CirculationEntities")
//        {
//        }
//        public List<GET_PATRON_LOANINFOR_Result> CIR_GET_PATRON_LOAN_INFOR_LIST(string PatronCode, string ItemCode, string CopyNumber, int LocationID, string CheckOutDateFrom, string CheckOutDateTo, string CheckInDateFrom, string CheckInDateTo, string Serial, int UserID)
//        {
//            List<GET_PATRON_LOANINFOR_Result> list = this.Database.SqlQuery<GET_PATRON_LOANINFOR_Result>("GET_PATRON_LOANINFOR {0}, {1}, {2}, {3}, {4}, {5}, {6}, {7}, {8}, {9}",
//                new object[] { PatronCode, ItemCode, CopyNumber, LocationID, CheckOutDateFrom, CheckOutDateTo, CheckInDateFrom, CheckInDateTo, Serial, UserID }).ToListAsync();
//            return list;
//        }
//    }
//}