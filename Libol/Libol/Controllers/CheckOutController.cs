using System;
using System.Collections.Generic;
using System.Linq;
using System.Web;
using System.Web.Mvc;
using Libol.Models;
using Libol.EntityResult;
using System.Data;

namespace Libol.Controllers
{
    public class CheckOutController : Controller
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

        [HttpPost]
        public PartialViewResult CheckOutCardInfo(string strFullName, string strPatronCode, string strFixDueDate)
        {
            SP_GET_PATRON_INFOR_Result patroninfo =
                db.SP_GET_PATRON_INFOR(strFullName, strPatronCode, strFixDueDate).First();
            ViewData["patroninfo"] = patroninfo;

            List<SP_GET_PATRON_ONLOAN_COPIES_Result> patronloaninfo = db.SP_GET_PATRON_ONLOAN_COPIES(patroninfo.ID).ToList<SP_GET_PATRON_ONLOAN_COPIES_Result>();
            ViewData["patronloaninfo"] = patronloaninfo;
            return PartialView("_showPatronInfo");
        }
    }
}