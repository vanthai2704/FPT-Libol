using Libol.Models;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Web;

namespace Libol.EntityResult
{
    public class SP_HOLDING_LIBRARY_SELECT_Result
    {
        public SP_HOLDING_LIBRARY_SELECT_Result()
        {

        }

        public int ID { get; set; }
        public string Name { get; set; }
        public string Code { get; set; }
        public bool LocalLib { get; set; }
        public string Address { get; set; }
        public string AccessEntry { get; set; }
        public string FullName { get; set; }

    }
}