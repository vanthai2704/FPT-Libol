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

        [AuthAttribute(ModuleID = 4, RightID = "125")]
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
        public JsonResult Liquidate(string Copynumber, string DKCB, string Liquidate, string DateLiquidate, int Reason)
        {
            string formatDKCB = DKCB.Replace('\n',',');
            ViewBag.Liquidate = db.SP_HOLDING_REMOVED_LIQUIDATE(Liquidate, DateLiquidate,Copynumber, formatDKCB, Reason, new ObjectParameter("intTotalItem", typeof(int)),
                new ObjectParameter("intOnLoan", typeof(int)),
                new ObjectParameter("intOnInventory", typeof(int))).ToList();
            return Json(ViewBag.Liquidate, JsonRequestBehavior.AllowGet);

        }
    }
}