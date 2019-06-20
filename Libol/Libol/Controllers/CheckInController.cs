using Libol.Models;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Web;
using System.Web.Mvc;

namespace Libol.Controllers
{
    public class CheckInController : BaseController
    {
        private LibolEntities db = new LibolEntities();

        // GET: CheckIn
        public ActionResult Index()
        {
            return View();
        }

        [HttpPost]
        public PartialViewResult CheckInByCardNumber(string strFullName, string strPatronCode, string strFixDueDate)
        {
            SP_GET_PATRON_INFOR_Result patroninfo =
                db.SP_GET_PATRON_INFOR(strFullName, strPatronCode, strFixDueDate).First();
            ViewData["patroninfo"] = patroninfo;

            List<SP_GET_PATRON_ONLOAN_COPIES_Result> patronloaninfo = db.SP_GET_PATRON_ONLOAN_COPIES(patroninfo.ID).ToList<SP_GET_PATRON_ONLOAN_COPIES_Result>();
            ViewData["patronloaninfo"] = patronloaninfo;
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