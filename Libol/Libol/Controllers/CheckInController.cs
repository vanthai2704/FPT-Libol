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

        [HttpGet]
        public PartialViewResult FindByCardNumber()
        {
            return PartialView("_findByCardNumber");
        }
    }
}