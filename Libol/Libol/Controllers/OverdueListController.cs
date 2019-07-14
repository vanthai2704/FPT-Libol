using System;
using System.Collections.Generic;
using System.Linq;
using System.Web;
using System.Web.Mvc;
using Libol.EntityResult;
using Libol.Models;

namespace Libol.Controllers
{
    public class OverdueListController : Controller
    {
        private LibolEntities db = new LibolEntities();
        // GET: OverdueList
        public ActionResult OverdueList()
        {
            ViewBag.listLockPatron = GET_LIST_OVERDUELIST_GETINFOR(65, "3770", "").ToList();
            return View();
        }

        // trinhlv1
        public List<SP_CIR_OVERDUELIST_GETINFOR_Result> GET_LIST_OVERDUELIST_GETINFOR(Nullable<int> intUserID, string strPatronIDs, string whereCondition)
        {
            List<SP_CIR_OVERDUELIST_GETINFOR_Result> list = db.Database.SqlQuery<SP_CIR_OVERDUELIST_GETINFOR_Result>("SP_CIR_OVERDUELIST_GETINFOR {0}, {1}, {2}",
                new object[] { intUserID, strPatronIDs, whereCondition }).ToList();
            return list;
        }       
    }
}