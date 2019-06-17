using System;
using System.Collections.Generic;
using System.Linq;
using System.Web;
using System.Web.Mvc;
using System.Web.Routing;

namespace Libol.Controllers
{
    public class BaseController : Controller
    {
        protected override void OnActionExecuting(ActionExecutingContext filterContext)
        {
            var session = Session["UserID"];
            string path = Request.RequestContext.HttpContext.Request.RawUrl;
            if (session == null)
            {
                
                if (!filterContext.HttpContext.Request.IsAjaxRequest() || path.Equals("")
                    || path.Equals("/") || path.Equals("/Home"))
                {
                    filterContext.Result = new RedirectToRouteResult(new RouteValueDictionary(new { controller = "Login", action = "Index" }));
                }
                else
                {
                    filterContext.HttpContext.Response.StatusCode = 401;
                    filterContext.HttpContext.Response.End();
                }
                
            }
            base.OnActionExecuting(filterContext);
        }
    }
}