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
            getpatrondetail(strPatronCode);

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
            getpatrondetail(strPatronCode);
            List<SP_GET_PATRON_ONLOAN_COPIES_Result> patronloaninfo = db.SP_GET_PATRON_ONLOAN_COPIES(patroninfo.ID).ToList<SP_GET_PATRON_ONLOAN_COPIES_Result>();
            ViewData["patronloaninfo"] = patronloaninfo;
            return PartialView("_checkinByDKCB");
        }

        [HttpPost]
        public PartialViewResult CheckInByDKCBs(
           string strFullName,
           string strPatronCode,
           string strFixDueDate,
           int intType,
           int intAutoPaid,
           string[] strCopyNumbers,
           string strCheckInDate
       )
        {
            SP_GET_PATRON_INFOR_Result patroninfo =
               db.SP_GET_PATRON_INFOR(strFullName, strPatronCode, strFixDueDate).First();
            ViewData["patroninfo"] = patroninfo;
            foreach (string CopyNumber in strCopyNumbers)
            {
                db.SP_CHECKIN(43, intType, intAutoPaid, CopyNumber, strCheckInDate,
                new ObjectParameter("strTransIDs", typeof(string)),
                new ObjectParameter("strPatronCode", typeof(string)),
                new ObjectParameter("intError", typeof(int)));
            }
            
            getpatrondetail(strPatronCode);
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

        public void getpatrondetail(string strPatronCode)
        {
            CIR_PATRON patron =
                db.CIR_PATRON.Where(a => a.Code == strPatronCode).First();
            ViewBag.groupname = patron.CIR_PATRON_GROUP.Name;
            ViewBag.loanquota = patron.CIR_PATRON_GROUP.LoanQuota;
            ViewBag.ethic = patron.CIR_DIC_ETHNIC == null ? null : patron.CIR_DIC_ETHNIC.Ethnic;
            ViewBag.educationlevel = patron.CIR_DIC_EDUCATION == null ? null : patron.CIR_DIC_EDUCATION.EducationLevel;
            try
            {
                ViewBag.faculty = patron.CIR_PATRON_UNIVERSITY.CIR_DIC_FACULTY.Faculty;
            }
            catch (Exception)
            {
                ViewBag.faculty = null;
            }
            try
            {
                ViewBag.college = patron.CIR_PATRON_UNIVERSITY.CIR_DIC_COLLEGE.College;
            }
            catch (Exception)
            {
                ViewBag.college = null;
            }
            ViewBag.occupation = patron.CIR_DIC_OCCUPATION == null ? null : patron.CIR_DIC_OCCUPATION.Occupation;
            ViewBag.address = patron.CIR_PATRON_OTHER_ADDR.Where(a => a.PatronID == patron.ID).Count() == 0 ? null : patron.CIR_PATRON_OTHER_ADDR.Where(a => a.PatronID == patron.ID).First().Address;
        }
    }
}