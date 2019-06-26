using System;
using System.Collections.Generic;
using System.Linq;
using System.Web;

namespace Libol.EntityResult
{
    public class SP_ILL_SEARCH_PATRON_Result
    {
        public SP_ILL_SEARCH_PATRON_Result()
        {

        }
        public int ID { get; set; }
        public string Code { get; set; }
        public string FullName { get; set; }
        public int GroupId { get; set; }

    }


}