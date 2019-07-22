using System;
using System.Collections.Generic;
using System.Linq;
using System.Web;
using System.Web.Mvc;
using Libol.Models;
using Libol.EntityResult;
using System.Data;
using System.Data.Entity.Core.Objects;
using Libol.SupportClass;

namespace Libol.Controllers
{
    public class CheckOutController : BaseController
    {
        private LibolEntities db = new LibolEntities();
        CheckOutBusiness checkOutBusiness = new CheckOutBusiness();
        SearchPatronBusiness searchPatronBusiness = new SearchPatronBusiness();
        private static string strTransactionIDs = "";
        private static string patroncode = "0";
        FormatHoldingTitle f = new FormatHoldingTitle();

        // GET: CheckOut
        public ActionResult Index()
        {
            patroncode = "0";
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
            getpatrondetail(strPatronCode);
            int success= db.SP_CHECKOUT(strPatronCode, 43, intLoanMode, strCopyNumbers, strFixDueDate, strCheckOutDate, intHoldIgnore,
               new ObjectParameter("intOutValue", typeof(int)),
                new ObjectParameter("intOutID", typeof(int)));
            string lastid = db.CIR_LOAN.Max(a => a.ID).ToString();
            if (success == 3)
            {
                if (patroncode == strPatronCode)
                {
                    strTransactionIDs = strTransactionIDs + "," + lastid;
                }
                else
                {
                    strTransactionIDs = lastid;
                }
            }
            else
            {
                if (patroncode != strPatronCode)
                {
                    strTransactionIDs = "0";
                }
            }
            getcurrentloandetail();
            patroncode = strPatronCode;
            return PartialView("_checkoutSuccess");
        }

        [HttpPost]
        public PartialViewResult CheckOutCardInfo(string strFullName, string strPatronCode, string strFixDueDate)
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
            int id = ViewBag.PatronDetail.ID;
            getonloandetail(id);
            return PartialView("_showPatronInfo");
        }

        //thu hoi 1 an pham
        public PartialViewResult Rollbackacheckout (string strCopyNumbers)
        {
            db.SP_CHECKIN(43, 1, 0, strCopyNumbers, DateTime.Now.ToString("dd/MM/yyyy"),
               new ObjectParameter("strTransIDs", typeof(string)),
               new ObjectParameter("strPatronCode", typeof(string)),
               new ObjectParameter("intError", typeof(int)));

            strTransactionIDs = strTransactionIDs.Replace(","+ strCopyNumbers, "");
            getcurrentloandetail();
            getpatrondetail(patroncode);
            return PartialView("_checkoutSuccess");
        }

        [HttpPost]
        public PartialViewResult FindByName(string strFullName)
        {
            ViewBag.listpatron = searchPatronBusiness.FPT_SP_ILL_SEARCH_PATRONs(strFullName, "").ToList().Take(50).ToList();
            return PartialView("_findByCardNumber");
        }
        [HttpGet]
        public PartialViewResult FindByCardNumber()
        {
            ViewBag.listpatron = searchPatronBusiness.FPT_SP_ILL_SEARCH_PATRONs("", "").ToList().Take(0).ToList();
            return PartialView("_findByCardNumber");
        }

        public void getpatrondetail(string strPatronCode)
        {
            SP_GET_PATRON_INFOR_Result patroninfo =
               db.SP_GET_PATRON_INFOR("", strPatronCode, DateTime.Now.ToString("MM/dd/yyyy")).First();
            CIR_PATRON patron = db.CIR_PATRON.Where(a => a.Code == strPatronCode).First();
            ViewBag.PatronDetail = new CustomPatron
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

        public void getcurrentloandetail()
        {
            List<SP_GET_CURRENT_LOANINFOR_Result> currentloaninfo = checkOutBusiness.SP_GET_CURRENT_LOANINFORs(strTransactionIDs, "Loan").ToList();
            List<OnLoan> onLoans = new List<OnLoan>();

            foreach (SP_GET_CURRENT_LOANINFOR_Result a in currentloaninfo)
            {
                onLoans.Add(new OnLoan
                {
                    Title = f.OnFormatHoldingTitle(a.Title),
                    Copynumber = a.CopyNumber,
                    CheckoutDate = a.CheckOutDate.ToString("dd/MM/yyyy"),
                    DueDate = a.DueDate.ToString("dd/MM/yyyy"),
                    Note = a.Note
                });
            }
            ViewBag.currentloaninfo = onLoans;
        }

        public class CustomPatron
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

        public class OnLoan
        {
            public string Title { get; set; }
            public string Copynumber { get; set; }
            public string CheckoutDate { get; set; }
            public string DueDate { get; set; }
            public string Note { get; set; }
        }

    }
}