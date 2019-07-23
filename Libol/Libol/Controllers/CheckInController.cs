using Libol.EntityResult;
using Libol.Models;
using System;
using System.Collections.Generic;
using System.Data.Entity.Core.Objects;
using System.Linq;
using System.Web;
using System.Web.Mvc;
using Libol.SupportClass;

namespace Libol.Controllers
{
    public class CheckInController : BaseController
    {
        private LibolEntities db = new LibolEntities();
        SearchPatronBusiness searchPatronBusiness = new SearchPatronBusiness();
        FormatHoldingTitle f = new FormatHoldingTitle();
        private static string fullname = "";
        [AuthAttribute(ModuleID = 3, RightID = "58")]
        public ActionResult Index()
        {
            return View();
        }

        [HttpPost]
        public PartialViewResult CheckInByCardNumber(string strFullName, string strPatronCode, string strFixDueDate)
        {
            if (db.GET_BLACK_PATRON_INFOR().Where(a => a.code == strPatronCode).Where(a => a.isLocked == 1).Count() == 0)
            {
                ViewBag.active = 1;
            }
            else
            {
                ViewBag.active = 0;
                ViewBag.blackNote = db.GET_BLACK_PATRON_INFOR().Where(a => a.code == strPatronCode).First().Note;
                ViewBag.blackstartdate = db.CIR_PATRON_LOCK.Where(a => a.PatronCode == strPatronCode).First().StartedDate;
                ViewBag.blackenddate = ViewBag.blackstartdate.AddDays(db.CIR_PATRON_LOCK.Where(a => a.PatronCode == strPatronCode).First().LockedDays);
            }

            getpatrondetail(strPatronCode);
            int id2 = ViewBag.PatronDetail.ID;
            getonloandetail(id2);
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
            db.SP_CHECKIN(43, intType, intAutoPaid, strCopyNumbers, strCheckInDate,
                new ObjectParameter("strTransIDs", typeof(string)),
                new ObjectParameter("strPatronCode", typeof(string)),
                new ObjectParameter("intError", typeof(int)));
            getpatrondetail(strPatronCode);
            int id2 = ViewBag.PatronDetail.ID;
            getonloandetail(id2);
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
            int id2 = ViewBag.PatronDetail.ID;
            getonloandetail(id2);
            return PartialView("_checkinByDKCB");
        }

        [HttpPost]
        public PartialViewResult FindByName(string strFullName)
        {
            if (String.IsNullOrEmpty(strFullName))
            {
                ViewBag.listpatron = new List<FPT_SP_ILL_SEARCH_PATRON_Result>();
            }
            else
            {
                fullname = strFullName;
                ViewBag.listpatron = searchPatronBusiness.FPT_SP_ILL_SEARCH_PATRONs(fullname, "").Where(a => a.DOB != null).ToList();
            }
                
            return PartialView("_findByCardNumber");
        }
        [HttpGet]
        public PartialViewResult FindByCardNumber()
        {
            ViewBag.listpatron = new List<FPT_SP_ILL_SEARCH_PATRON_Result>();
            ViewBag.PatronDetail = null;
            return PartialView("_findByCardNumber");
        }

        public PartialViewResult GetPatronSearchDetail(string code)
        {
            getpatrondetail(code);
            ViewBag.listpatron = searchPatronBusiness.FPT_SP_ILL_SEARCH_PATRONs(fullname, "").Where(a => a.DOB != null).ToList();
            return PartialView("_findByCardNumber");
        }

        public void getpatrondetail(string strPatronCode)
        {
            SP_GET_PATRON_INFOR_Result patroninfo =
               db.SP_GET_PATRON_INFOR("", strPatronCode, DateTime.Now.ToString("MM/dd/yyyy")).First();
            CIR_PATRON patron = db.CIR_PATRON.Where(a => a.Code == strPatronCode).First();
            ViewBag.PatronDetail = new DetailPatron
            {
                ID = patron.ID,
                strCode = patron.Code,
                Name = patron.FirstName + " " + patron.MiddleName + " " + patron.LastName,
                strDOB = Convert.ToDateTime(patron.DOB).ToString("dd/MM/yyyy"),
                strValidDate = Convert.ToDateTime(patroninfo.ValidDate).ToString("dd/MM/yyyy"),
                strExpiredDate = Convert.ToDateTime(patron.ExpiredDate).ToString("dd/MM/yyyy"),
                Sex = patron.Sex == "1" ? "Nam" : "Nữ",
                intEthnicID = db.CIR_DIC_ETHNIC.Where(a => a.ID == patron.EthnicID).Count() == 0 ? "" : db.CIR_DIC_ETHNIC.Where(a => a.ID == patron.EthnicID).First().Ethnic,
                intCollegeID = (patron.CIR_PATRON_UNIVERSITY == null || patron.CIR_PATRON_UNIVERSITY.CIR_DIC_COLLEGE == null) ? "" : patron.CIR_PATRON_UNIVERSITY.CIR_DIC_COLLEGE.College,
                intFacultyID = (patron.CIR_PATRON_UNIVERSITY == null || patron.CIR_PATRON_UNIVERSITY.CIR_DIC_FACULTY == null) ? "" : patron.CIR_PATRON_UNIVERSITY.CIR_DIC_FACULTY.Faculty,
                strEducationlevel = patron.CIR_DIC_EDUCATION == null ? null : patron.CIR_DIC_EDUCATION.EducationLevel,
                strWorkPlace = patroninfo.WorkPlace,
                strGrade = patron.CIR_PATRON_UNIVERSITY == null ? "" : patron.CIR_PATRON_UNIVERSITY.Grade,
                strClass = patron.CIR_PATRON_UNIVERSITY == null ? "" : patron.CIR_PATRON_UNIVERSITY.Class,
                strAddress = patron.CIR_PATRON_OTHER_ADDR.Count == 0 ? "" : patron.CIR_PATRON_OTHER_ADDR.First().Address,
                strTelephone = patron.Telephone,
                strMobile = patron.Mobile,
                strEmail = patron.Email,
                strNote = patron.Note,
                intOccupationID = patron.CIR_DIC_OCCUPATION == null ? "" : patron.CIR_DIC_OCCUPATION.Occupation,
                intPatronGroupID = patron.CIR_PATRON_GROUP == null ? "" : patron.CIR_PATRON_GROUP.Name
            };
        }

        public void getonloandetail(int id)
        {
            List<SP_GET_PATRON_ONLOAN_COPIES_Result> patronloaninfo = db.SP_GET_PATRON_ONLOAN_COPIES(id).ToList<SP_GET_PATRON_ONLOAN_COPIES_Result>();
            List<OnLoan> onLoans = new List<OnLoan>();

            foreach (SP_GET_PATRON_ONLOAN_COPIES_Result a in patronloaninfo)
            {
                onLoans.Add(new OnLoan
                {
                    Title = f.OnFormatHoldingTitle(a.TITLE),
                    Copynumber = a.COPYNUMBER,
                    CheckoutDate = a.CHECKOUTDATE.ToString("dd/MM/yyyy"),
                    DueDate = a.DUEDATE.Value.ToString("dd/MM/yyyy"),
                    Note = a.NOTE
                });
            }
            ViewBag.patronloaninfo = onLoans;
        }
    }
    public class OnLoan
    {
        public string Title { get; set; }
        public string Copynumber { get; set; }
        public string CheckoutDate { get; set; }
        public string DueDate { get; set; }
        public string Note { get; set; }
    }

    public class DetailPatron
    {
        public int ID { get; set; }
        public string strCode { get; set; }
        public string Name { get; set; }
        public string strDOB { get; set; }
        public string strValidDate { get; set; }
        public string strExpiredDate { get; set; }
        public string Sex { get; set; }
        public string intEthnicID { get; set; }
        public string intCollegeID { get; set; }
        public string intFacultyID { get; set; }
        public string strEducationlevel { get; set; }
        public string strWorkPlace { get; set; }
        public string strGrade { get; set; }
        public string strClass { get; set; }
        public string strAddress { get; set; }
        public string strTelephone { get; set; }
        public string strMobile { get; set; }
        public string strEmail { get; set; }
        public string strNote { get; set; }
        public string intOccupationID { get; set; }
        public string intPatronGroupID { get; set; }
    }
}