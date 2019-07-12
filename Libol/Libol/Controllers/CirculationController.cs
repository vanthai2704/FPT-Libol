﻿using System;
using System.Collections.Generic;
using System.Linq;
using System.Web;
using System.Web.Mvc;
using Libol.Models;
using System.Text.RegularExpressions;

namespace Libol.Controllers
{    
    public class CirculationController : BaseController
    {
        LibolEntities le = new LibolEntities();
        CirculationBusiness cb = new CirculationBusiness();
        PatronBusiness pb = new PatronBusiness();
        int UserID = 49;
        public string GetContent(string copynumber)
        {
            string validate = copynumber.Replace("$a", " ");
            validate = validate.Replace("$b", " ");
            validate = validate.Replace("$c", " ");
            validate = validate.Replace("$n", " ");
            validate = validate.Replace("$p", " ");
            validate = validate.Replace("$e", " ");

            return validate.Trim();
        }
        // GET: Circulation
        public ActionResult Index()
        {
            return View();
        }

        public ActionResult Reports()
        {
            return View();
        }

        public ActionResult ReportOnLoanCopy()
        {
            List<SelectListItem> lib = new List<SelectListItem>
            {
                new SelectListItem { Text = "Hãy chọn thư viện", Value = "" }
            };
            foreach (var l in le.FPT_SP_CIR_LIB_SEL(UserID).ToList())
            {
                lib.Add(new SelectListItem { Text = l.Code, Value = l.ID.ToString() });
            }
            ViewData["lib"] = lib;
            return View();
        }
        public PartialViewResult GetOnLoanStats(string strLibID, string strLocPrefix, string strLocID, string strPatronNumber, string strItemCode, string strDueDateFrom, string strDueDateTo, string strCheckOutDateFrom, string strCheckOutDateTo, string strCopyNumber)
        {
            int LibID = 0;
            int LocID = 0;
            if (!String.IsNullOrEmpty(strLibID)) LibID = Convert.ToInt32(strLibID);
            if (!String.IsNullOrEmpty(strLocPrefix) && !strLocPrefix.Equals("0")) LocID = Convert.ToInt32(strLocID);

            List<GET_PATRON_ONLOANINFOR_Result> result = cb.GET_PATRON_ONLOAN_INFOR_LIST(strPatronNumber, strItemCode, strCopyNumber, LibID, strLocPrefix, LocID, strCheckOutDateFrom, strCheckOutDateTo, strDueDateFrom, strDueDateTo, null, UserID);
            foreach (var item in result)
            {
                item.Content = GetContent(item.Content);
            }
            ViewBag.Result = result;
            //Count number of Patrons
            Dictionary<string, int> PatronCount = new Dictionary<string, int>();
            foreach (var item in result)
            {
                if (!String.IsNullOrEmpty(item.FullName))
                {
                    if (!PatronCount.ContainsKey(item.FullName))
                    {
                        PatronCount.Add(item.FullName, 1);
                    }
                    else
                    {
                        PatronCount[item.FullName] += 1;
                    }
                }
            }
            ViewBag.PatronCount = PatronCount.Count;
            return PartialView("GetOnLoanStats");
        }
        public PartialViewResult GetFilteredOnLoanStats(string strLibID, string strLocPrefix, string strLocID, string strPatronNumber, string strItemCode, string strCheckInDateFrom, string strCheckInDateTo, string strCheckOutDateFrom, string strCheckOutDateTo, string strCopyNumber)
        {
            int LibID = 0;
            int LocID = 0;
            if (!String.IsNullOrEmpty(strLibID)) LibID = Convert.ToInt32(strLibID);
            if (!String.IsNullOrEmpty(strLocPrefix) && !strLocPrefix.Equals("0")) LocID = Convert.ToInt32(strLocID);
            List<GET_PATRON_RENEW_ONLOAN_INFOR_Result> result = cb.GET_PATRON_RENEW_ONLOAN_INFOR_LIST(strPatronNumber, strItemCode, strCopyNumber, LibID, strLocPrefix, LocID, strCheckOutDateFrom, strCheckOutDateTo, strCheckInDateFrom, strCheckInDateTo, UserID);
            foreach (var item in result)
            {
                item.Content = GetContent(item.Content);
            }
            ViewBag.Result = result;
            //Count number of Patrons
            Dictionary<string, int> PatronCount = new Dictionary<string, int>();
            foreach (var item in result)
            {
                if (!String.IsNullOrEmpty(item.FullName))
                {
                    if (!PatronCount.ContainsKey(item.FullName))
                    {
                        PatronCount.Add(item.FullName, 1);
                    }
                    else
                    {
                        PatronCount[item.FullName] += 1;
                    }
                }
            }
            ViewBag.PatronCount = PatronCount.Count;
            return PartialView("GetFilteredOnLoanStats");
        }
        //-------------------END OF ONLOAN REPORT---------------------
        public ActionResult ReportLoanCopy()
        {
            List<SelectListItem> lib = new List<SelectListItem>
            {
                new SelectListItem { Text = "Hãy chọn thư viện", Value = "" }
            };
            foreach (var l in le.FPT_SP_CIR_LIB_SEL(UserID).ToList())
            {
                lib.Add(new SelectListItem { Text = l.Code, Value = l.ID.ToString() });
            }
            ViewData["lib"] = lib;
            return View();
        }

        //GET LOCATIONS PREFIX BY LIBRARY
        public JsonResult GetLocationsPrefix(int id)
        {
            List<SelectListItem> LocPrefix = new List<SelectListItem>();
            LocPrefix.Add(new SelectListItem { Text = "Tất cả", Value = "0" });
            foreach (var lp in le.FPT_CIR_GET_LOCLIBUSER_PREFIX_SEL(UserID, id))
            {
                LocPrefix.Add(new SelectListItem { Text = Regex.Replace(lp.ToString(), @"[^0-9a-zA-Z]+", ""), Value = lp.ToString() });
            }
            return Json(new SelectList(LocPrefix, "Value", "Text"));
        }

        //GET LOCATIONS BY LOCATION PREFIX, LIBRARY, USERID
        public JsonResult GetLocationsByPrefix(int id, string prefix)
        {
            List<SelectListItem> LocByPrefix = new List<SelectListItem>();
            LocByPrefix.Add(new SelectListItem { Text = "Tất cả", Value = "0" });
            foreach (var lbp in le.FPT_CIR_GET_LOCFULLNAME_LIBUSER_SEL(UserID, id, prefix))
            {
                LocByPrefix.Add(new SelectListItem { Text = lbp.Symbol, Value = lbp.ID.ToString() });
            }
            return Json(new SelectList(LocByPrefix, "Value", "Text"));
        }

        [HttpPost]
        public PartialViewResult GetLoanStats(string strLibID, string strLocPrefix, string strLocID, string strPatronNumber, string strItemCode, string strCheckInDateFrom, string strCheckInDateTo, string strCheckOutDateFrom, string strCheckOutDateTo, string strCopyNumber)
        {
            int LibID = 0;
            int LocID = 0;
            if (!String.IsNullOrEmpty(strLibID)) LibID = Convert.ToInt32(strLibID);
            if (!String.IsNullOrEmpty(strLocPrefix) && !strLocPrefix.Equals("0")) LocID = Convert.ToInt32(strLocID);
            List<GET_PATRON_LOANINFOR_Result> result = cb.GET_PATRON_LOAN_INFOR_LIST(strPatronNumber, strItemCode, strCopyNumber, LibID, strLocPrefix, LocID, strCheckOutDateFrom, strCheckOutDateTo, strCheckInDateFrom, strCheckInDateTo, null, UserID);
            foreach (var item in result)
            {
                item.Content = GetContent(item.Content);
            }
            ViewBag.Result = result;
            //Count number of Patrons
            Dictionary<string, int> PatronCount = new Dictionary<string, int>();
            foreach (var item in result)
            {
                if (!String.IsNullOrEmpty(item.FullName))
                {
                    if (!PatronCount.ContainsKey(item.FullName))
                    {
                        PatronCount.Add(item.FullName, 1);
                    }
                    else
                    {
                        PatronCount[item.FullName] += 1;
                    }
                }
            }
            ViewBag.PatronCount = PatronCount.Count;
            return PartialView("GetLoanStats");
        }
        [HttpPost]
        public PartialViewResult GetFilteredLoanStats(string strLibID, string strLocPrefix, string strLocID, string strPatronNumber, string strItemCode, string strCheckInDateFrom, string strCheckInDateTo, string strCheckOutDateFrom, string strCheckOutDateTo, string strCopyNumber)
        {
            int LibID = 0;
            int LocID = 0;
            if (!String.IsNullOrEmpty(strLibID)) LibID = Convert.ToInt32(strLibID);
            if (!String.IsNullOrEmpty(strLocPrefix) && !strLocPrefix.Equals("0")) LocID = Convert.ToInt32(strLocID);
            List<GET_PATRON_RENEW_LOAN_INFOR_Result> result = cb.GET_PATRON_RENEW_LOAN_INFOR_LIST(strPatronNumber, strItemCode, strCopyNumber, LibID, strLocPrefix, LocID, strCheckOutDateFrom, strCheckOutDateTo, strCheckInDateFrom, strCheckInDateTo, UserID);
               
            foreach (var item in result)
            {
                item.Content = GetContent(item.Content);               
                if((item.CheckInDate-item.OverDueDateNew).Days>item.OverdueDays)
                {
                    item.OverdueDays = 0;
                    item.OverdueFine = 0;
                }     

            }
            ViewBag.Result = result;
            //Count number of Patrons
            Dictionary<string, int> PatronCount = new Dictionary<string, int>();
            foreach (var item in result)
            {
                if (!String.IsNullOrEmpty(item.FullName))
                {
                    if (!PatronCount.ContainsKey(item.FullName))
                    {
                        PatronCount.Add(item.FullName, 1);
                    }
                    else
                    {
                        PatronCount[item.FullName] += 1;
                    }
                }
            }
            ViewBag.PatronCount = PatronCount.Count;
            return PartialView("GetFilteredLoanStats");
        }
        //-------------------END OF LOAN HISTORY REPORT---------------------
        public ActionResult StatisticAnnual()
        {
            List<SelectListItem> lib = new List<SelectListItem>
            {
                new SelectListItem { Text = "Hãy chọn thư viện", Value = "" }
            };
            foreach (var l in le.FPT_SP_CIR_LIB_SEL(UserID).ToList())
            {
                lib.Add(new SelectListItem { Text = l.Code, Value = l.ID.ToString() });
            }
            ViewData["lib"] = lib;
            return View();
        }
        public ActionResult StatisticYear()
        {
            List<SelectListItem> lib = new List<SelectListItem>
            {
                new SelectListItem { Text = "Hãy chọn thư viện", Value = "" }
            };
            foreach (var l in le.FPT_SP_CIR_LIB_SEL(UserID).ToList())
            {
                lib.Add(new SelectListItem { Text = l.Code, Value = l.ID.ToString() });
            }
            ViewData["lib"] = lib;
            return View();
        }
        //GET LOCATIONS BY LIBRARY
        public JsonResult GetLocations(int id)
        {
            List<SelectListItem> loc = new List<SelectListItem>();
            loc.Add(new SelectListItem { Text = "Tất cả các kho", Value = "0" });
            foreach (var l in le.FPT_SP_CIR_LIBLOCUSER_SEL(UserID, id).ToList())
            {
                loc.Add(new SelectListItem { Text = l.Symbol, Value = l.ID.ToString() });
            }
            return Json(new SelectList(loc, "Value", "Text"));
        }
        [HttpPost]
        public PartialViewResult GetYearStats(string strLibID, string strLocID, string strFromYear, string strToYear, string strType)
        {
            int LibID = 0;
            int LocID = 0;
            int Type = 0;
            if (!String.IsNullOrEmpty(strLibID)) LibID = Convert.ToInt32(strLibID);
            if (!String.IsNullOrEmpty(strLocID)) LocID = Convert.ToInt32(strLocID);
            if (!String.IsNullOrEmpty(strType)) Type = Convert.ToInt32(strType);            
            if (Type == 3)
            {
                ViewBag.TypeName = "bạn đọc";
            }
            else if (Type == 2)
            {
                ViewBag.TypeName = "bản ấn phẩm";
            }
            else if (Type == 1)
            {
                ViewBag.TypeName = "đầu ấn phẩm";
            }
            ViewBag.UsedResult = cb.GET_FPT_CIR_YEAR_STATISTIC_LIST(LibID, LocID, Type, 0, strFromYear, strToYear, UserID);
            ViewBag.UsingResult = cb.GET_FPT_CIR_YEAR_STATISTIC_LIST(LibID, LocID, Type, 1, strFromYear, strToYear, UserID);
            return PartialView("GetYearStats");
        }
        [HttpPost]
        public PartialViewResult GetMonthStats(string strLibID, string strLocID, string strInYear, string strType)
        {
            int LibID = 0;
            int LocID = 0;
            int Type = 0;
            if (!String.IsNullOrEmpty(strLibID)) LibID = Convert.ToInt32(strLibID);
            if (!String.IsNullOrEmpty(strLocID)) LocID = Convert.ToInt32(strLocID);
            if (!String.IsNullOrEmpty(strType)) Type = Convert.ToInt32(strType);
            if (Type == 3)
            {
                ViewBag.TypeName = "bạn đọc";
            }
            else if (Type == 2)
            {
                ViewBag.TypeName = "bản ấn phẩm";
            }
            else if (Type == 1)
            {
                ViewBag.TypeName = "đầu ấn phẩm";
            }
            ViewBag.UsedResult = cb.GET_FPT_CIR_MONTH_STATISTIC_LIST(LibID, LocID, Type, 0, strInYear, UserID);
            ViewBag.UsingResult = cb.GET_FPT_CIR_MONTH_STATISTIC_LIST(LibID, LocID, Type, 1, strInYear, UserID);
            return PartialView("GetMonthStats");
        }
        public ActionResult StatisticMonth()
        {
            List<SelectListItem> lib = new List<SelectListItem>
            {
                new SelectListItem { Text = "Hãy chọn thư viện", Value = "" }
            };
            foreach (var l in le.FPT_SP_CIR_LIB_SEL(UserID).ToList())
            {
                lib.Add(new SelectListItem { Text = l.Code, Value = l.ID.ToString() });
            }
            ViewData["lib"] = lib;
            return View();
        }

        public ActionResult LockPatronStats()
        {
            //FPT_CIR_GET_LOCKEDPATRONS(PatronCode, LockDateTo, LockDateFrom, LibraryID, UserID)
            //ViewBag.Result = cb.GET_SP_GET_LOCKEDPATRONS_LIST(null, null, null);
            return View();
        }

        public PartialViewResult GetLockPatronStats(string strPatronCode, string strLockDateTo, string strLockDateFrom)
        {
            ViewBag.Result = cb.GET_SP_GET_LOCKEDPATRONS_LIST(strPatronCode, strLockDateFrom, strLockDateTo);
            return PartialView("GetLockPatronStats");
        }

        public ActionResult StatisticPatronGroup()
        {
            List<SelectListItem> lib = new List<SelectListItem>
            {
                new SelectListItem { Text = "Chọn thư viện", Value = "" }
            };
            foreach (var item in le.SP_HOLDING_LIB_SEL(UserID).ToList())
            {
                lib.Add(new SelectListItem { Text = item.Code, Value = item.ID.ToString() });
            }
            ViewBag.list_lib = lib;
            return View();
        }
        [HttpPost]
        public PartialViewResult DisplayPatronGroup(String strLibID, String strDateFrom, String strDateTo, String strType)
        {
            string userID = "UserID";
            List<PATRON_GROUP> result_now =
                pb.PATRON_GROUP_NOW(userID, strDateFrom, strDateTo, strType, strLibID);

            List<PATRON_GROUP> result_pass =
                pb.PATRON_GROUP_PASS(userID, strDateFrom, strDateTo, strType, strLibID);

            ViewBag.rnow = result_now;

            ViewBag.rpass = result_pass;

            return PartialView("DisplayPatronGroup");
        }
        public ActionResult StatisticTopPatron()
        {
            List<SelectListItem> lib = new List<SelectListItem>
            {
                new SelectListItem { Text = "Hãy chọn thư viện", Value = "" }
            };
            foreach (var item in le.SP_HOLDING_LIB_SEL(UserID).ToList())
            {
                lib.Add(new SelectListItem { Text = item.Code, Value = item.ID.ToString() });
            }
            ViewBag.list_lib = lib;
            return View();
        }
        [HttpPost]
        public PartialViewResult DisplayTopPatron(String strLibID, String strLocID, String strDateFrom, String strDateTo,
            String strNumPatron, String strHireTimes, String strType)
        {
            string userID = "UserID";

            List<FPT_SP_STAT_PATRONMAX_Result> result =
                pb.FPT_SP_STAT_PATRONMAX_LIST(userID, strDateFrom, strDateTo, strNumPatron, strHireTimes, strType, strLocID, strLibID);

            ViewBag.test = result;
            return PartialView("DisplayTopPatron");
        }
        public ActionResult StatisticTopCopy()
        {
            List<SelectListItem> lib = new List<SelectListItem>
            {
                new SelectListItem { Text = "Hãy chọn thư viện", Value = "" }
            };
            foreach (var item in le.SP_HOLDING_LIB_SEL(UserID).ToList())
            {
                lib.Add(new SelectListItem { Text = item.Code, Value = item.ID.ToString() });
            }
            ViewBag.list_lib = lib;
            return View();
        }
        [HttpPost]
        public PartialViewResult DisplayTopCopy(String strLibID, String strDateFrom, String strDateTo,
        String strNumPatron, String strHireTimes)
        {
            string userID = "UserID";

            List<ITEMMAX> result =
                pb.TOP_COPY(userID, strDateFrom, strDateTo, strNumPatron, strHireTimes, strLibID);

            ViewBag.test = result;
            return PartialView("DisplayTopCopy");
        }

        public JsonResult GetLocationsDemo(int id)
        {
            List<SelectListItem> loc = new List<SelectListItem>();
            loc.Add(new SelectListItem { Text = "Tất cả các kho", Value = "0" });
            foreach (var l in le.SP_HOLDING_LIBLOCUSER_SEL(UserID, id).ToList())
            {
                loc.Add(new SelectListItem { Text = l.Symbol, Value = l.ID.ToString() });
            }
            return Json(new SelectList(loc, "Value", "Text"));
        }
        public ActionResult DemoDataTableEport()
        {
            ViewBag.ParentNodes = le.SP_HOLDING_LIB_SEL(UserID).ToList();
            //le.SP_HOLDING_LIBLOCUSER_SEL(UserID, id).ToList();
            return View();
        }
    }
}