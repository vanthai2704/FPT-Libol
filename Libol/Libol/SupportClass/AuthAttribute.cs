using System;
using System.Collections.Generic;
using System.Linq;
using System.Web;
using System.Web.Mvc;
using System.Web.Mvc.Filters;

namespace Libol.SupportClass
{
    public class AuthAttribute : ActionFilterAttribute, IAuthorizationFilter
    {
        public int ModuleID { get; set; }
        public int RightID { get; set; }        

        public void OnAuthorization(AuthorizationContext filterContext)
        {
            if (string.IsNullOrEmpty(Convert.ToString(filterContext.HttpContext.Session["UserID"])))
            {
                var Url = new UrlHelper(filterContext.RequestContext);
                var url = Url.Action("Index", "Login");
                filterContext.Result = new RedirectResult(url);
            }
            else
            {
                List<Int32> ModuleIDs = (List<Int32>)filterContext.HttpContext.Session["ModuleIDs"];
                List<Int32> RightIDs = (List<Int32>)filterContext.HttpContext.Session["RightIDs"];
                RightIDs.Add(0);
                if (ModuleIDs.Contains(ModuleID) && RightIDs.Contains(RightID))
                {
                    // Do nothing
                }
                else
                {
                    filterContext.Result = new ViewResult() { ViewName = "Permisssion" };
                }
            }
        }

    }
}