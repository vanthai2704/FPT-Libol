using System;
using System.Collections.Generic;
using System.Linq;
using System.Web;
using System.Web.Mvc;

namespace Libol.Controllers
{
    public class CheckOutController : BaseController
    {
        // GET: CheckOut
        public ActionResult Index()
        {
            return View();
        }
        
        // GET: Giahan
        public ActionResult Giahan()
        {
            return View();
        }

        // GET: CheckOutSuccess
        public PartialViewResult CheckOutSuccess()
        {
            return PartialView("_checkoutSuccess");
        }

        [HttpGet]
        public PartialViewResult CheckOutCardInfo()
        {
            return PartialView("_showPatronInfo");
        }
    }
}