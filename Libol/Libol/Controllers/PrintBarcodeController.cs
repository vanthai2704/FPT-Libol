using Libol.EntityResult;
using Libol.Models;
using Libol.SupportClass;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Web;
using System.Web.Mvc;

namespace Libol.Controllers
{
    public class PrintBarcodeController : Controller
    {
        private LibolEntities db = new LibolEntities();
        ShelfBusiness shelfBusiness = new ShelfBusiness();

        [AuthAttribute(ModuleID = 4, RightID = "103")]
        public ActionResult Index()
        {
            ViewBag.Library = shelfBusiness.FPT_SP_HOLDING_LIBRARY_SELECT(0, 1, -1, (int)Session["UserID"], 1);
            ViewBag.Template = db.SP_SYS_GET_TEMPLATE(0, 79).ToList();
            return View();
        }

        [HttpPost]
        [AuthAttribute(ModuleID = 4, RightID = "103")]
        public JsonResult OnchangeLibrary(int LibID)
        {
            List<SP_HOLDING_LOCATION_GET_INFO_Result> list = shelfBusiness.FPT_SP_HOLDING_LOCATION_GET_INFO(LibID, (int)Session["UserID"], 0, -1);
            return Json(list, JsonRequestBehavior.AllowGet);
        }

        
    }
}