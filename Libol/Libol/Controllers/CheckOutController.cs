using System;
using System.Collections.Generic;
using System.Linq;
using System.Web;
using System.Web.Mvc;
using Libol.Models;

namespace Libol.Controllers
{
    public class CheckOutController : BaseController
    {

        private LibolEntities db = new LibolEntities();

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
            //var data = db.
                return PartialView("_showPatronInfo");
        }
    }
}