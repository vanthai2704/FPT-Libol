using System;
using System.Collections.Generic;
using System.Linq;
using System.Web;

namespace Libol.EntityResult
{
    public class SP_CIR_OVERDUELIST_GETINFOR_Result
    {
        //trinhlv1
        public int LOANID { get; set; }
        public int LibID { get; set; }
        public int LocID { get; set; }
        //can null
        public string College { get; set; }
        //can null
        public string Faculty { get; set; }
        //can null
        public string Grade { get; set; }
        //can null
        public string Class { get; set; }
        //can null
        public Nullable<int> FacultyID { get; set; }
        public int CollegeID { get; set; }
        public int PatronGroupID { get; set; }
        //can null
        public Nullable<int> LocationID { get; set; }
        public System.DateTime CheckOutDate { get; set; }
        public Nullable<System.DateTime> CheckInDate { get; set; }
        public string MainTitle { get; set; }
        public string CopyNumber { get; set; }
        public int PatronID { get; set; }
        public string Name { get; set; }
        public string Email { get; set; }
        public int OverdueDate { get; set; }
        public long Penati { get; set; }
        public string PatronCode { get; set; }
        public string Code { get; set; }
        public string ItemCode { get; set; }
        public string LibCode { get; set; }
        public string LocCode { get; set; }

    }
}