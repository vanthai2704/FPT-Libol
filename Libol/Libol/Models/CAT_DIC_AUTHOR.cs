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
    
    public partial class CAT_DIC_AUTHOR
    {
        [System.Diagnostics.CodeAnalysis.SuppressMessage("Microsoft.Usage", "CA2214:DoNotCallOverridableMethodsInConstructors")]
        public CAT_DIC_AUTHOR()
        {
            this.ITEM_AUTHOR = new HashSet<ITEM_AUTHOR>();
        }
    
        public int ID { get; set; }
        public string DisplayEntry { get; set; }
        public string AccessEntry { get; set; }
        public Nullable<int> DicItemID { get; set; }
    
        [System.Diagnostics.CodeAnalysis.SuppressMessage("Microsoft.Usage", "CA2227:CollectionPropertiesShouldBeReadOnly")]
        public virtual ICollection<ITEM_AUTHOR> ITEM_AUTHOR { get; set; }
    }
}
