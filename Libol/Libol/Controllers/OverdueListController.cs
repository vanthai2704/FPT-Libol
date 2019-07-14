using System;
using System.Collections.Generic;
using System.Linq;
using System.Web;
using System.Web.Mvc;

namespace Libol.Controllers
{
    public class OverdueListController : Controller
    {
        // GET: OverdueList
        public ActionResult OverdueList()
        {
            return View();
        }
    }
}