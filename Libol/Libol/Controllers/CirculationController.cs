using System;
using System.Collections.Generic;
using System.Linq;
using System.Web;
using System.Web.Mvc;
using Libol.Models;
using System.Text.RegularExpressions;
using Libol.SupportClass;

namespace Libol.Controllers
{
    public class CirculationController : Controller
    {
        LibolEntities le = new LibolEntities();
        CirculationBusiness cb = new CirculationBusiness();
        PatronBusiness pb = new PatronBusiness();
        //int UserID = 49;
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
        [AuthAttribute(ModuleID = 3, RightID = "67")]
        public ActionResult Index()
        {
            return View();
        }

        public ActionResult Reports()
        {
            return View();
        }

        [AuthAttribute(ModuleID = 3, RightID = "67")]
        public ActionResult ReportOnLoanCopy()
        {
            List<SelectListItem> lib = new List<SelectListItem>
            {
                new SelectListItem { Text = "Hãy chọn thư viện", Value = "" }
            };
            foreach (var l in le.FPT_SP_CIR_LIB_SEL((int)Session["UserID"]).ToList())
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

            List<GET_PATRON_ONLOANINFOR_Result> result = cb.GET_PATRON_ONLOAN_INFOR_LIST(strPatronNumber, strItemCode, strCopyNumber, LibID, strLocPrefix, LocID, strCheckOutDateFrom, strCheckOutDateTo, strDueDateFrom, strDueDateTo, null, (int)Session["UserID"]);
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
            List<GET_PATRON_RENEW_ONLOAN_INFOR_Result> result = cb.GET_PATRON_RENEW_ONLOAN_INFOR_LIST(strPatronNumber, strItemCode, strCopyNumber, LibID, strLocPrefix, LocID, strCheckOutDateFrom, strCheckOutDateTo, strCheckInDateFrom, strCheckInDateTo, (int)Session["UserID"]);
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
        [AuthAttribute(ModuleID = 3, RightID = "67")]
        public ActionResult ReportLoanCopy()
        {
            List<SelectListItem> lib = new List<SelectListItem>
            {
                new SelectListItem { Text = "Hãy chọn thư viện", Value = "" }
            };
            foreach (var l in le.FPT_SP_CIR_LIB_SEL((int)Session["UserID"]).ToList())
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
            foreach (var lp in le.FPT_CIR_GET_LOCLIBUSER_PREFIX_SEL((int)Session["UserID"], id))
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
            foreach (var lbp in le.FPT_CIR_GET_LOCFULLNAME_LIBUSER_SEL((int)Session["UserID"], id, prefix))
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
            List<GET_PATRON_LOANINFOR_Result> result = cb.GET_PATRON_LOAN_INFOR_LIST(strPatronNumber, strItemCode, strCopyNumber, LibID, strLocPrefix, LocID, strCheckOutDateFrom, strCheckOutDateTo, strCheckInDateFrom, strCheckInDateTo, null, (int)Session["UserID"]);
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
            List<GET_PATRON_RENEW_LOAN_INFOR_Result> result = cb.GET_PATRON_RENEW_LOAN_INFOR_LIST(strPatronNumber, strItemCode, strCopyNumber, LibID, strLocPrefix, LocID, strCheckOutDateFrom, strCheckOutDateTo, strCheckInDateFrom, strCheckInDateTo, (int)Session["UserID"]);

            foreach (var item in result)
            {
                item.Content = GetContent(item.Content);
                if ((item.CheckInDate - item.OverDueDateNew).Days > item.OverdueDays)
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
            foreach (var l in le.FPT_SP_CIR_LIB_SEL((int)Session["UserID"]).ToList())
            {
                lib.Add(new SelectListItem { Text = l.Code, Value = l.ID.ToString() });
            }
            ViewData["lib"] = lib;
            return View();
        }
        [AuthAttribute(ModuleID = 3, RightID = "67")]
        public ActionResult StatisticYear()
        {
            List<SelectListItem> lib = new List<SelectListItem>
            {
                new SelectListItem { Text = "Hãy chọn thư viện", Value = "" }
            };
            foreach (var l in le.FPT_SP_CIR_LIB_SEL((int)Session["UserID"]).ToList())
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
            foreach (var l in le.FPT_SP_CIR_LIBLOCUSER_SEL((int)Session["UserID"], id).ToList())
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
            ViewBag.UsedResult = cb.GET_FPT_CIR_YEAR_STATISTIC_LIST(LibID, LocID, Type, 0, strFromYear, strToYear, (int)Session["UserID"]);
            ViewBag.UsingResult = cb.GET_FPT_CIR_YEAR_STATISTIC_LIST(LibID, LocID, Type, 1, strFromYear, strToYear, (int)Session["UserID"]);
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
            ViewBag.UsedResult = cb.GET_FPT_CIR_MONTH_STATISTIC_LIST(LibID, LocID, Type, 0, strInYear, (int)Session["UserID"]);
            ViewBag.UsingResult = cb.GET_FPT_CIR_MONTH_STATISTIC_LIST(LibID, LocID, Type, 1, strInYear, (int)Session["UserID"]);
            return PartialView("GetMonthStats");
        }
        [AuthAttribute(ModuleID = 3, RightID = "67")]
        public ActionResult StatisticMonth()
        {
            List<SelectListItem> lib = new List<SelectListItem>
            {
                new SelectListItem { Text = "Hãy chọn thư viện", Value = "" }
            };
            foreach (var l in le.FPT_SP_CIR_LIB_SEL((int)Session["UserID"]).ToList())
            {
                lib.Add(new SelectListItem { Text = l.Code, Value = l.ID.ToString() });
            }
            ViewData["lib"] = lib;
            return View();
        }

        [AuthAttribute(ModuleID = 3, RightID = "72")]
        public ActionResult LockPatronStats()
        {
            List<SelectListItem> lib = new List<SelectListItem>
            {
                new SelectListItem { Text = "Hãy chọn thư viện", Value = "" }
            };
            foreach (var l in le.HOLDING_LIBRARY.ToList())
            {
                lib.Add(new SelectListItem { Text = l.Code, Value = l.ID.ToString() });
            }
            ViewData["lib"] = lib;
            //FPT_CIR_GET_LOCKEDPATRONS(PatronCode, LockDateTo, LockDateFrom, LibraryID, UserID)
            //ViewBag.Result = cb.GET_SP_GET_LOCKEDPATRONS_LIST(null, null, null);
            string LibraryFilter = Request.Form["LibraryFilter"];
            if (!string.IsNullOrEmpty(LibraryFilter))
            {
                ViewBag.iddd = Int32.Parse(LibraryFilter);

            }
            else
            {
                ViewBag.iddd = -1;
            }
            string PatronCodeFilter = Request.Form["PatronCodeFilter"];
            string LockDateFromFilter = Request.Form["LockDateFromFilter"];
            string LockDateToFilter = Request.Form["LockDateToFilter"];
            int CollegeID = 0;
            if (!String.IsNullOrEmpty(LibraryFilter)) CollegeID = Convert.ToInt32(LibraryFilter);
            ViewBag.Result = cb.GET_SP_GET_LOCKEDPATRONS_LIST(PatronCodeFilter, LockDateFromFilter, LockDateToFilter, CollegeID);
            ShelfBusiness shelfBusiness = new ShelfBusiness();
            ViewBag.Library = shelfBusiness.FPT_SP_HOLDING_LIBRARY_SELECT(0, 1, -1, Int32.Parse(Session["UserID"].ToString()), 1);
            return View(ViewBag.iddd);
        }
        // LockCard()
        [HttpPost]
        public JsonResult LockCardPatron(string cardNumber,string startDate,int lockDays, string note)
        {
            List<SP_LOCK_PATRON_CARD_Result> listResult = cb.GET_SP_LOCK_PATRON_CARD_LIST(cardNumber, lockDays, startDate, note);
            ViewData["listResult"] = listResult;
            return Json(listResult, JsonRequestBehavior.AllowGet);

        }
        // Edit LockCard()
        [HttpPost]
        public JsonResult UpdatedLockCardPatron(string patronCode, int lockDays, string note)
        {
            List<FPT_SP_UPDATE_UNLOCK_PATRON_CARD_Result> listResult = cb.FPT_SP_UPDATE_UNLOCK_PATRON_CARD(patronCode, lockDays, note);
            ViewData["listResult"] = listResult;
            return Json(listResult, JsonRequestBehavior.AllowGet);

        }
        // UnLockCard()
        [HttpPost]
        public JsonResult UnLockCardPatron(List<string> patroncodeList)
        {
            try
            {
                foreach (var item in patroncodeList)
                {
                    cb.FPT_SP_UNLOCK_PATRON_CARD_LIST("'" + item+ "'"); ;
                }
            }
            catch (Exception)
            {
                throw;
            }
            return Json(new { Message = "Mở Khóa thành công!" }, JsonRequestBehavior.AllowGet);

        }

        public PartialViewResult GetLockPatronStats(string strPatronCode, string strLockDateTo, string strLockDateFrom, string strCollegeID)
        {
            int CollegeID = 0;
            if (!String.IsNullOrEmpty(strCollegeID)) CollegeID = Convert.ToInt32(strCollegeID);
            ViewBag.Result = cb.GET_SP_GET_LOCKEDPATRONS_LIST(strPatronCode, strLockDateFrom, strLockDateTo, CollegeID);
            List<SelectListItem> lib = new List<SelectListItem>
            {
                new SelectListItem { Text = "Hãy chọn thư viện", Value = "" }
            };
            foreach (var l in le.HOLDING_LIBRARY.ToList())
            {
                lib.Add(new SelectListItem { Text = l.Code, Value = l.ID.ToString() });
            }
            ViewData["lib"] = lib;
            return PartialView("GetLockPatronStats");
        }

        [AuthAttribute(ModuleID = 3, RightID = "67")]
        public ActionResult StatisticPatronGroup()
        {
            List<SelectListItem> lib = new List<SelectListItem>
            {
                new SelectListItem { Text = "Chọn thư viện", Value = "" }
            };
            foreach (var item in le.SP_HOLDING_LIB_SEL((int)Session["UserID"]).ToList())
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
        [AuthAttribute(ModuleID = 3, RightID = "67")]
        public ActionResult StatisticTopPatron()
        {
            List<SelectListItem> lib = new List<SelectListItem>
            {
                new SelectListItem { Text = "Hãy chọn thư viện", Value = "" }
            };
            foreach (var item in le.SP_HOLDING_LIB_SEL((int)Session["UserID"]).ToList())
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
        [AuthAttribute(ModuleID = 3, RightID = "67")]
        public ActionResult StatisticTopCopy()
        {
            List<SelectListItem> lib = new List<SelectListItem>
            {
                new SelectListItem { Text = "Hãy chọn thư viện", Value = "" }
            };
            foreach (var item in le.SP_HOLDING_LIB_SEL((int)Session["UserID"]).ToList())
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
            foreach (var l in le.SP_HOLDING_LIBLOCUSER_SEL((int)Session["UserID"], id).ToList())
            {
                loc.Add(new SelectListItem { Text = l.Symbol, Value = l.ID.ToString() });
            }
            return Json(new SelectList(loc, "Value", "Text"));
        }
        public ActionResult DemoDataTableEport()
        {
            ViewBag.ParentNodes = le.SP_HOLDING_LIB_SEL((int)Session["UserID"]).ToList();
            //le.SP_HOLDING_LIBLOCUSER_SEL(UserID, id).ToList();
            return View();
        }
        // get list lock patron in datatable
        [HttpPost]
        public JsonResult GetLockPatron(DataTableAjaxPostModel model ,int libraryID, string PatronCode,string Note,string StartedDate,string FinishDate)
        {
            var lockedpatron = cb.GET_SP_GET_LOCKEDPATRONS_LIST(PatronCode, "", "", 0);
            var search = lockedpatron.Where(a => true);
            if(libraryID != -1)
            {
                List<String> listInLib = le.CIR_PATRON.Where(c => c.CIR_PATRON_GROUP == null ? false : c.CIR_PATRON_GROUP.HOLDING_LOCATION.Select(l => l.LibID).Contains(libraryID)).Select(c => c.Code).ToList();
                search = lockedpatron.Where(a => listInLib.Contains(a.PatronCode));
            }
            if (!String.IsNullOrEmpty(Note))
            {
                search = search.Where(a => a.Note.Contains(Note));
            }
            if (!String.IsNullOrEmpty(StartedDate))
            {
                search = search.Where(a => a.StartedDate.ToString("yyyy-MM-dd").CompareTo(StartedDate) >= 0);
            }
            if (!String.IsNullOrEmpty(FinishDate))
            {
                search = search.Where(a => a.FinishDate.ToString("yyyy-MM-dd").CompareTo(FinishDate)<=0);
            }
            var paging = search.Skip(model.start).Take(model.length).ToList();
            var result = paging.ToList();
            List<SP_GET_LOCKEDPATRONS_Result2> list = new List<SP_GET_LOCKEDPATRONS_Result2>();
            foreach (var i in result)
            {
                list.Add(new SP_GET_LOCKEDPATRONS_Result2()
                {
                    PatronCode = i.PatronCode,
                    StartedDate = i.StartedDate.ToString("dd/MM/yyyy"),
                    Note = i.Note,
                    FullName = i.FullName,
                    FinishDate = i.FinishDate.ToString("dd/MM/yyyy"),
                    LockedDays = i.LockedDays

                });
            }

            return Json(new
            {
                draw = model.draw,
                recordsTotal = lockedpatron.Count(),
                recordsFiltered = search.Count(),
                data = list
            });
        }

    }
}