using Libol.SupportClass;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Web;
using System.Web.Mvc;

namespace Libol.Controllers
{
    public class AcquiredController : Controller
    {
        [AuthAttribute(ModuleID = 4, RightID = "0")]
        public ActionResult Index()
        {
            return View();
        }
    }
}