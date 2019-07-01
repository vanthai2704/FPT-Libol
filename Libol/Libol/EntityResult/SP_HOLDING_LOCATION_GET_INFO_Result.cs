using Libol.Models;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Web;

namespace Libol.EntityResult
{
    public class SP_HOLDING_LOCATION_GET_INFO_Result
    {
        public SP_HOLDING_LOCATION_GET_INFO_Result()
        {

        }
        public int ID { get; set; }
        public Nullable<int> LibID { get; set; }
        public string Symbol { get; set; }
        public bool Status { get; set; }
        public Nullable<int> MaxNumber { get; set; }
        public string CodeLoc { get; set; }
        public string CodeSymbol { get; set; }


    }
}