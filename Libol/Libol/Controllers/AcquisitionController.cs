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
    public class AcquisitionController : Controller
    {
        private LibolEntities db = new LibolEntities();
        ShelfBusiness shelfBusiness = new ShelfBusiness();

        [AuthAttribute(ModuleID = 4, RightID = "125")]
        public ActionResult HoldingLocRemove()
        {
            ViewBag.Library = shelfBusiness.FPT_SP_HOLDING_LIBRARY_SELECT(0, 1, -1, (int)Session["UserID"], 1);
            return View();
        }

        [HttpPost]
        public JsonResult OnchangeLibrary(int LibID)
        {
            List<SP_HOLDING_LOCATION_GET_INFO_Result> list = shelfBusiness.FPT_SP_HOLDING_LOCATION_GET_INFO(LibID, 43, 0, -1);
            return Json(list, JsonRequestBehavior.AllowGet);
        }
    }
}