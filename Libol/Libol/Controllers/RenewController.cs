using Libol.EntityResult;
using Libol.Models;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Web;
using System.Web.Mvc;

namespace Libol.Controllers
{
    public class RenewController : Controller
    {
        private LibolEntities db = new LibolEntities();
        RenewBusiness renewBusiness = new RenewBusiness();

        // GET: Renew
        public ActionResult Renew()
        {
            ViewBag.ContentRenew = new List<SP_CIR_GET_RENEW_Result>();
            return View();
        }

        [HttpPost]
        public ActionResult SearchToRenew(int intUserID, Byte intType, string strCodeVal)
        {
            ViewBag.ContentRenew = renewBusiness.SP_CIR_GET_RENEW(intUserID, intType, strCodeVal);
            return View();
        }
    }
}