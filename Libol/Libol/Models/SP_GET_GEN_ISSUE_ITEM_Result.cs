//------------------------------------------------------------------------------
// <auto-generated>
//     This code was generated from a template.
//
//     Manual changes to this file may cause unexpected behavior in your application.
//     Manual changes to this file will be overwritten if the code is regenerated.
// </auto-generated>
//------------------------------------------------------------------------------

namespace Libol.Models
{
    using System;
    
    public partial class SP_GET_GEN_ISSUE_ITEM_Result
    {
        public int ItemID { get; set; }
        public Nullable<int> TotalCopies { get; set; }
        public Nullable<int> TotalIssues { get; set; }
        public string TITLE { get; set; }
        public string ISSN { get; set; }
        public string FreqCode { get; set; }
        public Nullable<System.DateTime> BasedDate { get; set; }
        public Nullable<bool> Ceased { get; set; }
        public string SummaryHolding { get; set; }
        public string ChangeNote { get; set; }
        public int OnSubscription { get; set; }
        public Nullable<int> AcqSourceID { get; set; }
        public Nullable<int> POID { get; set; }
    }
}
