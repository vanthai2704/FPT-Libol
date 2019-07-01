using Libol.EntityResult;
using Libol.Models;
using System;
using System.Collections.Generic;
using System.Data.Entity.Core.Objects;
using System.Linq;
using System.Web;
using System.Web.Mvc;

namespace Libol.Controllers
{
    public class CheckInController : BaseController
    {
        private LibolEntities db = new LibolEntities();
        SearchPatronBusiness searchPatronBusiness = new SearchPatronBusiness();
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

        [HttpPost]
        public PartialViewResult CheckInByDKCB(
            string strFullName,
            string strPatronCode,
            string strFixDueDate,
            int intType,
            int intAutoPaid,
            string strCopyNumbers,
            string strCheckInDate
        )
        {
            SP_GET_PATRON_INFOR_Result patroninfo =
               db.SP_GET_PATRON_INFOR(strFullName, strPatronCode, strFixDueDate).First();
            ViewData["patroninfo"] = patroninfo;
            db.SP_CHECKIN(43, intType, intAutoPaid, strCopyNumbers, strCheckInDate,
                new ObjectParameter("strTransIDs", typeof(string)),
                new ObjectParameter("strPatronCode", typeof(string)),
                new ObjectParameter("intError", typeof(int)));

            List<SP_GET_PATRON_ONLOAN_COPIES_Result> patronloaninfo = db.SP_GET_PATRON_ONLOAN_COPIES(patroninfo.ID).ToList<SP_GET_PATRON_ONLOAN_COPIES_Result>();
            ViewData["patronloaninfo"] = patronloaninfo;
            return PartialView("_checkinByDKCB");
        }

        [HttpPost]
        public PartialViewResult FindByCardNumber(string strFullName)
        {

            ViewBag.listpatron = searchPatronBusiness.FPT_SP_ILL_SEARCH_PATRONs(strFullName, "").ToList().Take(50).ToList();
            return PartialView("_findByCardNumber");
        }
    }
}