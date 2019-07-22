using System;
using System.Collections.Generic;
using System.Linq;
using System.Web;

namespace Libol.SupportClass
{
    public class FormatHoldingTitle
    {
        public string OnFormatHoldingTitle(string title)
        {
            string validate = title.Replace("$a", "");
            validate = validate.Replace("$b", "");
            validate = validate.Replace("$c", "");
            validate = validate.Replace("=$b", "");
            validate = validate.Replace(":$b", "");
            validate = validate.Replace("/$c", "");
            validate = validate.Replace(".$n", "");
            validate = validate.Replace(":$p", "");
            validate = validate.Replace(";$c", "");
            validate = validate.Replace("+$e", "");
            return validate;
        }
    }
}