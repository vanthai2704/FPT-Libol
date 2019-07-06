﻿using System;
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
        CheckOutBusiness checkOutBusiness = new CheckOutBusiness();
        private static string strTransactionIDs = "";
        private static string patroncode = "0";

        // GET: CheckOut
        public ActionResult Index()
        {
            return View();
        }

        // GET: Giahan
        public ActionResult Giahan()
        {
            patroncode = "0";
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
            ViewBag.ethic = patron.CIR_DIC_ETHNIC == null ? null : patron.CIR_DIC_ETHNIC.Ethnic;
            ViewBag.educationlevel = patron.CIR_DIC_EDUCATION == null ? null : patron.CIR_DIC_EDUCATION.EducationLevel;
            ViewBag.occupation = patron.CIR_DIC_OCCUPATION == null ? null : patron.CIR_DIC_OCCUPATION.Occupation;
            ViewBag.address = patron.CIR_PATRON_OTHER_ADDR.Where(a => a.PatronID == patron.ID).Count() == 0 ? null : patron.CIR_PATRON_OTHER_ADDR.Where(a => a.PatronID == patron.ID).First().Address;
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
            SP_GET_PATRON_INFOR_Result patroninfo =
                db.SP_GET_PATRON_INFOR("", strPatronCode, strFixDueDate).First();
            ViewData["patroninfo"] = patroninfo;

            int success= db.SP_CHECKOUT(strPatronCode, 43, intLoanMode, strCopyNumbers, "12/31/2019", strCheckOutDate, intHoldIgnore,
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
                strTransactionIDs = "0";
            }
            ViewBag.currentloaninfo = checkOutBusiness.SP_GET_CURRENT_LOANINFORs(strTransactionIDs, "Loan").ToList();
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

            SP_GET_PATRON_INFOR_Result patroninfo =
                db.SP_GET_PATRON_INFOR(strFullName, strPatronCode, strFixDueDate).First();
            ViewData["patroninfo"] = patroninfo;
            List<SP_GET_PATRON_ONLOAN_COPIES_Result> patronloaninfo = db.SP_GET_PATRON_ONLOAN_COPIES(patroninfo.ID).ToList<SP_GET_PATRON_ONLOAN_COPIES_Result>();
            ViewData["patronloaninfo"] = patronloaninfo;
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
            ViewBag.currentloaninfo = checkOutBusiness.SP_GET_CURRENT_LOANINFORs(strTransactionIDs, "Loan").ToList();
            SP_GET_PATRON_INFOR_Result patroninfo =
               db.SP_GET_PATRON_INFOR("", patroncode, DateTime.Now.ToString("dd/MM/yyyy")).First();
            ViewData["patroninfo"] = patroninfo;
            getpatrondetail(patroncode);
            return PartialView("_checkoutSuccess");
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