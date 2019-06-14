using System;
using System.Collections.Generic;
using System.Linq;
using System.Web;
using System.Web.Mvc;

namespace Libol.Controllers
{
    public class CheckInController : BaseController
    {
        // GET: CheckIn
        public ActionResult Index()
        {
            return View();
        }

        [HttpGet]
        public PartialViewResult CheckInByCardNumber()
        {
            return PartialView("_checkinByCardNumber");
        }

        [HttpGet]
        public PartialViewResult CheckInByDKCB()
        {
            return PartialView("_checkinByDKCB");
        }

        [HttpGet]
        public PartialViewResult FindByCardNumber()
        {
            return PartialView("_findByCardNumber");
        }
    }
}