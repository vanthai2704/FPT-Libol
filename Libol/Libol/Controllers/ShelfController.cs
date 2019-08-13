﻿using System;
using System.Collections.Generic;
using System.Data.SqlClient;
using System.Linq;
using System.Web;
using System.Web.Mvc;
using Libol.EntityResult;
using Libol.Models;
using Libol.SupportClass;
using OfficeOpenXml;
using OfficeOpenXml.Table;
using System.Data;
using System.Data.Entity.Core.Objects;
using System.IO;
using System.Text.RegularExpressions;


namespace Libol.Controllers
{
    public class ShelfController : Controller
    {
        LibolEntities db = new LibolEntities();
        ShelfBusiness shelfBusiness = new ShelfBusiness();
        List<Library> libs = new List<Library>();
        List<LibraryLocation> lic_locs = new List<LibraryLocation>();
        List<FPT_SP_GET_GENERAL_LOC_INFOR_DUCNV_Result> general_loc = null;

        [AuthAttribute(ModuleID = 4, RightID = "26")]
        public ActionResult Index()
        {

            //get list marc form
            ViewData["ListNBS"] = db.ACQ_ACQUIRE_SOURCE.OrderBy(d => d.ID).ToList();
            //Cấp thư mục
            ViewData["listKTL"] = db.CIR_LOAN_TYPE.ToList();
            ViewData["ListCurrency"] = db.ACQ_CURRENCY.OrderBy(d => d.CurrencyCode).ToList();
            ViewData["ListDeleteReason"] = db.SP_HOLDING_REMOVE_REASON_SEL(0).ToList();

            List<SP_HOLDING_LIBRARY_SELECT_Result> listLibsResult = shelfBusiness.FPT_SP_HOLDING_LIBRARY_SELECT(0, 1, -1, (int)Session["UserID"], 1);
            List<HOLDING_LIBRARY> libs = SP_HOLDING_LIBRARY_SELECT_Result.ConvertToHoldingLibrary(listLibsResult);
            ViewData["listLibs"] = libs;


            string code = Request.QueryString["Code"];


            if (!string.IsNullOrEmpty(code))
            {
                var item = db.ITEMs.Where(i => i.Code.Equals(code)).FirstOrDefault();
                if (item == null)
                {
                    ViewBag.AlertMessage = "Mã tài liệu không tồn tại";
                    return View();
                }
                ViewBag.content = getContentShelf(code);
                int itemID = item.ID;
                ViewBag.itemID = itemID;
            }

            return View();

        }

        [HttpPost]
        public JsonResult SelectHolding(int libID)
        {
            List<SP_HOLDING_LOCATION_GET_INFO_Result> listLocsResult = shelfBusiness.FPT_SP_HOLDING_LOCATION_GET_INFO(libID, (int)Session["UserID"], 0, -1);
            List<HOLDING_LOCATION> locs = SP_HOLDING_LOCATION_GET_INFO_Result.ConvertToHoldingLocation(listLocsResult);
            ViewData["listLocs"] = locs;
            return Json(locs, JsonRequestBehavior.AllowGet);
        }
        public string getContentShelf(string idMTL)
        {

            List<FPT_EDU_GET_SHELF_CONTENT_Result> listContentResult = db.FPT_EDU_GET_SHELF_CONTENT(idMTL).ToList();
            string contentOutput = "";
            string fieldCode = "";
            string field020 = "";
            string field022 = "";
            string field100 = "";
            string field110 = "";
            string field245 = "";
            string field250 = "";
            string field260 = "";
            string field300 = "";
            string field490 = "";
            string field520 = "";
            foreach (FPT_EDU_GET_SHELF_CONTENT_Result item in listContentResult)
            {
                
                fieldCode = item.FieldCode;
                if (fieldCode.Equals("020"))
                {
                    field020 = ". -" + shelfBusiness.GetContent(item.Content);
                }
                if (fieldCode.Equals("022"))
                {
                    field022 = "=" + shelfBusiness.GetContent(item.Content);
                }
                if (fieldCode.Equals("100"))
                {
                    field100 = shelfBusiness.GetContent(item.Content);
                }
                if (fieldCode.Equals("110"))
                {
                    field110 = shelfBusiness.GetContent(item.Content);
                }
                if (fieldCode.Equals("245"))
                {
                    field245 = item.Content;
                    if (field245.Contains("$a"))
                    {
                        field245 = field245.Replace("$a", ". -");
                    }
                    if (field245.Contains("$b"))
                    {
                        field245 = field245.Replace("$b", " ");
                    }
                    if (field245.Contains("$c"))
                    {  
                        field245 = field245.Replace("$c", " ");
                    }
                    if (field245.Contains("$n"))
                    {
                        field245 = field245.Replace("$n", " ");
                    }
                    if (field245.Contains("$p"))
                    {
                        field245 = field245.Replace("$p", " ");
                    }
                }
                if (fieldCode.Equals("250"))
                {
                    field250 = ". -" + shelfBusiness.GetContent(item.Content);
                }
                if (fieldCode.Equals("260"))
                {
                    field260 = item.Content;
                    if (field260.Contains("$a"))
                    {
                        field260 = field260.Replace("$a", ". -");
                    }
                    if (field260.Contains("$b"))
                    {
                        field260 = field260.Replace("$b", " ");
                    }
                    if (field260.Contains("$c"))
                    {
                        field260 = field260.Replace("$c", " ");
                    }
                }
                if (fieldCode.Equals("300"))
                {
                    field300 = item.Content;
                    if (field300.Contains("$a"))
                    {
                        field300 = field300.Replace("$a", ". -");
                    }
                    if (field300.Contains("$b"))
                    {
                        field300 = field300.Replace("$b", " ");
                    }
                    if (field300.Contains("$c"))
                    {
                        field300 = field300.Replace("$c", " ");
                    }
                    if (field300.Contains("$e"))
                    {
                        field300 = field300.Replace("$e", " ");
                    }
                }
                if (fieldCode.Equals("490"))
                {
                    field490 = ". -" + shelfBusiness.GetContent(item.Content);
                }
                if (fieldCode.Equals("520"))
                {
                    field520 = shelfBusiness.GetContent(item.Content);
                }
                contentOutput = field022  + field100 + field110  +"@"+ field245 + "@" + field250  + field260 + field300  + field490  + "@" + field520  + field020;
            }
            return contentOutput;
        }



        [HttpPost]
        public JsonResult GenCopyNumber(int locId)
        {
            string copyNumber = shelfBusiness.GenCopyNumber(locId);
            return Json(new Result()
            {
                Data = copyNumber
            }, JsonRequestBehavior.AllowGet);
        }

        [HttpPost]
        public JsonResult InsertHolding(HOLDING holding, int numberOfCN,string recommendID)
        {
            string composite = "";
            string message = shelfBusiness.InsertHolding(holding, numberOfCN,recommendID,ref composite);
            return Json(new { Message = message, Composite = composite }, JsonRequestBehavior.AllowGet);
        }

        [HttpPost]
        public JsonResult UpdateHolding(HoldingTable holdingUpdate)
        {
            string message = shelfBusiness.UpdateHolding(holdingUpdate);
            return Json(new { Message = message }, JsonRequestBehavior.AllowGet);
        }

        [HttpPost]
        public JsonResult DeleteHolding(int[] CopynumberList,int DeleteReasonID)
        {

            if (CopynumberList == null || CopynumberList.Length <= 0)
            {
                return Json(new { Message = "Hãy chọn bản ghi" }, JsonRequestBehavior.AllowGet);
            }
            string holdingIDs = string.Join(",", CopynumberList);
            int result = db.SP_HOLDING_REMOVED_PROC(DeleteReasonID, holdingIDs);
            return Json(new { Message = "Xóa thành công" }, JsonRequestBehavior.AllowGet);
        }

        [HttpPost]
        public JsonResult ChangeStatus(List<HoldingStatus> statusList)
        {
            try
            {
                foreach (var item in statusList)
                {
                    db.SP_PROCESS_HOLDING("" + item.HoldingID, item.LibID, item.LocID, item.Shelf, item.Mode, item.IsNew);
                }
            }
            catch (Exception)
            {
                throw;
            }
            return Json(new { Message = "Kiểm nhận và mở khóa thành công!" }, JsonRequestBehavior.AllowGet);
        }

        [HttpPost]
        public JsonResult LoadTableHolding(string code)
        {
            string message ="";

            var draw = Request.Form.GetValues("draw").FirstOrDefault();
            var start = Request.Form.GetValues("start").FirstOrDefault();
            var length = Request.Form.GetValues("length").FirstOrDefault();

            var sortColumnInt = Request.Form.GetValues("order[0][column]");

            var sortColumn = Request.Form.GetValues("columns[" + Request.Form.GetValues("order[0][column]").FirstOrDefault() + "][name]").FirstOrDefault();
            var sortColumnDir = Request.Form.GetValues("order[0][dir]").FirstOrDefault();
            var searchValue = Request.Form.GetValues("search[value]").FirstOrDefault();


            //Paging Size (10,20,50,100)    
            int pageSize = length != null ? Convert.ToInt32(length) : 0;
            int skip = start != null ? Convert.ToInt32(start) : 0;
            int RecordsTotal = 0;
            // Getting all holding data    
            var item = db.ITEMs.Where(i => i.Code.Equals(code)).FirstOrDefault();
            int itemID = 0;
            if (item != null)
            {
                itemID = db.ITEMs.Where(i => i.Code.Equals(code)).Select(i => i.ID).FirstOrDefault();
            }
            else
            {
                message = "Mã tài liệu không tồn tại";
                return Json(new { draw = draw, recordsFiltered = 0, recordsTotal = 0, numberOfFreeCopies = 0,data= new HoldingTable(), compositeHolding = 0, numberRecord = 0, Message = message });
            }
            


            var holdings = new List<HOLDING>();
            holdings = db.HOLDINGs.Where(h => h.ItemID == itemID).OrderBy(h => h.ID).ToList();

            // thông tin tổng hợp về mã tài liệu
            int numberFreeCopies = holdings.Where(h => h.InUsed == false).Count();
            string compositeHoldingData = shelfBusiness.GenerateCompositeHoldings(itemID);
            if (Convert.ToInt32(draw) > 1)
            {
                compositeHoldingData = "";
            }
            
            int numberOfRecord = holdings.Count(); 

            //Sorting    
            if (!string.IsNullOrEmpty(sortColumn) && !string.IsNullOrEmpty(sortColumnDir))
            {
                // sort theo library and location
                #region
                if (sortColumn.Equals("Library"))
                {
                    if (sortColumnDir.Equals("asc"))
                    {
                        holdings = db.HOLDINGs.Join(db.HOLDING_LIBRARY, holding => holding.LibID, lib => lib.ID, (holding, lib) => new { HOLDING = holding, HOLDING_LIBRARY = lib })
                             .Where(y => y.HOLDING.ItemID == itemID).OrderBy(o => o.HOLDING_LIBRARY.AccessEntry).ToList().Select(x => new HOLDING()
                             {
                                 ID = x.HOLDING.ID,
                                 LibID = x.HOLDING.LibID,
                                 LocationID = x.HOLDING.LocationID,
                                 AcquiredDate = x.HOLDING.AcquiredDate,
                                 AcquiredSourceID = x.HOLDING.AcquiredSourceID,
                                 CallNumber = x.HOLDING.CallNumber,
                                 CopyNumber = x.HOLDING.CopyNumber,
                                 Currency = x.HOLDING.Currency,
                                 Note = x.HOLDING.Note,
                                 Price = x.HOLDING.Price,
                                 ReceiptedDate = x.HOLDING.ReceiptedDate,
                                 RecordNumber = x.HOLDING.RecordNumber,
                                 Shelf = x.HOLDING.Shelf,
                                 Volume = x.HOLDING.Volume,
                                 ItemID = x.HOLDING.ItemID,
                                 UseCount = x.HOLDING.UseCount,
                                 InUsed = x.HOLDING.InUsed,
                                 InCirculation = x.HOLDING.InCirculation,
                                 ILLID = x.HOLDING.ILLID,
                                 POID = x.HOLDING.POID,
                                 DateLastUsed = x.HOLDING.DateLastUsed,
                                 LoanTypeID = x.HOLDING.LoanTypeID,
                                 LockedReason = x.HOLDING.LockedReason,
                                 IsLost = x.HOLDING.IsLost,
                                 IsConfusion = x.HOLDING.IsConfusion,
                                 Rate = x.HOLDING.Rate,
                                 Reason = x.HOLDING.Reason,
                                 OnHold = x.HOLDING.OnHold,
                                 Acquired = x.HOLDING.Acquired,
                                 Availlable = x.HOLDING.Availlable,

                             }).ToList();
                    }
                    else
                    {
                        holdings = db.HOLDINGs.Join(db.HOLDING_LIBRARY, holding => holding.LibID, lib => lib.ID, (holding, lib) => new { HOLDING = holding, HOLDING_LIBRARY = lib })
                            .Where(y => y.HOLDING.ItemID == itemID).OrderByDescending(o => o.HOLDING_LIBRARY.AccessEntry).ToList().Select(x => new HOLDING()
                            {
                                ID = x.HOLDING.ID,
                                LibID = x.HOLDING.LibID,
                                LocationID = x.HOLDING.LocationID,
                                AcquiredDate = x.HOLDING.AcquiredDate,
                                AcquiredSourceID = x.HOLDING.AcquiredSourceID,
                                CallNumber = x.HOLDING.CallNumber,
                                CopyNumber = x.HOLDING.CopyNumber,
                                Currency = x.HOLDING.Currency,
                                Note = x.HOLDING.Note,
                                Price = x.HOLDING.Price,
                                ReceiptedDate = x.HOLDING.ReceiptedDate,
                                RecordNumber = x.HOLDING.RecordNumber,
                                Shelf = x.HOLDING.Shelf,
                                Volume = x.HOLDING.Volume,
                                ItemID = x.HOLDING.ItemID,
                                UseCount = x.HOLDING.UseCount,
                                InUsed = x.HOLDING.InUsed,
                                InCirculation = x.HOLDING.InCirculation,
                                ILLID = x.HOLDING.ILLID,
                                POID = x.HOLDING.POID,
                                DateLastUsed = x.HOLDING.DateLastUsed,
                                LoanTypeID = x.HOLDING.LoanTypeID,
                                LockedReason = x.HOLDING.LockedReason,
                                IsLost = x.HOLDING.IsLost,
                                IsConfusion = x.HOLDING.IsConfusion,
                                Rate = x.HOLDING.Rate,
                                Reason = x.HOLDING.Reason,
                                OnHold = x.HOLDING.OnHold,
                                Acquired = x.HOLDING.Acquired,
                                Availlable = x.HOLDING.Availlable,
                            }).ToList();
                    }

                }
                else if (sortColumn.Equals("Location"))
                {

                    if (sortColumnDir.Equals("asc"))
                    {
                        holdings = db.HOLDINGs.Join(db.HOLDING_LOCATION, holding => holding.LocationID, loc => loc.ID, (holding, loc) => new { HOLDING = holding, HOLDING_LOCATION = loc })
                            .Where(y => y.HOLDING.ItemID == itemID).OrderBy(o => o.HOLDING_LOCATION.Symbol).ToList().Select(x => new HOLDING()
                            {
                                ID = x.HOLDING.ID,
                                LibID = x.HOLDING.LibID,
                                LocationID = x.HOLDING.LocationID,
                                AcquiredDate = x.HOLDING.AcquiredDate,
                                AcquiredSourceID = x.HOLDING.AcquiredSourceID,
                                CallNumber = x.HOLDING.CallNumber,
                                CopyNumber = x.HOLDING.CopyNumber,
                                Currency = x.HOLDING.Currency,
                                Note = x.HOLDING.Note,
                                Price = x.HOLDING.Price,
                                ReceiptedDate = x.HOLDING.ReceiptedDate,
                                RecordNumber = x.HOLDING.RecordNumber,
                                Shelf = x.HOLDING.Shelf,
                                Volume = x.HOLDING.Volume,
                                ItemID = x.HOLDING.ItemID,
                                UseCount = x.HOLDING.UseCount,
                                InUsed = x.HOLDING.InUsed,
                                InCirculation = x.HOLDING.InCirculation,
                                ILLID = x.HOLDING.ILLID,
                                POID = x.HOLDING.POID,
                                DateLastUsed = x.HOLDING.DateLastUsed,
                                LoanTypeID = x.HOLDING.LoanTypeID,
                                LockedReason = x.HOLDING.LockedReason,
                                IsLost = x.HOLDING.IsLost,
                                IsConfusion = x.HOLDING.IsConfusion,
                                Rate = x.HOLDING.Rate,
                                Reason = x.HOLDING.Reason,
                                OnHold = x.HOLDING.OnHold,
                                Acquired = x.HOLDING.Acquired,
                                Availlable = x.HOLDING.Availlable,
                            }).ToList();
                    }
                    else
                    {
                        holdings = db.HOLDINGs.Join(db.HOLDING_LOCATION, holding => holding.LocationID, loc => loc.ID, (holding, loc) => new { HOLDING = holding, HOLDING_LOCATION = loc })
                            .Where(y => y.HOLDING.ItemID == itemID).OrderByDescending(o => o.HOLDING_LOCATION.Symbol).ToList().Select(x => new HOLDING()
                            {
                                ID = x.HOLDING.ID,
                                LibID = x.HOLDING.LibID,
                                LocationID = x.HOLDING.LocationID,
                                AcquiredDate = x.HOLDING.AcquiredDate,
                                AcquiredSourceID = x.HOLDING.AcquiredSourceID,
                                CallNumber = x.HOLDING.CallNumber,
                                CopyNumber = x.HOLDING.CopyNumber,
                                Currency = x.HOLDING.Currency,
                                Note = x.HOLDING.Note,
                                Price = x.HOLDING.Price,
                                ReceiptedDate = x.HOLDING.ReceiptedDate,
                                RecordNumber = x.HOLDING.RecordNumber,
                                Shelf = x.HOLDING.Shelf,
                                Volume = x.HOLDING.Volume,
                                ItemID = x.HOLDING.ItemID,
                                UseCount = x.HOLDING.UseCount,
                                InUsed = x.HOLDING.InUsed,
                                InCirculation = x.HOLDING.InCirculation,
                                ILLID = x.HOLDING.ILLID,
                                POID = x.HOLDING.POID,
                                DateLastUsed = x.HOLDING.DateLastUsed,
                                LoanTypeID = x.HOLDING.LoanTypeID,
                                LockedReason = x.HOLDING.LockedReason,
                                IsLost = x.HOLDING.IsLost,
                                IsConfusion = x.HOLDING.IsConfusion,
                                Rate = x.HOLDING.Rate,
                                Reason = x.HOLDING.Reason,
                                OnHold = x.HOLDING.OnHold,
                                Acquired = x.HOLDING.Acquired,
                                Availlable = x.HOLDING.Availlable,
                            }).ToList();
                    }
                }
                else if (sortColumn.Equals("Status"))
                {
                    if (sortColumnDir.Equals("asc"))
                    {
                        holdings = db.HOLDINGs.Where(h => h.ItemID == itemID).OrderBy( o => o.Acquired ).ThenBy( o => o.InCirculation ).ThenBy(o=> o.InUsed).ToList();
                    }
                    else 
                    {
                        holdings = db.HOLDINGs.Where(h => h.ItemID == itemID).OrderByDescending(o => o.Acquired).ThenByDescending(o => o.InCirculation).ThenByDescending(o => o.InUsed).ToList();
                    }
                }
                #endregion  
                else
                    holdings = db.HOLDINGs.SqlQuery("Select * from HOLDING where ItemID=" + itemID + " order by " + sortColumn + " " + sortColumnDir).ToList();
            }
            
            //Search    
            if (!string.IsNullOrEmpty(searchValue))
            {
                holdings = holdings.Where(m => m.CopyNumber.ToLower().Contains(searchValue.ToLower())).ToList();
            }

            //total number of rows count     
            RecordsTotal = holdings.Count();
            //Paging     
            var data = holdings.Skip(skip).Take(pageSize).ToList();
            List<HoldingTable> holdingTables = new List<HoldingTable>();
          
            foreach (var holding in data)
            {
                holdingTables.Add(new HoldingTable()
                {
                    ID = holding.ID,
                    LibID = holding.LibID,
                    LocID = holding.LocationID,
                    Library = db.HOLDING_LIBRARY.Where(h => h.ID == holding.LibID).Select(h => h.AccessEntry).FirstOrDefault(),
                    Location = db.HOLDING_LOCATION.Where(h => h.ID == holding.LocationID).Select(h => h.Symbol).FirstOrDefault(),
                    AcquiredDate = holding.AcquiredDate.Value.ToString("dd/MM/yyyy"),
                    AcquiredSource = db.ACQ_ACQUIRE_SOURCE.Where(h => h.ID == holding.AcquiredSourceID).Select(h => h.Source).FirstOrDefault(),
                    CallNumber = holding.CallNumber,
                    CopyNumber = holding.CopyNumber,
                    Currency = holding.Currency,
                    Volume = holding.Volume,
                    Note = holding.Note,
                    Price = holding.Price,
                    ReceiptedDate = holding.ReceiptedDate != null ? holding.ReceiptedDate.Value.ToString("dd/MM/yyyy"): "" ,
                    RecordNumber = holding.RecordNumber,
                    Shelf = holding.Shelf,
                    Status = shelfBusiness.GetHoldingStatus(holding.InUsed, holding.InCirculation.Value, holding.Acquired),
                });
            }

            //Returning Json Data    
            return Json(new { draw = draw, recordsFiltered = RecordsTotal, recordsTotal = RecordsTotal, data = holdingTables, numberOfFreeCopies = numberFreeCopies, compositeHolding = compositeHoldingData, numberRecord= numberOfRecord, Message = message });
        }

        

        [HttpPost]
        public JsonResult SearchItem(string title,string copynumber, string author,string publisher,string year,string isbn)
        {
            List<SP_GET_TITLES_Result> data= null;
            string message = shelfBusiness.SearchItem(title.Trim(), copynumber.Trim(), author.Trim(), publisher.Trim(), year.Trim(), isbn.Trim(), ref data);
            return Json(new { Message = message, data = data }, JsonRequestBehavior.AllowGet);
        }


        [AuthAttribute(ModuleID = 4, RightID = "29")]
        public ActionResult LiquidationOrLost()
        {

            foreach (var item in db.SP_HOLDING_LIB_SEL(42).ToList())
            {
                libs.Add(new Library(item.ID.ToString(), item.Code, item.LibName));
            }

            ViewBag.libs = libs;

            foreach (Library lib in libs)
            {
                List<Location> locs = new List<Location>();

                foreach (var item in db.SP_HOLDING_LIBLOCUSER_SEL(42, Int32.Parse(lib.ID)).ToList())
                {
                    locs.Add(new Location(item.LOCNAME, item.ID.ToString(), item.GroupID, item.LibID.ToString(), item.Symbol, item.Code));
                }
                lic_locs.Add(new LibraryLocation(lib, locs));
            }

            ViewBag.lic_locs = lic_locs;

            return View();
        }

        [HttpPost]
        public PartialViewResult LiquidationOrLostPartialView(string libname, string locname, string page_index,
            string record_per_page, string state, string find_title, string find_code,
            string find_price, string find_dkcb, string find_so_dinh_danh, string find_volume,
            string selected_checkbox_list, string strType, string libid, string locid, string date_from, string date_to, string reason, string date_type)
        {
            // setup for "date type list"
            List<SelectListItem> datetypes = new List<SelectListItem>();
            datetypes.Add(new SelectListItem { Text = "-------------", Value = "-1" });
            datetypes.Add(new SelectListItem { Text = "Ngày bổ sung", Value = "1" });
            datetypes.Add(new SelectListItem { Text = "Ngày ghi nhận mất", Value = "2" });
            datetypes.Add(new SelectListItem { Text = "Ngày mượn cuối", Value = "3" });
            ViewBag.datetypes = datetypes;

            // setup for "reason dropdown list"
            List<SelectListItem> ta = new List<SelectListItem>();
            ta.Add(new SelectListItem { Text = "---------------", Value = "-1" });
            foreach (var item in db.SP_HOLDING_REMOVE_REASON_SEL(0).ToList())
            {
                ta.Add(new SelectListItem { Text = item.REASON, Value = item.ID.ToString() });
            }
            ViewBag.ta = ta;

            List<SelectListItem> lib = new List<SelectListItem>();
            foreach (var item in db.FPT_SP_HOLDING_LIB_SEL().ToList())
            {
                lib.Add(new SelectListItem { Text = item.Code, Value = item.ID.ToString() });
            }
            ViewBag.list_lib = lib;

            // searching for item
            if (string.IsNullOrEmpty(state))
            {
                findingItem(find_title, find_code, find_price, find_dkcb, find_so_dinh_danh, find_volume, date_from, date_to, date_type, reason);
                ViewBag.screen_stage = "finding result";
            }
            // remove item from holding removed item
            else if (state == "remove item")
            {
                ViewBag.selected_checkbox_list = selected_checkbox_list;
                string selected_checkboxes = ModifyString(selected_checkbox_list);
                List<string> selected_checkbox_tempo = selected_checkboxes.Split(',').ToList();
                List<string> selected_checkboxes_list_final = new List<string>();

                foreach (string item in selected_checkbox_tempo)
                {
                    if (item.Contains("true"))
                    {
                        string[] index = item.Split(':');
                        List<Removed_Item> tempo_list =
                         db.Database.SqlQuery<Removed_Item>(
                        "FPT_SP_GET_HOLDING_REMOVED_WITH_ID {0}",
                        new object[] { index[0] }
                        ).ToList();
                        foreach (var i in tempo_list)
                        {
                            selected_checkboxes_list_final.Add(i.CopyNumber);
                            break;
                        }
                        // delete item from database
                        db.FPT_SP_HOLDING_REMOVED_ITEM_DEL(index[0]);
                    }
                }

                ViewBag.selected_checkboxes_list_final = selected_checkboxes_list_final;
                ViewBag.screen_stage = "remove result";
            }
            // restore item from holding removed into holding
            else if (state == "restore result")
            {
                string selected_checkboxes = ModifyString(selected_checkbox_list);
                List<string> selected_checkbox_tempo = selected_checkboxes.Split(',').ToList(); // list checkbox includes checked and unchecked 
                List<string> selected_checkboxes_list_finally = new List<string>();             // list checked checkbox
                List<Removed_Item> list_data = new List<Removed_Item>();
                List<string> danh_sach_dang_ky_ca_biet = new List<string>();

                foreach (string item in selected_checkbox_tempo)
                {
                    if (item.Contains("true"))
                    {
                        string[] index = item.Split(':');
                        selected_checkboxes_list_finally.Add(index[0]);
                        //get removed item from holding removed by item's id
                        List<Removed_Item> tempo_list =
                         db.Database.SqlQuery<Removed_Item>(
                        "FPT_SP_GET_HOLDING_REMOVED_WITH_ID {0}",
                        new object[] { index[0] }
                        ).ToList();
                        foreach (var i in tempo_list)
                        {
                            list_data.Add(i);
                            break;
                        }

                    }
                }
                // restore to the old position
                // listdata.getItem().LibID .LocationID
                if (strType.Equals("0"))
                {
                    foreach (Removed_Item rm in list_data)
                    {
                        danh_sach_dang_ky_ca_biet.Add(rm.CopyNumber);

                        int itemid = rm.ItemID;
                        int locationid = rm.LocationID;
                        int libraryid = rm.LibID;
                        int use_count = rm.UseCount;
                        string volume = rm.Volume;
                        string acquiredDate = Convert.ToString(rm.AcquiredDate);
                        string copy_number = rm.CopyNumber;
                        int in_used = 0; // sach chua duoc muon
                        int in_circulation = 0; // sach chua duoc luu thong
                        int ill_id = 0;
                        double price = (double)rm.Price;
                        string shelf = rm.Shelf;
                        int? po_id = string.IsNullOrEmpty(Convert.ToString(rm.PoID)) ? 0 : rm.PoID;
                        string datelastused = Convert.ToString(rm.DateLastUsed);
                        string call_number = rm.CallNumber;
                        int acquired = 0;  // sach chua kiem nhan
                        string note = "";
                        int loantypeid = rm.LoanTypeID;
                        int acquired_source = rm.AcquiredSourceID;
                        string currency_coode = "VND";
                        float rate = 1;
                        string record_number = "";
                        string receipted_date = "";

                        db.SP_HOLDING_INS(itemid, locationid, libraryid,
                            use_count, volume, acquiredDate, copy_number,
                            in_used, in_circulation, ill_id,
                            price, shelf, po_id, datelastused,
                            call_number, acquired, note, loantypeid,
                            acquired_source, currency_coode, rate,
                            record_number, receipted_date);
                        // delete item from database
                        db.FPT_SP_HOLDING_REMOVED_ITEM_DEL(Convert.ToString(rm.ID));
                    }
                }
                // restore to the new position 
                // arcording to the new libid and loc id
                else if (strType.Equals("1"))
                {
                    List<FPT_SP_GET_HOLDING_REMOVED_GET_COPYNUMBER_TO_INS_Result>
                        fe = db.FPT_SP_GET_HOLDING_REMOVED_GET_COPYNUMBER_TO_INS(libid, locid).ToList();
                    string copy = "";
                    string symbol = "";
                    string numberPart = "";
                    if (fe.Count != 0)
                    {
                        foreach (var item in fe)
                        {
                            copy = item.CopyNumber;
                            symbol = item.Symbol;
                        }
                        Regex re = new Regex(@"([a-zA-Z]+)(\d+)");
                        Match result = re.Match(copy);

                        numberPart = result.Groups[2].Value;
                    }
                    else
                    {
                        numberPart = "0";
                        List<SelectListItem> loc = new List<SelectListItem>();
                        foreach (var l in db.SP_HOLDING_LIBLOCUSER_SEL(42, Int32.Parse(libid)).ToList())
                        {
                            if (l.ID == Int32.Parse(locid))
                            {
                                symbol = l.Symbol;
                            }
                            loc.Add(new SelectListItem { Text = l.Symbol, Value = l.ID.ToString() });
                        }
                    }

                    //
                    int count = 1;
                    foreach (Removed_Item rm in list_data)
                    {
                        danh_sach_dang_ky_ca_biet.Add(rm.CopyNumber);

                        int itemid = rm.ItemID;
                        int locationid = Int32.Parse(locid);
                        int libraryid = Int32.Parse(libid);
                        int use_count = rm.UseCount;
                        string volume = rm.Volume;
                        string acquiredDate = "";
                        string copy_number = "";
                        int x = Convert.ToInt32(numberPart);
                        int y = 10000000 + x + count;
                        if (x < 1000000)
                        {
                            copy_number = symbol + Convert.ToString(y).Substring(2);
                        }
                        else if (x > 1000000 && x < 10000000)
                        {
                            copy_number = symbol + Convert.ToString(y).Substring(1);
                        }

                        count++;


                        int in_used = 0; // sach chua duoc muon
                        int in_circulation = 0; // sach chua duoc luu thong
                        int ill_id = 0;
                        double price = (double)rm.Price;
                        string shelf = rm.Shelf;
                        int? po_id = string.IsNullOrEmpty(Convert.ToString(rm.PoID)) ? 0 : rm.PoID;
                        string datelastused = Convert.ToString(rm.DateLastUsed);
                        string call_number = rm.CallNumber;
                        int acquired = 0;
                        string note = "";
                        int loantypeid = rm.LoanTypeID;
                        int acquired_source = rm.AcquiredSourceID;
                        string currency_coode = "VND";
                        float rate = 1;
                        string record_number = "";
                        string receipted_date = "";

                        db.SP_HOLDING_INS(itemid, locationid, libraryid,
                            use_count, volume, acquiredDate, copy_number,
                            in_used, in_circulation, ill_id,
                            price, shelf, po_id, datelastused,
                            call_number, acquired, note, loantypeid,
                            acquired_source, currency_coode, rate,
                            record_number, receipted_date);
                    }
                }
                ViewBag.screen_stage = "restore result";
                // inform use which item was restore
                ViewBag.selected_checkboxes_list_final = danh_sach_dang_ky_ca_biet;
            }
            // restore item from holding removed into holding AND UNLOCK ITEM
            else if (state == "restore and unlock result")
            {

                string selected_checkboxes = ModifyString(selected_checkbox_list);
                List<string> selected_checkbox_tempo = selected_checkboxes.Split(',').ToList(); // list checkbox includes checked and unchecked 
                List<string> selected_checkboxes_list_finally = new List<string>();             // list checked checkbox

                List<Removed_Item> list_data = new List<Removed_Item>();
                List<string> danh_sach_dang_ky_ca_biet = new List<string>();

                foreach (string item in selected_checkbox_tempo)
                {
                    if (item.Contains("true"))
                    {
                        string[] index = item.Split(':');
                        selected_checkboxes_list_finally.Add(index[0]);

                        //get removed item from holding removed by item's id
                        List<Removed_Item> tempo_list =
                         db.Database.SqlQuery<Removed_Item>(
                        "FPT_SP_GET_HOLDING_REMOVED_WITH_ID {0}",
                        new object[] { index[0] }
                        ).ToList();
                        foreach (var i in tempo_list)
                        {
                            list_data.Add(i);
                            break;
                        }

                    }
                }

                // restore to the old position             
                // listdata.getItem().LibID .LocationID
                if (strType.Equals("0"))
                {
                    foreach (Removed_Item rm in list_data)
                    {
                        danh_sach_dang_ky_ca_biet.Add(rm.CopyNumber);

                        int itemid = rm.ItemID;
                        int locationid = rm.LocationID;
                        int libraryid = rm.LibID;
                        int use_count = rm.UseCount;
                        string volume = rm.Volume;
                        string acquiredDate = "";
                        string copy_number = rm.CopyNumber;
                        int in_used = 0; // sach chua duoc muon
                        int in_circulation = 1; // sach duoc luu thong   UNLOCK ITEM
                        int ill_id = 0;
                        double price = (double)rm.Price;
                        string shelf = rm.Shelf;
                        int? po_id = string.IsNullOrEmpty(Convert.ToString(rm.PoID)) ? 0 : rm.PoID;
                        string datelastused = "";
                        string call_number = rm.CallNumber;
                        int acquired = 1; // sach da duoc kiem nhan
                        string note = "";
                        int loantypeid = rm.LoanTypeID;
                        int acquired_source = rm.AcquiredSourceID;
                        string currency_coode = "VND";
                        float rate = 1;
                        string record_number = "";
                        string receipted_date = "";

                        db.SP_HOLDING_INS(itemid, locationid, libraryid,
                            use_count, volume, acquiredDate, copy_number,
                            in_used, in_circulation, ill_id,
                            price, shelf, po_id, datelastused,
                            call_number, acquired, note, loantypeid,
                            acquired_source, currency_coode, rate,
                            record_number, receipted_date);
                        // delete item from database
                        db.FPT_SP_HOLDING_REMOVED_ITEM_DEL(Convert.ToString(rm.ID));
                    }
                }
                // restore to the new position                      
                // arcording to the new libid and loc id
                else if (strType.Equals("1"))
                {
                    List<FPT_SP_GET_HOLDING_REMOVED_GET_COPYNUMBER_TO_INS_Result>
                       fe = db.FPT_SP_GET_HOLDING_REMOVED_GET_COPYNUMBER_TO_INS(libid, locid).ToList();
                    string copy = "";
                    string symbol = "";
                    string numberPart = "";
                    if (fe.Count != 0)
                    {
                        foreach (var item in fe)
                        {
                            copy = item.CopyNumber;
                            symbol = item.Symbol;
                        }
                        Regex re = new Regex(@"([a-zA-Z]+)(\d+)");
                        Match result = re.Match(copy);

                        numberPart = result.Groups[2].Value;
                    }
                    else
                    {
                        numberPart = "0";
                        List<SelectListItem> loc = new List<SelectListItem>();
                        foreach (var l in db.SP_HOLDING_LIBLOCUSER_SEL(42, Int32.Parse(libid)).ToList())
                        {
                            if (l.ID == Int32.Parse(locid))
                            {
                                symbol = l.Symbol;
                            }
                            loc.Add(new SelectListItem { Text = l.Symbol, Value = l.ID.ToString() });
                        }
                    }
                    //
                    int count = 1;

                    foreach (Removed_Item rm in list_data)
                    {
                        danh_sach_dang_ky_ca_biet.Add(rm.CopyNumber);

                        int itemid = rm.ItemID;
                        int locationid = Int32.Parse(locid);
                        int libraryid = Int32.Parse(libid);
                        int use_count = rm.UseCount;
                        string volume = rm.Volume;
                        string acquiredDate = "";

                        string copy_number = "";
                        int x = Convert.ToInt32(numberPart);
                        int y = 10000000 + x + count;
                        if (x < 1000000)
                        {
                            copy_number = symbol + Convert.ToString(y).Substring(2);
                        }
                        else if (x > 1000000 && x < 10000000)
                        {
                            copy_number = symbol + Convert.ToString(y).Substring(1);
                        }
                        count++;

                        int in_used = 0; // sach chua duoc muon
                        int in_circulation = 1; // sach duoc luu thong   UNLOCK ITEM
                        int ill_id = 0;
                        double price = (double)rm.Price;
                        string shelf = rm.Shelf;
                        int? po_id = string.IsNullOrEmpty(Convert.ToString(rm.PoID)) ? 0 : rm.PoID;
                        string datelastused = "";
                        string call_number = rm.CallNumber;
                        int acquired = 1; // da duoc kiem nhan
                        string note = "";
                        int loantypeid = rm.LoanTypeID;
                        int acquired_source = rm.AcquiredSourceID;
                        string currency_coode = "VND";
                        float rate = 1;
                        string record_number = "";
                        string receipted_date = "";

                        db.SP_HOLDING_INS(itemid, locationid, libraryid,
                            use_count, volume, acquiredDate, copy_number,
                            in_used, in_circulation, ill_id,
                            price, shelf, po_id, datelastused,
                            call_number, acquired, note, loantypeid,
                            acquired_source, currency_coode, rate,
                            record_number, receipted_date);
                    }
                }

                ViewBag.screen_stage = "restore and unlock result";

                // inform use which item was restore
                ViewBag.selected_checkboxes_list_final = danh_sach_dang_ky_ca_biet;
            }
            //display thong thuong
            else
            {
                if (locname == null || locname.Equals("Tất cả các kho."))
                {
                    getRemovedItemFromLibrary(libname, page_index, record_per_page);
                }
                else
                {
                    getRemovedItemFromLocation(locname, page_index, record_per_page);
                }
                ViewBag.record_per_page = record_per_page;
                ViewBag.page_index = page_index;
                ViewBag.screen_stage = "";
            }
            return PartialView("LiquidationOrLostPartialView");
        }


        public void findingItem(string find_title1, string find_code1, string find_price1,
            string find_dkcb1, string find_so_dinh_danh1, string find_volume1,
            string date_from1, string date_to1, string date_type1, string reason1)
        {

            string find_title = string.IsNullOrEmpty(find_title1) ? null : Request.Form["find_title"].ToString();
            // ma thanh ly
            string find_code = string.IsNullOrEmpty(find_code1) ? null : Request.Form["find_code"].ToString();
            string find_price = string.IsNullOrEmpty(find_price1) ? null : Request.Form["find_price"].ToString();
            string find_dkcb = string.IsNullOrEmpty(find_dkcb1) ? null : Request.Form["find_dkcb"].ToString();
            string find_so_dinh_danh = string.IsNullOrEmpty(find_so_dinh_danh1) ? null : Request.Form["find_so_dinh_danh"].ToString();
            string find_volume = string.IsNullOrEmpty(find_volume1) ? null : Request.Form["find_volume"].ToString();
            DateTime? date_from = null;
            DateTime? date_to = null;
            if (!string.IsNullOrEmpty(date_from1))
            {
                date_from = Convert.ToDateTime(date_from1);
            }

            if (!string.IsNullOrEmpty(date_to1))
            {
                date_to = Convert.ToDateTime(date_to1);
            }
            string date_type = date_type1;
            string reason = reason1;
            List<Removed_Item> list = new List<Removed_Item>();
            //try
            //{
                list =
                db.Database.SqlQuery<Removed_Item>(
                "FPT_SP_GET_HOLDING_REMOVED {0},{1},{2},{3},{4},{5},{6},{7},{8},{9},{10},{11},{12}",
                new object[] { null, null, null, find_dkcb, find_so_dinh_danh, find_code, find_volume, find_title, find_price, date_from, date_to, date_type, reason }
                ).ToList();
                if (list.Count != 0)
                {
                    //modify content
                    foreach (var item in list)
                    {
                        item.Content = GetContent(item.Content);
                    }

                    foreach (Removed_Item rm in list)
                    {
                        ViewBag.LibName = rm.LibName;
                        ViewBag.LocName = rm.LocName;
                        break;
                    }
                    ViewBag.list = list;
                    ViewBag.pagingamount = 1;
                    ViewBag.page_index = "1";
                    ViewBag.record_per_page = Convert.ToString(list.Count());
                }
                else
                {
                    ViewBag.LibName = "";
                    ViewBag.LocName = "";
                    ViewBag.list = list;
                    ViewBag.pagingamount = 1;
                    ViewBag.page_index = "1";
                    ViewBag.record_per_page = Convert.ToString(list.Count());
                }
            //}
            //catch (Exception e)
            //{
            //    ViewBag.LibName = "";
            //    ViewBag.LocName = "";
            //    ViewBag.list = list;
            //    ViewBag.pagingamount = 1;
            //    ViewBag.page_index = "1";
            //    ViewBag.record_per_page = Convert.ToString(list.Count());
            //}

        }

        [AuthAttribute(ModuleID = 4, RightID = "29")]
        public ActionResult NotYetChecked()
        {
            foreach (var item in db.SP_HOLDING_LIB_SEL(42).ToList())
            {
                int lbid = Int32.Parse(item.ID.ToString());
                Total_Amount total = null;
                List<Total_Amount> ta =
                     db.Database.SqlQuery<Total_Amount>(
                    "SP_GET_HOLDING_SUMMARY_INFOR {0},{1},{2}",
                    new object[] { lbid, 0, 3 }
                    ).ToList();
                foreach (var jtem in ta)
                {
                    total = jtem;
                }
                libs.Add(new Library(item.ID.ToString(), item.Code, item.LibName, total));
            }

            ViewBag.libs = libs;

            foreach (Library lib in libs)
            {
                List<Location> locs = new List<Location>();

                foreach (var item in db.SP_HOLDING_LIBLOCUSER_SEL(42, Int32.Parse(lib.ID)).ToList())
                {
                    int lbid = Int32.Parse(lib.ID.ToString());
                    int lcid = Int32.Parse(item.ID.ToString());
                    Total_Amount total = null;
                    List<Total_Amount> ta =
                        db.Database.SqlQuery<Total_Amount>(
                        "SP_GET_HOLDING_SUMMARY_INFOR {0},{1},{2}",
                        new object[] { lbid, lcid, 3 }
                        ).ToList();
                    foreach (var jtem in ta)
                    {
                        total = jtem;
                    }
                    locs.Add(new Location(item.LOCNAME, item.ID.ToString(), item.GroupID, item.LibID.ToString(), item.Symbol, item.Code, total));
                }
                lic_locs.Add(new LibraryLocation(lib, locs));
            }

            ViewBag.lic_locs = lic_locs;

            return View();
        }

        [HttpPost]
        public PartialViewResult NotYetCheckedPartialView(string libname, string locname, string page_index,
            string record_per_page, string state, string find_title, string find_code,
            string find_price, string find_dkcb, string find_so_dinh_danh, string find_volume,
            string selected_checkbox_list, string strType, string libid, string locid)
        {
            List<SelectListItem> lib = new List<SelectListItem>();
            foreach (var item in db.FPT_SP_HOLDING_LIB_SEL().ToList())
            {
                lib.Add(new SelectListItem { Text = item.Code, Value = item.ID.ToString() });
            }
            ViewBag.list_lib = lib;

            // searching book
            if (string.IsNullOrEmpty(state))
            {
                findingItem_not_yet_checked(find_title, find_code, find_price, find_dkcb, find_so_dinh_danh, find_volume);
                ViewBag.screen_stage = "finding result";
            }
            // remove item from holding table
            else if (state == "remove item")
            {
                ViewBag.selected_checkbox_list = selected_checkbox_list;
                string selected_checkboxes = ModifyString(selected_checkbox_list);
                List<string> selected_checkbox_tempo = selected_checkboxes.Split(',').ToList();
                List<string> selected_checkboxes_list_final = new List<string>();

                foreach (string item in selected_checkbox_tempo)
                {
                    if (item.Contains("true"))
                    {
                        string[] index = item.Split(':');

                        List<Holding_Item> tempo_list =
                         db.Database.SqlQuery<Holding_Item>(
                        "FPT_SP_GET_HOLDING_IDs_v1_searching_with_id {0},{1},{2},{3},{4}",
                        new object[] { index[0], "3", "0", null, null }
                        ).ToList();
                        foreach (Holding_Item hi in tempo_list)
                        {
                            selected_checkboxes_list_final.Add(hi.CopyNumber);
                        }
                        // delete item from database
                        db.FPT_SP_HOLDING_DEL(index[0]);
                    }
                }

                ViewBag.selected_checkboxes_list_final = selected_checkboxes_list_final;
                ViewBag.screen_stage = "remove result";
            }
            // kiểm nhận sách
            else if (state == "restore result")
            {
                string selected_checkboxes = ModifyString(selected_checkbox_list);
                List<string> selected_checkbox_tempo = selected_checkboxes.Split(',').ToList(); // list checkbox includes checked and unchecked 
                List<string> selected_checkboxes_list_finally = new List<string>();             // list checked checkbox

                List<Holding_Item> list_data = new List<Holding_Item>();
                List<string> danh_sach_dang_ky_ca_biet = new List<string>();

                foreach (string item in selected_checkbox_tempo)
                {
                    if (item.Contains("true"))
                    {
                        string[] index = item.Split(':');

                        List<Holding_Item> tempo_lists =
                        db.Database.SqlQuery<Holding_Item>(
                       "FPT_SP_GET_HOLDING_IDs_v1_searching_with_id {0},{1},{2},{3},{4}",
                       new object[] { index[0], "0", "0", null, null }
                       ).ToList();
                        foreach (Holding_Item hi in tempo_lists)
                        {
                            selected_checkboxes_list_finally.Add(hi.CopyNumber);
                        }

                        //get removed item from holding removed by item's id
                        List<Holding_Item> tempo_list =
                         db.Database.SqlQuery<Holding_Item>(
                        "FPT_SP_GET_HOLDING_IDs_v1_searching_with_id {0},{1},{2},{3},{4}",
                        new object[] { index[0], "3", "0", null, null }
                        ).ToList();
                        foreach (var i in tempo_list)
                        {
                            list_data.Add(i);
                            break;
                        }
                    }
                }

                List<FPT_SP_GET_HOLDING_REMOVED_GET_COPYNUMBER_TO_INS_Result>
                    fe = new List<FPT_SP_GET_HOLDING_REMOVED_GET_COPYNUMBER_TO_INS_Result>();
                if (!string.IsNullOrEmpty(locid))
                {
                    fe = db.FPT_SP_GET_HOLDING_REMOVED_GET_COPYNUMBER_TO_INS(libid, locid).ToList();
                }
                string copy = "";
                string symbol = "";
                string numberPart = "";
                if (fe.Count != 0)
                {
                    foreach (var item in fe)
                    {
                        copy = item.CopyNumber;
                        symbol = item.Symbol;
                    }

                    Regex re = new Regex(@"([a-zA-Z]+)(\d+)");
                    Match result = re.Match(copy);

                    numberPart = result.Groups[2].Value;
                }
                else
                {
                    numberPart = "0";
                    List<SelectListItem> loc = new List<SelectListItem>();
                    foreach (var l in db.SP_HOLDING_LIBLOCUSER_SEL(42, Int32.Parse(libid)).ToList())
                    {
                        if (l.ID == Int32.Parse(locid))
                        {
                            symbol = l.Symbol;
                        }
                        loc.Add(new SelectListItem { Text = l.Symbol, Value = l.ID.ToString() });
                    }
                }
                //
                int count = 1;
                foreach (Holding_Item rm in list_data)
                {
                    string copy_number = "";
                    int x = Convert.ToInt32(numberPart);
                    int y = 10000000 + x + count;
                    string abc = Convert.ToString(y);
                    if (x < 1000000)
                    {
                        copy_number = symbol + abc.Substring(2);
                    }
                    else if (x >= 1000000 && x < 10000000)
                    {
                        copy_number = symbol + abc.Substring(1);
                    }

                    count++;
                    danh_sach_dang_ky_ca_biet.Add(rm.CopyNumber);
                    int itemid = rm.ID;
                    // kiểm nhận, lưu tại vị trí location và library hiện tại của sách
                    if (strType.Equals("0"))
                    {
                        db.FPT_SP_HOLDING_UPDATE(Convert.ToString(itemid), "", "", rm.CopyNumber, "1");
                    }
                    // kiểm nhận sách
                    // save arcording to the new libid and loc id
                    else if (strType.Equals("1"))
                    {
                        db.FPT_SP_HOLDING_UPDATE(Convert.ToString(itemid), locid, libid, copy_number, "1");
                    }
                }

                ViewBag.screen_stage = "restore result";
                // inform use which item was restore
                ViewBag.selected_checkboxes_list_final = danh_sach_dang_ky_ca_biet;
            }
            // kiểm nhận và mở khóa sách
            else if (state == "restore and unlock result")
            {
                string selected_checkboxes = ModifyString(selected_checkbox_list);
                List<string> selected_checkbox_tempo = selected_checkboxes.Split(',').ToList(); // list checkbox includes checked and unchecked 
                List<string> selected_checkboxes_list_finally = new List<string>();             // list checked checkbox

                List<Holding_Item> list_data = new List<Holding_Item>();
                List<string> danh_sach_dang_ky_ca_biet = new List<string>();

                foreach (string item in selected_checkbox_tempo)
                {
                    if (item.Contains("true"))
                    {
                        string[] index = item.Split(':');
                        selected_checkboxes_list_finally.Add(index[0]);

                        //get removed item from holding removed by item's id
                        List<Holding_Item> tempo_list =
                         db.Database.SqlQuery<Holding_Item>(
                        "FPT_SP_GET_HOLDING_IDs_v1_searching_with_id {0},{1},{2},{3},{4}",
                        new object[] { index[0], "3", "0", null, null }
                        ).ToList();
                        foreach (var i in tempo_list)
                        {
                            list_data.Add(i);
                            break;
                        }
                    }
                }
                List<FPT_SP_GET_HOLDING_REMOVED_GET_COPYNUMBER_TO_INS_Result>
                    fe = new List<FPT_SP_GET_HOLDING_REMOVED_GET_COPYNUMBER_TO_INS_Result>();
                if (!string.IsNullOrEmpty(locid))
                {
                    fe = db.FPT_SP_GET_HOLDING_REMOVED_GET_COPYNUMBER_TO_INS(libid, locid).ToList();
                }

                string copy = "";
                string symbol = "";
                string numberPart = "";
                if (fe.Count != 0)
                {
                    foreach (var item in fe)
                    {
                        copy = item.CopyNumber;
                        symbol = item.Symbol;
                    }

                    Regex re = new Regex(@"([a-zA-Z]+)(\d+)");
                    Match result = re.Match(copy);

                    numberPart = result.Groups[2].Value;
                }
                else
                {
                    numberPart = "0";
                    List<SelectListItem> loc = new List<SelectListItem>();
                    foreach (var l in db.SP_HOLDING_LIBLOCUSER_SEL(42, Int32.Parse(libid)).ToList())
                    {
                        if (l.ID == Int32.Parse(locid))
                        {
                            symbol = l.Symbol;
                        }
                        loc.Add(new SelectListItem { Text = l.Symbol, Value = l.ID.ToString() });
                    }
                }
                //
                int count = 1;
                foreach (Holding_Item rm in list_data)
                {
                    string copy_number = "";
                    int x = Convert.ToInt32(numberPart);
                    int y = 10000000 + x + count;
                    if (x < 1000000)
                    {
                        copy_number = symbol + Convert.ToString(y).Substring(2);
                    }
                    else if (x > 1000000 && x < 10000000)
                    {
                        copy_number = symbol + Convert.ToString(y).Substring(1);
                    }

                    count++;
                    danh_sach_dang_ky_ca_biet.Add(rm.CopyNumber);
                    int itemid = rm.ID;
                    // kiểm nhận, lưu tại vị trí location và library hiện tại của sách
                    if (strType.Equals("0"))
                    {
                        db.FPT_SP_HOLDING_UPDATE(Convert.ToString(itemid), "", "", rm.CopyNumber, "1");
                        db.FPT_SP_HOLDING_UPDATE(Convert.ToString(itemid), "", "", rm.CopyNumber, "2"); //mo khoa 
                    }
                    // kiểm nhận sách
                    // save arcording to the new libid and loc id
                    else if (strType.Equals("1"))
                    {
                        db.FPT_SP_HOLDING_UPDATE(Convert.ToString(itemid), locid, libid, copy_number, "1");
                        db.FPT_SP_HOLDING_UPDATE(Convert.ToString(itemid), locid, libid, copy_number, "2"); //mo khoa 
                    }
                }
                ViewBag.screen_stage = "restore and unlock result";
                // inform use which item was restore
                ViewBag.selected_checkboxes_list_final = danh_sach_dang_ky_ca_biet;
            }
            // display thông thường
            else
            {
                if (string.IsNullOrEmpty(locname) || locname.Equals("Tất cả các kho."))
                {
                    get_not_checked_yet_ItemFromLibrary(libname, page_index, record_per_page);
                }
                else
                {
                    get_not_checked_yet_ItemFromLocation(locname, page_index, record_per_page);
                }
                ViewBag.record_per_page = record_per_page;
                ViewBag.page_index = page_index;
                ViewBag.screen_stage = "";
            }
            return PartialView("NotYetCheckedPartialView");
        }


        public void get_not_checked_yet_ItemFromLocation(string itemName, string page_index, string record_per_page)
        {
            //Get library list
            foreach (var jtem in db.SP_HOLDING_LIB_SEL(42).ToList())
            {
                libs.Add(new Library(jtem.ID.ToString(), jtem.Code, jtem.LibName));
            }
            ViewBag.libs = libs;


            // Get location detail for each library item
            foreach (Library lib in libs)
            {
                List<Location> locs = new List<Location>();

                foreach (var jtem in db.SP_HOLDING_LIBLOCUSER_SEL(42, Int32.Parse(lib.ID)).ToList())
                {
                    locs.Add(new Location(jtem.LOCNAME, jtem.ID.ToString(), jtem.GroupID, jtem.LibID.ToString(), jtem.Symbol, jtem.Code));
                }
                lic_locs.Add(new LibraryLocation(lib, locs));
            }

            foreach (LibraryLocation ll in lic_locs)
            {
                bool flag = false;
                // get item of a specify LOCATION of a library
                foreach (Location l in ll.locs)
                {
                    if (itemName.Equals(l.ID))
                    {
                        String libid = ll.lib.ID;
                        String locid = l.ID;
                        List<Holding_Item> list =
                        db.Database.SqlQuery<Holding_Item>(
                        "FPT_SP_GET_HOLDING_IDs_v1 {0},{1},{2},{3},{4},{5},{6}",
                        new object[] { libid, locid, null, "3", "0", page_index, record_per_page }
                        ).ToList();

                        //modify content
                        foreach (var item in list)
                        {
                            item.Content = GetContent(item.Content);
                        }

                        ViewBag.list = list;

                        // get total page amount to paging
                        int PagingAmount = getPagingAmount_not_yet_checked(record_per_page, libid, locid);
                        ViewBag.pagingamount = PagingAmount;

                        // get lib_name and loc_name to display on top of the table

                        ViewBag.LibName = ll.lib.LibName;
                        ViewBag.LocName = l.Symbol;
                        ViewBag.LibID = ll.lib.ID;
                        ViewBag.LocID = l.ID;
                        flag = true;
                        break;
                    }
                    if (flag)
                    {
                        break;
                    }
                }
            }
        }

        public void get_not_checked_yet_ItemFromLibrary(string itemName, string page_index, string record_per_page)
        {
            // get all item in a library
            List<Holding_Item> list =
            db.Database.SqlQuery<Holding_Item>(
            "FPT_SP_GET_HOLDING_IDs_v1 {0},{1},{2},{3},{4},{5},{6}",
            new object[] { itemName, null, null, "3", "0", page_index, record_per_page }
            ).ToList();

            //modify content
            foreach (var item in list)
            {
                item.Content = GetContent(item.Content);
            }

            ViewBag.list = list;

            // get total page amount to paging
            int PagingAmount = getPagingAmount_not_yet_checked(record_per_page, itemName, null);
            ViewBag.pagingamount = PagingAmount;

            // get lib_name and loc_name to display on top of the table
            if (list.Count > 0)
            {
                foreach (var item in list)
                {
                    ViewBag.LibName = item.LibName;
                    ViewBag.LibID = itemName;
                    break;
                }
            }
            ViewBag.LocName = "Tất cả các kho.";
            ViewBag.LocID = "";
        }

        public void findingItem_not_yet_checked(string find_title1, string find_code1, string find_price1,
           string find_dkcb1, string find_so_dinh_danh1, string find_volume1)
        {
            string find_title = string.IsNullOrEmpty(find_title1) ? null : Request.Form["find_title"].ToString();
            string find_code = string.IsNullOrEmpty(find_code1) ? null : Request.Form["find_code"].ToString();
            string find_price = string.IsNullOrEmpty(find_price1) ? null : Request.Form["find_price"].ToString();
            string find_dkcb = string.IsNullOrEmpty(find_dkcb1) ? null : Request.Form["find_dkcb"].ToString();
            string find_so_dinh_danh = string.IsNullOrEmpty(find_so_dinh_danh1) ? null : Request.Form["find_so_dinh_danh"].ToString();
            string find_volume = string.IsNullOrEmpty(find_volume1) ? null : Request.Form["find_volume"].ToString();

            List<Holding_Item> list =
                db.Database.SqlQuery<Holding_Item>(
                    "FPT_SP_GET_HOLDING_IDs_v1_searching {0},{1},{2},{3},{4},{5},{6},{7},{8},{9},{10}",
                    new object[] { null, null, null, find_dkcb, find_so_dinh_danh, find_volume, find_title, "3", "0", null, null }
                    ).ToList();
            //modify content
            foreach (var item in list)
            {
                item.Content = GetContent(item.Content);
            }

            foreach (Holding_Item rm in list)
            {
                ViewBag.LibName = rm.LibName;
                ViewBag.LocName = rm.LocName;
                break;
            }

            ViewBag.list = list;
            ViewBag.pagingamount = 1;
            ViewBag.page_index = "1";
            ViewBag.record_per_page = Convert.ToString(list.Count());
        }

        public int getPagingAmount_not_yet_checked(string number_per_page, String libid, String locid)
        {
            int amount_page = 0;
            List<Total_Amount> totalRecordlist =
                db.Database.SqlQuery<Total_Amount>(
                    "FPT_SP_GET_HOLDING_IDs_v1 {0},{1},{2},{3},{4},{5},{6}",
                    new object[] { libid, locid, null, "3", "1", "", "" }
                    ).ToList();
            int totalRecord = 0;

            foreach (Total_Amount ta in totalRecordlist)
            {
                totalRecord = ta.Total;
            }

            if (totalRecord != 0)
            {

                int num_per_page = Int32.Parse(number_per_page);

                if ((totalRecord % num_per_page) == 0)
                {
                    amount_page = totalRecord / num_per_page;
                }
                else
                {
                    if (totalRecord < num_per_page)
                    {
                        amount_page = 1;
                    }
                    else if (totalRecord > num_per_page)
                    {
                        amount_page = (totalRecord - (totalRecord % num_per_page)) / num_per_page + 1;
                    }
                }

            }
            return amount_page;
        }

        public List<Holding_Item> getHoldingItemToExport(string libname, string locname)
        {
            //Get library list
            foreach (var jtem in db.SP_HOLDING_LIB_SEL(42).ToList())
            {
                libs.Add(new Library(jtem.ID.ToString(), jtem.Code, jtem.LibName));
            }
            ViewBag.libs = libs;

            // Get location detail for each library item
            foreach (Library lib in libs)
            {
                List<Location> locs = new List<Location>();

                foreach (var jtem in db.SP_HOLDING_LIBLOCUSER_SEL(42, Int32.Parse(lib.ID)).ToList())
                {
                    locs.Add(new Location(jtem.LOCNAME, jtem.ID.ToString(), jtem.GroupID, jtem.LibID.ToString(), jtem.Symbol, jtem.Code));
                }
                lic_locs.Add(new LibraryLocation(lib, locs));
            }

            // Get removed_item information
            foreach (LibraryLocation ll in lic_locs)
            {
                if (string.IsNullOrEmpty(locname) || locname.Equals("Tất cả các kho."))
                {
                    // get all item from a library
                    if (libname.Equals(ll.lib.ID))
                    {
                        String libid = ll.lib.ID;
                        // get all item in a library
                        List<Holding_Item> list =
                        db.Database.SqlQuery<Holding_Item>(
                        "FPT_SP_GET_HOLDING_IDs_v1 {0},{1},{2},{3},{4},{5},{6}",
                        new object[] { libname, null, null, "0", "0", "", "" }
                        ).ToList();
                        //modify content
                        foreach (var item in list)
                        {
                            item.Content = GetContent(item.Content);
                        }
                        ViewBag.list = list;
                        return list;
                    }
                }
                else
                {
                    // get item of a specify LOCATION of a library
                    foreach (Location l in ll.locs)
                    {
                        if (locname.Equals(l.LibID))
                        {
                            String libid = ll.lib.ID;
                            String locid = l.ID;
                            List<Holding_Item> list =
                            db.Database.SqlQuery<Holding_Item>(
                            "FPT_SP_GET_HOLDING_IDs_v1 {0},{1},{2},{3},{4},{5},{6}",
                            new object[] { libid, locid, null, "0", "0", "", "" }
                            ).ToList();

                            //modify content
                            foreach (var item in list)
                            {
                                item.Content = GetContent(item.Content);
                            }
                            ViewBag.list = list;
                            return list;
                        }

                    }
                }
            }
            return null;
        }

        [AuthAttribute(ModuleID = 4, RightID = "29")]
        public ActionResult InRepository()
        {
            foreach (var item in db.SP_HOLDING_LIB_SEL(42).ToList())
            {
                int lbid = Int32.Parse(item.ID.ToString());
                Total_Amount total = null;
                List<Total_Amount> tal =
                     db.Database.SqlQuery<Total_Amount>(
                    "SP_GET_HOLDING_SUMMARY_INFOR {0},{1},{2}",
                    new object[] { lbid, 0, 0 }
                    ).ToList(); // 0 in the middle here represent locid the other is represent in repository
                foreach (var jtem in tal)
                {
                    total = jtem;
                }
                libs.Add(new Library(item.ID.ToString(), item.Code, item.LibName, total));
            }

            ViewBag.libs = libs;

            foreach (Library lib in libs)
            {
                List<Location> locs = new List<Location>();

                foreach (var item in db.SP_HOLDING_LIBLOCUSER_SEL(42, Int32.Parse(lib.ID)).ToList())
                {
                    int lbid = Int32.Parse(lib.ID.ToString());
                    int lcid = Int32.Parse(item.ID.ToString());
                    Total_Amount total = null;
                    List<Total_Amount> tal =
                        db.Database.SqlQuery<Total_Amount>(
                        "SP_GET_HOLDING_SUMMARY_INFOR {0},{1},{2}",
                        new object[] { lbid, lcid, 0 }
                        ).ToList();
                    foreach (var jtem in tal)
                    {
                        total = jtem;
                    }
                    locs.Add(new Location(item.LOCNAME, item.ID.ToString(), item.GroupID, item.LibID.ToString(), item.Symbol, item.Code, total));
                }
                lic_locs.Add(new LibraryLocation(lib, locs));
            }

            ViewBag.lic_locs = lic_locs;


            ViewBag.libs = libs;

            return View();
        }

        [HttpPost]
        public PartialViewResult InRepositoryPartialView(string libname, string locname, string page_index,
            string record_per_page, string state, string find_title, string find_code,
            string find_price, string find_dkcb, string find_so_dinh_danh, string find_volume,
            string selected_checkbox_list, string strType, string libid, string locid, string reason)
        {
            List<SelectListItem> lib = new List<SelectListItem>();
            foreach (var item in db.FPT_SP_HOLDING_LIB_SEL().ToList())
            {
                lib.Add(new SelectListItem { Text = item.Code, Value = item.ID.ToString() });
            }
            ViewBag.list_lib = lib;

            // searching book
            if (string.IsNullOrEmpty(state))
            {
                findingItem_in_repository(find_title, find_code, find_price, find_dkcb, find_so_dinh_danh, find_volume);
                ViewBag.screen_stage = "finding result";

            }
            // delete item
            else if (state == "remove item")
            {
                ViewBag.selected_checkbox_list = selected_checkbox_list;
                string selected_checkboxes = ModifyString(selected_checkbox_list);
                List<string> selected_checkbox_tempo = selected_checkboxes.Split(',').ToList();
                List<string> selected_checkboxes_list_final = new List<string>();
                List<Holding_Item> list_data = new List<Holding_Item>();

                foreach (string item in selected_checkbox_tempo)
                {
                    if (item.Contains("true"))
                    {
                        string[] index = item.Split(':');

                        List<Holding_Item> tempo_list1 =
                         db.Database.SqlQuery<Holding_Item>(
                        "FPT_SP_GET_HOLDING_IDs_v1_searching_with_id {0},{1},{2},{3},{4}",
                        new object[] { index[0], "0", "0", null, null }
                        ).ToList();
                        foreach (Holding_Item hi in tempo_list1)
                        {
                            selected_checkboxes_list_final.Add(hi.CopyNumber);
                        }

                        // insert new item to remove item table here
                        //get removed item from holding removed by item's id
                        List<Holding_Item> tempo_list =
                         db.Database.SqlQuery<Holding_Item>(
                        "FPT_SP_GET_HOLDING_IDs_v1_searching_with_id {0},{1},{2},{3},{4}",
                        new object[] { index[0], "0", "0", null, null }
                        ).ToList();
                        foreach (var i in tempo_list)
                        {
                            list_data.Add(i);
                            DateTime datenow = DateTime.Now;
                            DateTime acd = i.AcquiredDate;
                            DateTime datelastuse = i.DateLastUsed;
                            int reasonID = Int32.Parse(reason);
                            string liquidcode = "";
                            general_loc = db.FPT_SP_GET_GENERAL_LOC_INFOR_DUCNV(i.LibID, i.LocationID, null, 1).ToList();

                            foreach (var jtem in general_loc)
                            {
                                if (jtem.Type.Equals("INVENTORY"))
                                {
                                    liquidcode = jtem.VALUE;
                                }
                            }

                            db.FPT_SP_HOLDING_REMOVED_INS(i.ItemID, i.LibID, i.LocationID, i.CopyNumber, acd,
                                datenow, reasonID, i.Price,
                                i.Shelf, i.Volume, i.LoanTypeID, i.UseCount, i.POID,
                                datelastuse, i.CallNumber, i.AcquiredSourceID, liquidcode
                                );
                            break;
                        }

                        // delete item from holding
                        db.FPT_SP_HOLDING_DEL(index[0]);
                    }
                }

                ViewBag.selected_checkboxes_list_final = selected_checkboxes_list_final;
                ViewBag.screen_stage = "remove result";
            }
            // lock item
            else if (state == "restore result")
            {
                string selected_checkboxes = ModifyString(selected_checkbox_list);
                List<string> selected_checkbox_tempo = selected_checkboxes.Split(',').ToList(); // list checkbox includes checked and unchecked 
                List<string> selected_checkboxes_list_finally = new List<string>();             // list checked checkbox

                List<Holding_Item> list_data = new List<Holding_Item>();
                List<string> danh_sach_dang_ky_ca_biet = new List<string>();

                foreach (string item in selected_checkbox_tempo)
                {
                    if (item.Contains("true"))
                    {
                        string[] index = item.Split(':');
                        selected_checkboxes_list_finally.Add(index[0]);

                        //get removed item from holding removed by item's id
                        List<Holding_Item> tempo_list =
                         db.Database.SqlQuery<Holding_Item>(
                        "FPT_SP_GET_HOLDING_IDs_v1_searching_with_id {0},{1},{2},{3},{4}",
                        new object[] { index[0], "0", "0", null, null }
                        ).ToList();
                        foreach (var i in tempo_list)
                        {
                            list_data.Add(i);
                            break;
                        }
                    }
                }
                // update lai thong tin sach --- LOCK BOOOK
                foreach (Holding_Item rm in list_data)
                {
                    danh_sach_dang_ky_ca_biet.Add(rm.CopyNumber);
                    int itemid = rm.ID;
                    db.FPT_SP_HOLDING_UPDATE(Convert.ToString(itemid), "", "", rm.CopyNumber, "3"); // khoa sach
                }

                // display thong thuong
                if (string.IsNullOrEmpty(locid) || locid.Equals("Tất cả các kho."))
                {
                    get_in_repository_ItemFromLibrary(libid, page_index, record_per_page);
                    general_loc = db.FPT_SP_GET_GENERAL_LOC_INFOR_DUCNV(Int32.Parse(libid), 0, "noname", 1).ToList();
                }
                else
                {
                    get_in_repository_ItemFromLocation(locid, page_index, record_per_page);
                }
                foreach (var item in general_loc)
                {
                    if (item.Type.Equals("CountCir"))
                    {
                        ViewBag.CountCir = item.VALUE;
                    }
                    else if (item.Type.Equals("CountLocked"))
                    {
                        ViewBag.CountLocked = item.VALUE;
                    }
                    else if (item.Type.Equals("LIB"))
                    {
                        ViewBag.LibName = item.VALUE;
                    }
                    else if (item.Type.Equals("LOC"))
                    {
                        ViewBag.LocName = item.VALUE;
                    }
                    else if (item.Type.Equals("SUMCOPY"))
                    {
                        ViewBag.SUMCOPY = item.VALUE;
                    }
                    else if (item.Type.Equals("SUMITEM"))
                    {
                        ViewBag.SUMITEM = item.VALUE;
                    }
                    else if (item.Type.Equals("INVENTORY"))
                    {
                        ViewBag.INVENTORY = item.VALUE + " (" + item.OpenedDate.ToString("dd/MM/yyyy") + " - " + item.ClosedDate.ToString() + ") ";
                    }
                }
                List<SelectListItem> ta = new List<SelectListItem>();
                foreach (var item in db.SP_HOLDING_REMOVE_REASON_SEL(0).ToList())
                {
                    ta.Add(new SelectListItem { Text = item.REASON, Value = item.ID.ToString() });
                }

                ViewBag.ta = ta;

                ViewBag.record_per_page = record_per_page;
                ViewBag.page_index = page_index;
                ViewBag.screen_stage = "";
            }
            // unlock item
            else if (state == "restore and unlock result")
            {
                string selected_checkboxes = ModifyString(selected_checkbox_list);
                List<string> selected_checkbox_tempo = selected_checkboxes.Split(',').ToList(); // list checkbox includes checked and unchecked 
                List<string> selected_checkboxes_list_finally = new List<string>();             // list checked checkbox

                List<Holding_Item> list_data = new List<Holding_Item>();

                foreach (string item in selected_checkbox_tempo)
                {
                    if (item.Contains("true"))
                    {
                        string[] index = item.Split(':');
                        selected_checkboxes_list_finally.Add(index[0]);

                        //get removed item from holding removed by item's id
                        List<Holding_Item> tempo_list =
                         db.Database.SqlQuery<Holding_Item>(
                        "FPT_SP_GET_HOLDING_IDs_v1_searching_with_id {0},{1},{2},{3},{4}",
                        new object[] { index[0], "0", "0", null, null }
                        ).ToList();
                        foreach (var i in tempo_list)
                        {
                            list_data.Add(i);
                            break;
                        }
                    }
                }
                // update book information      UNLOCK BOOK
                foreach (Holding_Item rm in list_data)
                {
                    int itemid = rm.ID;
                    db.FPT_SP_HOLDING_UPDATE(Convert.ToString(itemid), "", "", rm.CopyNumber, "2"); //mo khoa 
                }


                // display thong thuong
                if (string.IsNullOrEmpty(locid) || locid.Equals("Tất cả các kho."))
                {
                    get_in_repository_ItemFromLibrary(libid, page_index, record_per_page);
                    general_loc = db.FPT_SP_GET_GENERAL_LOC_INFOR_DUCNV(Int32.Parse(libid), 0, null, 1).ToList();
                }
                else
                {
                    get_in_repository_ItemFromLocation(locid, page_index, record_per_page);
                }
                foreach (var item in general_loc)
                {
                    if (item.Type.Equals("CountCir"))
                    {
                        ViewBag.CountCir = item.VALUE;
                    }
                    else if (item.Type.Equals("CountLocked"))
                    {
                        ViewBag.CountLocked = item.VALUE;
                    }
                    else if (item.Type.Equals("LIB"))
                    {
                        ViewBag.LibName = item.VALUE;
                    }
                    else if (item.Type.Equals("LOC"))
                    {
                        ViewBag.LocName = item.VALUE;
                    }
                    else if (item.Type.Equals("SUMCOPY"))
                    {
                        ViewBag.SUMCOPY = item.VALUE;
                    }
                    else if (item.Type.Equals("SUMITEM"))
                    {
                        ViewBag.SUMITEM = item.VALUE;
                    }
                    else if (item.Type.Equals("INVENTORY"))
                    {
                        ViewBag.INVENTORY = item.VALUE + " (" + item.OpenedDate.ToString("dd/MM/yyyy") + " - " + item.ClosedDate.ToString() + ") ";
                    }
                }
                List<SelectListItem> ta = new List<SelectListItem>();
                foreach (var item in db.SP_HOLDING_REMOVE_REASON_SEL(0).ToList())
                {
                    ta.Add(new SelectListItem { Text = item.REASON, Value = item.ID.ToString() });
                }

                ViewBag.ta = ta;

                ViewBag.record_per_page = record_per_page;
                ViewBag.page_index = page_index;
                ViewBag.screen_stage = "";
            }
            // cacel item
            else if (state == "cancel item") { }
            // display thông thường
            else
            {
                if (string.IsNullOrEmpty(locname) || locname.Equals("Tất cả các kho."))
                {
                    get_in_repository_ItemFromLibrary(libname, page_index, record_per_page);
                    general_loc = db.FPT_SP_GET_GENERAL_LOC_INFOR_DUCNV(Int32.Parse(libname), 0, null, 1).ToList();
                }
                else
                {
                    get_in_repository_ItemFromLocation(locname, page_index, record_per_page);
                }
                foreach (var item in general_loc)
                {
                    if (item.Type.Equals("CountCir"))
                    {
                        ViewBag.CountCir = item.VALUE;
                    }
                    else if (item.Type.Equals("CountLocked"))
                    {
                        ViewBag.CountLocked = item.VALUE;
                    }
                    else if (item.Type.Equals("LIB"))
                    {
                        ViewBag.LibName = item.VALUE;
                    }
                    else if (item.Type.Equals("LOC"))
                    {
                        ViewBag.LocName = item.VALUE;
                    }
                    else if (item.Type.Equals("SUMCOPY"))
                    {
                        ViewBag.SUMCOPY = item.VALUE;
                    }
                    else if (item.Type.Equals("SUMITEM"))
                    {
                        ViewBag.SUMITEM = item.VALUE;
                    }
                    else if (item.Type.Equals("INVENTORY"))
                    {
                        ViewBag.INVENTORY = item.VALUE + " (" + item.OpenedDate.ToString("dd/MM/yyyy") + " - " + item.ClosedDate.ToString() + ") ";
                    }
                }
                List<SelectListItem> ta = new List<SelectListItem>();
                foreach (var item in db.SP_HOLDING_REMOVE_REASON_SEL(0).ToList())
                {
                    ta.Add(new SelectListItem { Text = item.REASON, Value = item.ID.ToString() });
                }

                ViewBag.ta = ta;

                ViewBag.record_per_page = record_per_page;
                ViewBag.page_index = page_index;
                ViewBag.screen_stage = "";
            }
            return PartialView("InRepositoryPartialView");
        }

        public int getPagingAmount_in_repository(string number_per_page, String libid, String locid)
        {
            int amount_page = 0;
            List<Total_Amount> totalRecordlist =
                db.Database.SqlQuery<Total_Amount>(
                    "FPT_SP_GET_HOLDING_IDs_v1 {0},{1},{2},{3},{4},{5},{6}",
                    new object[] { libid, locid, null, "0", "1", "", "" }
                    ).ToList();
            int totalRecord = 0;

            foreach (Total_Amount ta in totalRecordlist)
            {
                totalRecord = ta.Total;
            }

            if (totalRecord != 0)
            {

                int num_per_page = Int32.Parse(number_per_page);

                if ((totalRecord % num_per_page) == 0)
                {
                    amount_page = totalRecord / num_per_page;
                }
                else
                {
                    if (totalRecord < num_per_page)
                    {
                        amount_page = 1;
                    }
                    else if (totalRecord > num_per_page)
                    {
                        amount_page = (totalRecord - (totalRecord % num_per_page)) / num_per_page + 1;
                    }
                }

            }
            return amount_page;
        }

        public void findingItem_in_repository(string find_title1, string find_code1, string find_price1,
            string find_dkcb1, string find_so_dinh_danh1, string find_volume1)
        {
            string find_title = string.IsNullOrEmpty(find_title1) ? null : Request.Form["find_title"].ToString();
            //string find_code = string.IsNullOrEmpty(find_code1) ? null : Request.Form["find_code"].ToString();
            //string find_price = string.IsNullOrEmpty(find_price1) ? null : Request.Form["find_price"].ToString();
            string find_dkcb = string.IsNullOrEmpty(find_dkcb1) ? null : Request.Form["find_dkcb"].ToString();
            string find_so_dinh_danh = string.IsNullOrEmpty(find_so_dinh_danh1) ? null : Request.Form["find_so_dinh_danh"].ToString();
            string find_volume = string.IsNullOrEmpty(find_volume1) ? null : Request.Form["find_volume"].ToString();

            List<Holding_Item> list = new List<Holding_Item>();
            if (string.IsNullOrEmpty(find_title1) && string.IsNullOrEmpty(find_dkcb1)
                && string.IsNullOrEmpty(find_so_dinh_danh1) && string.IsNullOrEmpty(find_volume1))
            {

            }
            else
            {
                list =
                db.Database.SqlQuery<Holding_Item>(
                    "FPT_SP_GET_HOLDING_IDs_v1_searching {0},{1},{2},{3},{4},{5},{6},{7},{8},{9},{10}",
                    new object[] { null, null, null, find_dkcb, find_so_dinh_danh, find_volume, find_title, "0", "0", null, null }
                    ).ToList();
            }

            if (list.Count != 0)
            {
                //modify content
                foreach (var item in list)
                {
                    item.Content = GetContent(item.Content);
                }
                foreach (Holding_Item rm in list)
                {
                    ViewBag.LibName = rm.LibName;
                    ViewBag.LocName = rm.LocName;
                    break;
                }
            }
            else
            {
                ViewBag.LibName = "";
                ViewBag.LocName = "";
            }

            ViewBag.CountCir = "";
            ViewBag.CountLocked = "";
            ViewBag.LibName = "";
            ViewBag.LocName = "";
            ViewBag.SUMCOPY = "";
            ViewBag.SUMITEM = "";
            ViewBag.INVENTORY = "";
            List<SelectListItem> ta = new List<SelectListItem>();
            foreach (var item in db.SP_HOLDING_REMOVE_REASON_SEL(0).ToList())
            {
                ta.Add(new SelectListItem { Text = item.REASON, Value = item.ID.ToString() });
            }

            ViewBag.ta = ta;


            ViewBag.list = list;
            ViewBag.pagingamount = 1;
            ViewBag.page_index = "1";
            ViewBag.record_per_page = Convert.ToString(list.Count());
        }


        public void get_in_repository_ItemFromLocation(string itemName, string page_index, string record_per_page)
        {
            //Get library list
            foreach (var jtem in db.SP_HOLDING_LIB_SEL(42).ToList())
            {
                libs.Add(new Library(jtem.ID.ToString(), jtem.Code, jtem.LibName));
            }
            ViewBag.libs = libs;


            // Get location detail for each library item
            foreach (Library lib in libs)
            {
                List<Location> locs = new List<Location>();

                foreach (var jtem in db.SP_HOLDING_LIBLOCUSER_SEL(42, Int32.Parse(lib.ID)).ToList())
                {
                    locs.Add(new Location(jtem.LOCNAME, jtem.ID.ToString(), jtem.GroupID, jtem.LibID.ToString(), jtem.Symbol, jtem.Code));
                }
                lic_locs.Add(new LibraryLocation(lib, locs));
            }

            foreach (LibraryLocation ll in lic_locs)
            {
                bool flag = false;
                // get item of a specify LOCATION of a library
                foreach (Location l in ll.locs)
                {
                    if (itemName.Equals(l.ID))
                    {
                        String libid = ll.lib.ID;
                        String locid = l.ID;
                        List<Holding_Item> list =
                        db.Database.SqlQuery<Holding_Item>(
                        "FPT_SP_GET_HOLDING_IDs_v1 {0},{1},{2},{3},{4},{5},{6}",
                        new object[] { libid, locid, null, "0", "0", page_index, record_per_page }
                        ).ToList();

                        //modify content
                        foreach (var item in list)
                        {
                            item.Content = GetContent(item.Content);
                        }

                        ViewBag.list = list;

                        // get total page amount to paging
                        int PagingAmount = getPagingAmount_in_repository(record_per_page, libid, locid);
                        ViewBag.pagingamount = PagingAmount;

                        // get lib_name and loc_name to display on top of the table

                        ViewBag.LibName = ll.lib.LibName;
                        ViewBag.LocName = l.Symbol;
                        ViewBag.LibID = ll.lib.ID;
                        ViewBag.LocID = l.ID;

                        //
                        general_loc = db.FPT_SP_GET_GENERAL_LOC_INFOR_DUCNV(Int32.Parse(ll.lib.ID), Int32.Parse(l.ID), "noname", 1).ToList();

                        flag = true;
                        break;
                    }
                    if (flag)
                    {
                        break;
                    }
                }
            }
        }

        public void get_in_repository_ItemFromLibrary(string itemName, string page_index, string record_per_page)
        {
            // get all item in a library
            List<Holding_Item> list =
            db.Database.SqlQuery<Holding_Item>(
            "FPT_SP_GET_HOLDING_IDs_v1 {0},{1},{2},{3},{4},{5},{6}",
            new object[] { itemName, null, null, "0", "0", page_index, record_per_page }
            ).ToList();

            //modify content
            foreach (var item in list)
            {
                item.Content = GetContent(item.Content);
            }

            ViewBag.list = list;

            // get total page amount to paging
            int PagingAmount = getPagingAmount_in_repository(record_per_page, itemName, null);
            ViewBag.pagingamount = PagingAmount;

            // get lib_name and loc_name to display on top of the table
            if (list.Count > 0)
            {
                foreach (var item in list)
                {
                    ViewBag.LibName = item.LibName;
                    ViewBag.LibID = itemName;
                    break;
                }
            }
            ViewBag.LocName = "Tất cả các kho.";
            ViewBag.LocID = "";
        }

        public List<Holding_Item> getInRepositoryItemToExport(string libname, string locname)
        {
            //Get library list
            foreach (var jtem in db.SP_HOLDING_LIB_SEL(42).ToList())
            {
                libs.Add(new Library(jtem.ID.ToString(), jtem.Code, jtem.LibName));
            }
            ViewBag.libs = libs;

            // Get location detail for each library item
            foreach (Library lib in libs)
            {
                List<Location> locs = new List<Location>();

                foreach (var jtem in db.SP_HOLDING_LIBLOCUSER_SEL(42, Int32.Parse(lib.ID)).ToList())
                {
                    locs.Add(new Location(jtem.LOCNAME, jtem.ID.ToString(), jtem.GroupID, jtem.LibID.ToString(), jtem.Symbol, jtem.Code));
                }
                lic_locs.Add(new LibraryLocation(lib, locs));
            }

            // Get removed_item information
            foreach (LibraryLocation ll in lic_locs)
            {
                if (string.IsNullOrEmpty(locname) || locname.Equals("Tất cả các kho."))
                {
                    // get all item from a library
                    if (libname.Equals(ll.lib.ID))
                    {
                        String libid = ll.lib.ID;
                        // get all item in a library
                        List<Holding_Item> list =
                        db.Database.SqlQuery<Holding_Item>(
                        "FPT_SP_GET_HOLDING_IDs_v1 {0},{1},{2},{3},{4},{5},{6}",
                        new object[] { libname, null, null, "0", "0", "", "" }
                        ).ToList();
                        //modify content
                        foreach (var item in list)
                        {
                            item.Content = GetContent(item.Content);
                        }
                        ViewBag.list = list;
                        return list;
                    }
                }
                else
                {
                    // get item of a specify LOCATION of a library
                    foreach (Location l in ll.locs)
                    {
                        if (locname.Equals(l.ID))
                        {
                            String libid = ll.lib.ID;
                            String locid = l.ID;
                            List<Holding_Item> list =
                            db.Database.SqlQuery<Holding_Item>(
                            "FPT_SP_GET_HOLDING_IDs_v1 {0},{1},{2},{3},{4},{5},{6}",
                            new object[] { libid, locid, null, "0", "0", "", "" }
                            ).ToList();

                            //modify content
                            foreach (var item in list)
                            {
                                item.Content = GetContent(item.Content);
                            }
                            ViewBag.list = list;
                            return list;
                        }

                    }
                }
            }
            return null;
        }


        public void getRemovedItemFromLocation(string itemName, string page_index, string record_per_page)
        {
            //Get library list
            foreach (var jtem in db.SP_HOLDING_LIB_SEL(42).ToList())
            {
                libs.Add(new Library(jtem.ID.ToString(), jtem.Code, jtem.LibName));
            }
            ViewBag.libs = libs;

            // Get location detail for each library item
            foreach (Library lib in libs)
            {
                List<Location> locs = new List<Location>();

                foreach (var jtem in db.SP_HOLDING_LIBLOCUSER_SEL(42, Int32.Parse(lib.ID)).ToList())
                {
                    locs.Add(new Location(jtem.LOCNAME, jtem.ID.ToString(), jtem.GroupID, jtem.LibID.ToString(), jtem.Symbol, jtem.Code));
                }
                lic_locs.Add(new LibraryLocation(lib, locs));
            }

            foreach (LibraryLocation ll in lic_locs)
            {
                bool flag = false;
                // get item of a specify LOCATION of a library
                foreach (Location l in ll.locs)
                {
                    if (itemName.Equals(l.Symbol))
                    {
                        String libid = ll.lib.ID;
                        String locid = l.ID;
                        List<Removed_Item> list =
                        db.Database.SqlQuery<Removed_Item>(
                        "FPT_SP_GET_HOLDING_REMOVED_PAGING_v2 {0},{1},{2},{3},{4},{5},{6},{7},{8}",
                        new object[] { libid, locid, null, null, null, null, null, page_index, record_per_page }
                        ).ToList();

                        //modify content
                        foreach (var item in list)
                        {
                            item.Content = GetContent(item.Content);
                        }

                        ViewBag.list = list;

                        // get total page amount to paging
                        int PagingAmount = getPagingAmount(record_per_page, libid, locid);
                        ViewBag.pagingamount = PagingAmount;

                        // get lib_name and loc_name to display on top of the table
                        foreach (Removed_Item rm in list)
                        {
                            ViewBag.LibName = rm.LibName;
                            ViewBag.LocName = rm.LocName;
                            break;
                        }
                        flag = true;
                        break;
                    }
                    if (flag)
                    {
                        break;
                    }
                }
            }
        }

        public void getRemovedItemFromLibrary(string itemName, string page_index, string record_per_page)
        {
            //Get library list
            foreach (var jtem in db.SP_HOLDING_LIB_SEL(42).ToList())
            {
                libs.Add(new Library(jtem.ID.ToString(), jtem.Code, jtem.LibName));
            }
            ViewBag.libs = libs;

            // Get location detail for each library item
            foreach (Library lib in libs)
            {
                List<Location> locs = new List<Location>();

                foreach (var jtem in db.SP_HOLDING_LIBLOCUSER_SEL(42, Int32.Parse(lib.ID)).ToList())
                {
                    locs.Add(new Location(jtem.LOCNAME, jtem.ID.ToString(), jtem.GroupID, jtem.LibID.ToString(), jtem.Symbol, jtem.Code));
                }
                lic_locs.Add(new LibraryLocation(lib, locs));
            }

            // Get removed_item information with specific location detail
            foreach (LibraryLocation ll in lic_locs)
            {
                // get all item in a library
                if (itemName.Equals(ll.lib.Code))
                {
                    String libid = ll.lib.ID;
                    List<Removed_Item> list =
                    db.Database.SqlQuery<Removed_Item>(
                    "FPT_SP_GET_HOLDING_REMOVED_PAGING_v2 {0},{1},{2},{3},{4},{5},{6},{7},{8}",
                    new object[] { libid, null, null, null, null, null, null, page_index, record_per_page }
                    ).ToList();

                    //modify content
                    foreach (var item in list)
                    {
                        item.Content = GetContent(item.Content);
                    }

                    ViewBag.list = list;

                    // get total page amount to paging
                    int PagingAmount = getPagingAmount(record_per_page, libid, null);
                    ViewBag.pagingamount = PagingAmount;

                    // get lib_name and loc_name to display on top of the table
                    foreach (Removed_Item rm in list)
                    {
                        ViewBag.LibName = rm.LibName;
                        ViewBag.LocName = "Tất cả các kho.";
                        break;
                    }
                    break;
                }
            }
        }

        public int getPagingAmount(string number_per_page, String libid, String locid)
        {
            int amount_page = 0;
            List<Total_Amount> totalRecordlist = db.Database.SqlQuery<Total_Amount>(
                "FPT_SP_GET_HOLDING_REMOVED_TOTAL_AMOUNT {0},{1},{2},{3},{4},{5},{6}",
                            new object[] { libid, locid, null, null, null, null, null }
                ).ToList();
            int totalRecord = 0;

            foreach (Total_Amount ta in totalRecordlist)
            {
                totalRecord = ta.Total;
            }

            if (totalRecord != 0)
            {

                int num_per_page = Int32.Parse(number_per_page);

                if ((totalRecord % num_per_page) == 0)
                {
                    amount_page = totalRecord / num_per_page;
                }
                else
                {
                    if (totalRecord < num_per_page)
                    {
                        amount_page = 1;
                    }
                    else if (totalRecord > num_per_page)
                    {
                        amount_page = (totalRecord - (totalRecord % num_per_page)) / num_per_page + 1;
                    }
                }

            }
            return amount_page;
        }

        public List<Removed_Item> getRemoveItemToExport(string libname, string locname)
        {
            //Get library list
            foreach (var jtem in db.SP_HOLDING_LIB_SEL(42).ToList())
            {
                libs.Add(new Library(jtem.ID.ToString(), jtem.Code, jtem.LibName));
            }
            ViewBag.libs = libs;

            // Get location detail for each library item
            foreach (Library lib in libs)
            {
                List<Location> locs = new List<Location>();

                foreach (var jtem in db.SP_HOLDING_LIBLOCUSER_SEL(42, Int32.Parse(lib.ID)).ToList())
                {
                    locs.Add(new Location(jtem.LOCNAME, jtem.ID.ToString(), jtem.GroupID, jtem.LibID.ToString(), jtem.Symbol, jtem.Code));
                }
                lic_locs.Add(new LibraryLocation(lib, locs));
            }

            // Get removed_item information
            foreach (LibraryLocation ll in lic_locs)
            {
                if (string.IsNullOrEmpty(locname) || locname.Equals("Tất cả các kho."))
                {
                    // get all item from a library
                    if (libname.Equals(ll.lib.Code))
                    {
                        String libid = ll.lib.ID;
                        List<Removed_Item> list =
                            db.Database.SqlQuery<Removed_Item>(
                            "FPT_SP_GET_HOLDING_REMOVED {0},{1},{2},{3},{4},{5},{6},{7},{8},{9},{10},{11},{12}",
                            new object[] { libid, null, null, null, null, null, null, null, null, null, null, "-1", "-1" }
                        ).ToList();

                        //modify content
                        foreach (var item in list)
                        {
                            item.Content = GetContent(item.Content);
                        }
                        ViewBag.list = list;
                        return list;
                    }
                }
                else
                {
                    // get item of a specify LOCATION of a library
                    foreach (Location l in ll.locs)
                    {
                        if (locname.Equals(l.Symbol))
                        {
                            String libid = ll.lib.ID;
                            String locid = l.ID;
                            List<Removed_Item> list =
                            db.Database.SqlQuery<Removed_Item>(
                            "FPT_SP_GET_HOLDING_REMOVED {0},{1},{2},{3},{4},{5},{6},{7},{8},{9},{10},{11},{12}",
                            new object[] { libid, locid, null, null, null, null, null, null, null, null, null, "-1", "-1" }
                            ).ToList();
                            //modify content
                            foreach (var item in list)
                            {
                                item.Content = GetContent(item.Content);
                            }
                            ViewBag.list = list;
                            return list;
                        }

                    }
                }
            }
            return null;
        }


        //GET LOCATIONS BY LIBRARY
        public JsonResult GetLocations(int id)
        {
            List<SelectListItem> loc = new List<SelectListItem>();
            loc.Add(new SelectListItem { Text = "All", Value = "-1" });
            foreach (var l in db.SP_HOLDING_LIBLOCUSER_SEL(42, id).ToList())
            {
                loc.Add(new SelectListItem { Text = l.Symbol, Value = l.ID.ToString() });
            }
            return Json(new SelectList(loc, "Value", "Text"));
        }
        //GET LOCATIONS BY LIBRARY
        public JsonResult GetLocation(int id)
        {
            List<SelectListItem> loc = new List<SelectListItem>();
            foreach (var l in db.FPT_SP_HOLDING_LIBLOCUSER_SEL(id).ToList())
            {
                loc.Add(new SelectListItem { Text = l.Symbol, Value = l.ID.ToString() });
            }
            return Json(new SelectList(loc, "Value", "Text"));
        }
        // customize data 
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
        public string ModifyString(string str)
        {
            string result = Regex.Replace(str, "\"", "");
            result = Regex.Replace(result, "\\{", "");
            result = Regex.Replace(result, "\\\\", "");
            result = Regex.Replace(result, "\\}", "");
            result = Regex.Replace(result, " ", "");

            return result;
        }
        [HttpPost]
        public ActionResult ExcelExport(string locname, string libname)
        {
            List<Removed_Item> list = null;
            if (locname == null || locname.Equals("Tất cả các kho."))
            {
                list = getRemoveItemToExport(libname, "");
            }
            else
            {
                list = getRemoveItemToExport(libname, locname);
            }

            try
            {
                DataTable Dt = new DataTable();
                Dt.Columns.Add("Thư Viện", typeof(string));
                Dt.Columns.Add("Kho", typeof(string));
                Dt.Columns.Add("Đăng Ký Cá Biệt", typeof(string));
                Dt.Columns.Add("Số Định Danh", typeof(string));
                Dt.Columns.Add("Tập", typeof(string));
                Dt.Columns.Add("Thông tin chi tiết", typeof(string));
                Dt.Columns.Add("Ngày Bổ sung", typeof(DateTime));
                Dt.Columns.Add("Giá tiền", typeof(decimal));
                Dt.Columns.Add("Lý Do", typeof(string));
                Dt.Columns.Add("Ngày ghi nhận mất", typeof(DateTime));
                Dt.Columns.Add("Ngày mượn cuối", typeof(DateTime));
                Dt.Columns.Add("Số lượt mượn", typeof(int));

                foreach (var v in list)
                {
                    DataRow row = Dt.NewRow();
                    row[0] = v.LibName;
                    row[1] = v.LocName;
                    row[2] = v.CopyNumber;
                    row[3] = v.CallNumber;
                    row[4] = v.Volume;
                    row[5] = v.Content;
                    row[6] = v.AcquiredDate;
                    row[7] = v.Price;
                    row[8] = v.Reson_detail;
                    row[9] = v.RemovedDate;
                    row[10] = v.DateLastUsed;
                    row[11] = v.UseCount;
                    Dt.Rows.Add(row);

                }

                var memoryStream = new MemoryStream();
                using (var excelPackage = new ExcelPackage(memoryStream))
                {
                    var worksheet = excelPackage.Workbook.Worksheets.Add("Sheet1");
                    worksheet.Cells["A1"].LoadFromDataTable(Dt, true, TableStyles.None);
                    worksheet.Cells["A1:AN1"].Style.Font.Bold = true;
                    worksheet.DefaultRowHeight = 18;

                    worksheet.Column(1).Style.HorizontalAlignment = OfficeOpenXml.Style.ExcelHorizontalAlignment.Center;
                    worksheet.Column(2).Style.HorizontalAlignment = OfficeOpenXml.Style.ExcelHorizontalAlignment.Center;
                    worksheet.Column(3).Style.HorizontalAlignment = OfficeOpenXml.Style.ExcelHorizontalAlignment.Center;
                    worksheet.Column(4).Style.HorizontalAlignment = OfficeOpenXml.Style.ExcelHorizontalAlignment.Center;
                    worksheet.Column(5).Style.HorizontalAlignment = OfficeOpenXml.Style.ExcelHorizontalAlignment.Center;
                    worksheet.Column(6).Style.HorizontalAlignment = OfficeOpenXml.Style.ExcelHorizontalAlignment.Left;
                    worksheet.Column(7).Style.HorizontalAlignment = OfficeOpenXml.Style.ExcelHorizontalAlignment.Center;
                    worksheet.Column(8).Style.HorizontalAlignment = OfficeOpenXml.Style.ExcelHorizontalAlignment.Center;
                    worksheet.Column(9).Style.HorizontalAlignment = OfficeOpenXml.Style.ExcelHorizontalAlignment.Center;
                    worksheet.Column(10).Style.HorizontalAlignment = OfficeOpenXml.Style.ExcelHorizontalAlignment.Center;
                    worksheet.Column(11).Style.HorizontalAlignment = OfficeOpenXml.Style.ExcelHorizontalAlignment.Center;
                    worksheet.Column(12).Style.HorizontalAlignment = OfficeOpenXml.Style.ExcelHorizontalAlignment.Center;

                    worksheet.Column(7).Style.Numberformat.Format = "dd/MM/yyyy";
                    worksheet.Column(10).Style.Numberformat.Format = "dd/MM/yyyy";
                    worksheet.Column(11).Style.Numberformat.Format = "dd/MM/yyyy";

                    worksheet.Column(7).AutoFit();
                    worksheet.Column(10).AutoFit();
                    worksheet.Column(11).AutoFit();

                    worksheet.DefaultColWidth = 20;
                    worksheet.Column(6).AutoFit();

                    Session["DownloadExcel_FileManager"] = excelPackage.GetAsByteArray();
                    return Json("", JsonRequestBehavior.AllowGet);
                }
            }
            catch (Exception ex)
            {
                throw;
            }


        }
        [HttpPost]
        public ActionResult ExcelExportForNotYetChecked(string locname, string libname)
        {
            List<Holding_Item> list = null;
            if (string.IsNullOrEmpty(locname) || locname.Equals("Tất cả các kho."))
            {
                list = getHoldingItemToExport(libname, "");
            }
            else
            {
                list = getHoldingItemToExport(libname, locname);
            }
            DataTable Dt = new DataTable();
            Dt.Columns.Add("STT", typeof(int));
            Dt.Columns.Add("Đăng Ký Cá Biệt", typeof(string));
            Dt.Columns.Add("Số Định Danh", typeof(string));
            Dt.Columns.Add("Tập", typeof(string));
            Dt.Columns.Add("Thông tin chi tiết", typeof(string));
            Dt.Columns.Add("Ngày Bổ sung", typeof(DateTime));
            Dt.Columns.Add("Giá tiền", typeof(decimal));
            Dt.Columns.Add("Số lượt mượn", typeof(int));
            foreach (var v in list)
            {
                DataRow row = Dt.NewRow();
                row[0] = v.Seq;
                row[1] = v.CopyNumber;
                row[2] = v.CallNumber;
                row[3] = v.Volume;
                row[4] = GetContent(v.Content);
                row[5] = v.AcquiredDate;
                row[6] = v.Price;
                row[7] = v.UseCount;
                Dt.Rows.Add(row);

            }

            var memoryStream = new MemoryStream();
            using (var excelPackage = new ExcelPackage(memoryStream))
            {
                var worksheet = excelPackage.Workbook.Worksheets.Add("Sheet1");
                worksheet.Cells["A1"].LoadFromDataTable(Dt, true, TableStyles.None);
                worksheet.Cells["A1:AN1"].Style.Font.Bold = true;
                worksheet.DefaultRowHeight = 18;

                worksheet.Column(1).Style.HorizontalAlignment = OfficeOpenXml.Style.ExcelHorizontalAlignment.Center;
                worksheet.Column(2).Style.HorizontalAlignment = OfficeOpenXml.Style.ExcelHorizontalAlignment.Center;
                worksheet.Column(3).Style.HorizontalAlignment = OfficeOpenXml.Style.ExcelHorizontalAlignment.Center;
                worksheet.Column(4).Style.HorizontalAlignment = OfficeOpenXml.Style.ExcelHorizontalAlignment.Center;
                worksheet.Column(5).Style.HorizontalAlignment = OfficeOpenXml.Style.ExcelHorizontalAlignment.Left;
                worksheet.Column(6).Style.HorizontalAlignment = OfficeOpenXml.Style.ExcelHorizontalAlignment.Center;
                worksheet.Column(7).Style.HorizontalAlignment = OfficeOpenXml.Style.ExcelHorizontalAlignment.Center;
                worksheet.Column(8).Style.HorizontalAlignment = OfficeOpenXml.Style.ExcelHorizontalAlignment.Center;
                worksheet.DefaultColWidth = 20;
                worksheet.Column(5).AutoFit();

                worksheet.Column(6).Style.Numberformat.Format = "dd/MM/yyyy";

                worksheet.Column(6).AutoFit();


                Session["DownloadExcel_FileManager"] = excelPackage.GetAsByteArray();
                return Json("", JsonRequestBehavior.AllowGet);
            }


        }
        [HttpPost]
        public ActionResult ExcelExportForInRepository(string locname, string libname)
        {
            List<Holding_Item> list = null;
            if (string.IsNullOrEmpty(locname) || locname.Equals("Tất cả các kho."))
            {
                list = getInRepositoryItemToExport(libname, "");
            }
            else
            {
                list = getInRepositoryItemToExport(libname, locname);
            }
            DataTable Dt = new DataTable();
            Dt.Columns.Add("STT", typeof(int));
            Dt.Columns.Add("Thư Viện", typeof(string));
            Dt.Columns.Add("Kho", typeof(string));
            Dt.Columns.Add("Đăng Ký Cá Biệt", typeof(string));
            Dt.Columns.Add("Số Định Danh", typeof(string));
            Dt.Columns.Add("Tập", typeof(string));
            Dt.Columns.Add("Thông tin chi tiết", typeof(string));
            Dt.Columns.Add("Ngày Bổ sung", typeof(DateTime));
            Dt.Columns.Add("Giá tiền", typeof(decimal));
            Dt.Columns.Add("Số lượt mượn", typeof(int));
            Dt.Columns.Add("Ngày mượn cuối", typeof(DateTime));
            Dt.Columns.Add("Ghi chú", typeof(string));
            foreach (var v in list)
            {
                DataRow row = Dt.NewRow();
                row[0] = v.Seq;
                row[1] = v.LibName;
                row[2] = v.LocName;
                row[3] = v.CopyNumber;
                row[4] = v.CallNumber;
                row[5] = v.Volume;
                row[6] = v.Content;
                row[7] = v.AcquiredDate;
                row[8] = v.Price;
                row[9] = v.UseCount;
                row[10] = v.DateLastUsed;
                row[11] = v.Note;
                Dt.Rows.Add(row);
            }

            var memoryStream = new MemoryStream();
            using (var excelPackage = new ExcelPackage(memoryStream))
            {
                var worksheet = excelPackage.Workbook.Worksheets.Add("Sheet1");
                worksheet.Cells["A1"].LoadFromDataTable(Dt, true, TableStyles.None);
                worksheet.Cells["A1:AN1"].Style.Font.Bold = true;
                worksheet.DefaultRowHeight = 18;

                worksheet.Column(1).Style.HorizontalAlignment = OfficeOpenXml.Style.ExcelHorizontalAlignment.Center;
                worksheet.Column(2).Style.HorizontalAlignment = OfficeOpenXml.Style.ExcelHorizontalAlignment.Center;
                worksheet.Column(3).Style.HorizontalAlignment = OfficeOpenXml.Style.ExcelHorizontalAlignment.Center;
                worksheet.Column(4).Style.HorizontalAlignment = OfficeOpenXml.Style.ExcelHorizontalAlignment.Center;
                worksheet.Column(5).Style.HorizontalAlignment = OfficeOpenXml.Style.ExcelHorizontalAlignment.Center;
                worksheet.Column(6).Style.HorizontalAlignment = OfficeOpenXml.Style.ExcelHorizontalAlignment.Center;
                worksheet.Column(7).Style.HorizontalAlignment = OfficeOpenXml.Style.ExcelHorizontalAlignment.Left;
                worksheet.Column(8).Style.HorizontalAlignment = OfficeOpenXml.Style.ExcelHorizontalAlignment.Center;
                worksheet.Column(9).Style.HorizontalAlignment = OfficeOpenXml.Style.ExcelHorizontalAlignment.Center;
                worksheet.Column(10).Style.HorizontalAlignment = OfficeOpenXml.Style.ExcelHorizontalAlignment.Center;
                worksheet.Column(11).Style.HorizontalAlignment = OfficeOpenXml.Style.ExcelHorizontalAlignment.Center;
                worksheet.Column(12).Style.HorizontalAlignment = OfficeOpenXml.Style.ExcelHorizontalAlignment.Center;
                worksheet.DefaultColWidth = 20;
                worksheet.Column(5).AutoFit();

                worksheet.Column(8).Style.Numberformat.Format = "dd/MM/yyyy";
                worksheet.Column(11).Style.Numberformat.Format = "dd/MM/yyyy";

                worksheet.Column(8).AutoFit();
                worksheet.Column(11).AutoFit();


                Session["DownloadExcel_FileManager"] = excelPackage.GetAsByteArray();
                return Json("", JsonRequestBehavior.AllowGet);
            }
        }
        public ActionResult Download()
        {

            if (Session["DownloadExcel_FileManager"] != null)
            {
                byte[] data = Session["DownloadExcel_FileManager"] as byte[];
                return File(data, "application/octet-stream", "FileManager.xlsx");
            }
            else
            {
                return new EmptyResult();
            }
        }









    }

    public class HoldingStatus
    {
        public int HoldingID { get; set; }
        public int LibID { get; set; }
        public int LocID { get; set; }
        public string Shelf { get; set; }
        public int Mode { get; set; }
        public int IsNew { get; set; }
    }

    public class HoldingTable
    {
        public int ID { get; set; }
        public int LibID { get; set; }
        public int LocID { get; set; }
        public string Library { get; set; }
        public string Location { get; set; }
        public string Shelf { get; set; }
        public string Volume { get; set; }
        public string CallNumber { get; set; }
        public string CopyNumber { get; set; }
        public float? Price { get; set; }
        public string Currency { get; set; }
        public string RecordNumber { get; set; }
        public string ReceiptedDate { get; set; }
        public string AcquiredDate { get; set; }
        public string AcquiredSource { get; set; }
        public string Note { get; set; }
        public string Status { get; set; }


    }


    public class Holding_Item
    {
        public Int64 Seq { get; set; }
        public bool Acquired { get; set; }
        public int ID { get; set; }
        public int LibID { get; set; }
        public int LocationID { get; set; }
        public string Content { get; set; }
        public string Volume { get; set; }
        public DateTime AcquiredDate { get; set; }
        public string CopyNumber { get; set; }
        public string CallNumber { get; set; }
        public string Shelf { get; set; }
        public bool InUsed { get; set; }
        public bool InCirculation { get; set; }
        public string Note { get; set; }

        public DateTime DateLastUsed { get; set; }
        public Single Price { get; set; }
        public int UseCount { get; set; }
        public string LibName { get; set; }
        public string LocName { get; set; }
        public int LoanTypeID { get; set; }
        public int ItemID { get; set; }
        public int? POID { get; set; }
        public int? AcquiredSourceID { get; set; }
    }


    public class Library
    {

        public string ID { get; set; }
        public string LibName { get; set; }
        public string Code { get; set; }
        public Total_Amount Total { get; set; }

        public Library(string ID, string Code, string LibName)
        {
            this.ID = ID;
            this.LibName = LibName;
            this.Code = Code;
        }
        public Library(string ID, string Code, string LibName, Total_Amount Total)
        {
            this.ID = ID;
            this.LibName = LibName;
            this.Code = Code;
            this.Total = Total;
        }

    }


    public class LibraryLocation
    {
        public Library lib { get; set; }
        public List<Location> locs { get; set; }

        public LibraryLocation(Library lib, List<Location> locs)
        {
            this.lib = lib;
            this.locs = locs;
        }

    }


    public class Location
    {
        public string LOCNAME { get; set; }
        public string ID { get; set; }
        public string GroupID { get; set; }
        public string LibID { get; set; }
        public string Symbol { get; set; }
        public string Code { get; set; }

        public Total_Amount Total { get; set; }

        public Location(string LOCNAME, string ID, string GroupID,
            string LibID, string Symbol, string Code)
        {
            this.LOCNAME = LOCNAME;
            this.ID = ID;
            this.GroupID = GroupID;
            this.LibID = LibID;
            this.Symbol = Symbol;
            this.Code = Code;
        }
        public Location(string LOCNAME, string ID, string GroupID,
            string LibID, string Symbol, string Code, Total_Amount Total)
        {
            this.LOCNAME = LOCNAME;
            this.ID = ID;
            this.GroupID = GroupID;
            this.LibID = LibID;
            this.Symbol = Symbol;
            this.Code = Code;
            this.Total = Total;
        }

        public Location()
        {
        }
    }

    public class Removed_Item
    {
        public int ID { get; set; }
        public string CopyNumber { get; set; }
        public int ItemID { get; set; }
        public int LibID { get; set; }
        public int LocationID { get; set; }
        public int LoanTypeID { get; set; }
        public string Shelf { get; set; }
        public decimal Price { get; set; }
        public int Reason { get; set; }
        public DateTime? AcquiredDate { get; set; }
        public DateTime? RemovedDate { get; set; }
        public string Volume { get; set; }
        public int UseCount { get; set; }
        public int? PoID { get; set; }
        public DateTime? DateLastUsed { get; set; }
        public string CallNumber { get; set; }
        public int AcquiredSourceID { get; set; }
        public string LiquidCode { get; set; }
        public string Content { get; set; }
        public int REASON_ID { get; set; }
        public string Reson_detail { get; set; }

        public string REASON_DETAIL { get; set; }
        public string LibName { get; set; }
        public string LocName { get; set; }
    }



    public class Total_Amount
    {
        public int Total { get; set; }
    }


}
