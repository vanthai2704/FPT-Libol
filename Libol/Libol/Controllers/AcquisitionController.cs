using Libol.EntityResult;
using Libol.Models;
using Libol.SupportClass;
using System;
using System.Collections.Generic;
using System.Data.Entity.Core.Objects;
using System.Linq;
using System.Web;
using System.Web.Mvc;

namespace Libol.Controllers
{
    public class AcquisitionController : Controller
    {
        private LibolEntities db = new LibolEntities();
        ShelfBusiness shelfBusiness = new ShelfBusiness();

        [AuthAttribute(ModuleID = 4, RightID = "32")]
        public ActionResult HoldingLocRemove()
        {
            ViewBag.Library = shelfBusiness.FPT_SP_HOLDING_LIBRARY_SELECT(0, 1, -1, (int)Session["UserID"], 1);
            ViewData["ListReason"] = db.SP_HOLDING_REMOVE_REASON_SEL(0).ToList();
            return View();
        }

        [HttpPost]
        public JsonResult OnchangeLibrary(int LibID)
        {
            List<SP_HOLDING_LOCATION_GET_INFO_Result> list = shelfBusiness.FPT_SP_HOLDING_LOCATION_GET_INFO(LibID, (int)Session["UserID"], 0, -1);
            return Json(list, JsonRequestBehavior.AllowGet);
        }

        // Liquidate : thanh ly
        [HttpPost]
        public JsonResult Liquidate(string Copynumber, string DKCB, string Liquidate, string DateLiquidate, int Reason ,string selectfile)
        {
            int IDCN = -1;
            if (Copynumber != "" && Copynumber != null)
            {
                if (db.ITEMs.Where(a => a.Code == Copynumber).Count() == 0)
                {
                    ViewBag.Liquidate = "Mã tài liệu : " + Copynumber + " không tồn tại";
                }
                else
                {
                    IDCN = db.ITEMs.Where(a => a.Code == Copynumber).First().ID;
                    if (db.CIR_LOAN.Where(a => a.ItemID == IDCN).Count() != 0)
                    {
                        ViewBag.Liquidate = "Không thể Thanh Lý vì vẫn còn sách đang lưu thông";
                    }
                    else
                    {
                        string formatDKCB = "";
                        ViewBag.Liquidate = db.SP_HOLDING_REMOVED_LIQUIDATE(Liquidate, DateLiquidate, Copynumber, formatDKCB, Reason, new ObjectParameter("intTotalItem", typeof(int)),
                            new ObjectParameter("intOnLoan", typeof(int)),
                            new ObjectParameter("intOnInventory", typeof(int))).ToList();
                        ViewBag.Liquidate = "Thanh lý thành công";
                    }
                }
            }
            else
            {
                if (Copynumber == "" && DKCB== "")
                {
                    ViewBag.Liquidate = "Không thể thanh lý vì chưa nhập thông tin";
                }
                else
                {
                    string formatDKCB = DKCB.Replace('\n', ',');
                    formatDKCB = formatDKCB.Replace("\t", "");
                    ViewBag.Liquidate = db.SP_HOLDING_REMOVED_LIQUIDATE(Liquidate, DateLiquidate, Copynumber, formatDKCB, Reason, new ObjectParameter("intTotalItem", typeof(int)),
                        new ObjectParameter("intOnLoan", typeof(int)),
                        new ObjectParameter("intOnInventory", typeof(int))).ToList();
                    ViewBag.Liquidate = "Thanh lý thành công";
                }
                
            }
            
            return Json(ViewBag.Liquidate, JsonRequestBehavior.AllowGet);

        }

        [HttpPost]
        public JsonResult SearchItem(string title, string copynumber, string author, string publisher, string year, string isbn)
        {
            List<SP_GET_TITLES_Result> data = null;
            string message = shelfBusiness.SearchItem(title.Trim(), copynumber.Trim(), author.Trim(), publisher.Trim(), year.Trim(), isbn.Trim(), ref data);
            return Json(new { Message = message, data = data }, JsonRequestBehavior.AllowGet);
        }
    }
}