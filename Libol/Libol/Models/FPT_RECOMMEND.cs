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
    using System.Collections.Generic;
    
    public partial class FPT_RECOMMEND
    {
        public int POID { get; set; }
        public string ReID { get; set; }
    
        public virtual ACQ_PO ACQ_PO { get; set; }
    }
}