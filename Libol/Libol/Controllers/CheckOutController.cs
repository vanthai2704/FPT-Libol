using System;
using System.Collections.Generic;
using System.Linq;
using System.Web;
using System.Web.Mvc;

namespace Libol.Controllers
{
    public class CheckOutController : Controller
    {
        // GET: CheckOut
        public ActionResult Index()
        {
            return View();
        }

        // GET: CheckOutByCard
        public ActionResult CheckOutByCard()
        {
            return View();
        }

        // GET: CheckOutByDKCB
        public ActionResult CheckOutByDKCB()
        {
            return View();
        }

        // GET: FindByCardNumber
        public ActionResult FindByCardNumber()
        {
            return View();
        }
    }
}