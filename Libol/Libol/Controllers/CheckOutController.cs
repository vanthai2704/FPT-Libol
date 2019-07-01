using System;
using System.Collections.Generic;
using System.Linq;
using System.Web;
using System.Web.Mvc;
using Libol.Models;
using Libol.EntityResult;
using System.Data;
using System.Data.Entity.Core.Objects;

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
        [HttpPost]
        public PartialViewResult CheckOutSuccess(
            string strFullName,
            string strPatronCode,
            string strFixDueDate,
            int intLoanMode,
            int intHoldIgnore,
            string strCopyNumbers,
            string strCheckOutDate
            )
        {
            CIR_PATRON patron =
                db.CIR_PATRON.Where(a => a.Code == strPatronCode).First();
            ViewBag.groupname = patron.CIR_PATRON_GROUP.Name;
            ViewBag.loanquota = patron.CIR_PATRON_GROUP.LoanQuota;
            ViewBag.ethic = patron.CIR_DIC_ETHNIC.Ethnic;
            ViewBag.educationlevel = patron.CIR_DIC_EDUCATION.EducationLevel;
            ViewBag.faculty = patron.CIR_PATRON_UNIVERSITY.CIR_DIC_FACULTY.Faculty;
            ViewBag.occupation = patron.CIR_DIC_OCCUPATION.Occupation;
            ViewBag.college = patron.CIR_PATRON_UNIVERSITY.CIR_DIC_COLLEGE.College;
            ViewBag.address = patron.CIR_PATRON_OTHER_ADDR.Where(a => a.PatronID == patron.ID).First().Address;
            SP_GET_PATRON_INFOR_Result patroninfo =
                db.SP_GET_PATRON_INFOR("", strPatronCode, strFixDueDate).First();
            ViewData["patroninfo"] = patroninfo;

            db.SP_CHECKOUT(strPatronCode, 43, intLoanMode, strCopyNumbers, "12/31/2019", strCheckOutDate, intHoldIgnore,
               new ObjectParameter("intOutValue", typeof(int)),
                new ObjectParameter("intOutID", typeof(int)));

            List <SP_GET_PATRON_ONLOAN_COPIES_Result> patronloaninfo = db.SP_GET_PATRON_ONLOAN_COPIES(patroninfo.ID).ToList<SP_GET_PATRON_ONLOAN_COPIES_Result>();
            ViewData["patronloaninfo"] = patronloaninfo;
            return PartialView("_checkoutSuccess");
        }

        [HttpPost]
        public PartialViewResult CheckOutCardInfo(string strFullName, string strPatronCode, string strFixDueDate)
        {
            CIR_PATRON patron =
                db.CIR_PATRON.Where(a => a.Code == strPatronCode).First();
            ViewBag.groupname = patron.CIR_PATRON_GROUP.Name;
            ViewBag.loanquota = patron.CIR_PATRON_GROUP.LoanQuota;
            ViewBag.ethic = patron.CIR_DIC_ETHNIC.Ethnic;
            ViewBag.educationlevel = patron.CIR_DIC_EDUCATION.EducationLevel;
            ViewBag.faculty = patron.CIR_PATRON_UNIVERSITY.CIR_DIC_FACULTY.Faculty;
            ViewBag.occupation = patron.CIR_DIC_OCCUPATION.Occupation;
            ViewBag.college = patron.CIR_PATRON_UNIVERSITY.CIR_DIC_COLLEGE.College;
            ViewBag.address = patron.CIR_PATRON_OTHER_ADDR.Where(a => a.PatronID == patron.ID).First().Address;
            SP_GET_PATRON_INFOR_Result patroninfo =
                db.SP_GET_PATRON_INFOR(strFullName, strPatronCode, strFixDueDate).First();
            ViewData["patroninfo"] = patroninfo;
            List<SP_GET_PATRON_ONLOAN_COPIES_Result> patronloaninfo = db.SP_GET_PATRON_ONLOAN_COPIES(patroninfo.ID).ToList<SP_GET_PATRON_ONLOAN_COPIES_Result>();
            ViewData["patronloaninfo"] = patronloaninfo;
            return PartialView("_showPatronInfo");
        }
    }
}