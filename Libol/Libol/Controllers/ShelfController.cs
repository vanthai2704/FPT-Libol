using System;
using System.Collections.Generic;
using System.Linq;
using System.Web;
using System.Web.Mvc;
using Libol.EntityResult;
using Libol.Models;

namespace Libol.Controllers
{
    public class ShelfController : Controller
    {
        LibolEntities libol = new LibolEntities();
        ShelfBusiness shelfBusiness = new ShelfBusiness();
        // GET: Shelf
        public ActionResult Index()
        {

            //get list marc form
            ViewData["ListNBS"] = libol.ACQ_ACQUIRE_SOURCE.OrderBy(d => d.ID).ToList();
            //Cấp thư mục
            ViewData["listKTL"] = libol.CIR_LOAN_TYPE.ToList();
            ViewData["ListCurrency"] = libol.ACQ_CURRENCY.OrderBy(d => d.CurrencyCode).ToList();



            List<SP_HOLDING_LIBRARY_SELECT_Result> listLibsResult = shelfBusiness.FPT_SP_HOLDING_LIBRARY_SELECT(0, 1, -1, 49, 1);
            List<HOLDING_LIBRARY> libs = SP_HOLDING_LIBRARY_SELECT_Result.ConvertToHoldingLibrary(listLibsResult);
            //List<SP_HOLDING_LOCATION_GET_INFO_Result> listLocsResult = shelfBusiness.FPT_SP_HOLDING_LOCATION_GET_INFO(20, 49, 0, -1);
            //List<HOLDING_LOCATION> locs = SP_HOLDING_LOCATION_GET_INFO_Result.ConvertToHoldingLocation(listLocsResult);
            //ViewData["listLocs"] = locs;
            ViewData["listLibs"] = libs;

            //List<FPT_EDU_GET_SHELF_CONTENT_Result> listContentResult = libol.FPT_EDU_GET_SHELF_CONTENT("FPT070013581");
            //List<FPT_EDU_GET_SHELF_CONTENT_Result> listContentResult = getContentShelf();
            ViewBag.content = getContentShelf();
            

            return View();

        }

        // cho nay phai xu ly
        [HttpPost]
        public JsonResult SelectHolding(int libID)
        {
            List<SP_HOLDING_LOCATION_GET_INFO_Result> listLocsResult = shelfBusiness.FPT_SP_HOLDING_LOCATION_GET_INFO(libID, 49, 0, -1);
            List<HOLDING_LOCATION> locs = SP_HOLDING_LOCATION_GET_INFO_Result.ConvertToHoldingLocation(listLocsResult);
            ViewData["listLocs"] = locs;
            return Json(locs, JsonRequestBehavior.AllowGet);
        }
        public string getContentShelf()
        {
            string idMTL = Request.QueryString["Code"];
            List<FPT_EDU_GET_SHELF_CONTENT_Result> listContentResult = libol.FPT_EDU_GET_SHELF_CONTENT("FPT070013582").ToList();
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
                    field020 = ".-" + getcontent(item.Content);
                }
                if (fieldCode.Equals("022"))
                {
                    field022 = "=" + getcontent(item.Content);
                }
                if (fieldCode.Equals("100"))
                {
                    field100 = getcontent(item.Content);
                }
                if (fieldCode.Equals("110"))
                {
                    field110 = getcontent(item.Content);
                }
                if (fieldCode.Equals("245"))
                {
                    field245 = item.Content;
                    if (field245.Contains("$a"))
                    {
                        field245 = field245.Replace("$a",".-");
                    }
                    if (field245.Contains("=$b"))
                    {
                        field245 = field245.Replace("=$b", "=");
                    }
                    if (field245.Contains(":$b"))
                    {
                        field245 = field245.Replace(":$b", ":");
                    }
                    if (field245.Contains("/$c"))
                    {
                        field245 = field245.Replace("/$c", "/");
                    }
                    if (field245.Contains(".$n"))
                    {
                        field245 = field245.Replace(".$n", ".");
                    }
                    if (field245.Contains(":$p"))
                    {
                        field245 = field245.Replace(":$p", ":");
                    }
                }
                if (fieldCode.Equals("250"))
                {
                    field250 = ".-" + getcontent(item.Content);
                }
                if (fieldCode.Equals("260"))
                {
                    field260 = item.Content;
                    if (field260.Contains("$a"))
                    {
                        field260 = field260.Replace("$a", ".-");
                    }
                    if (field260.Contains(":$b"))
                    {
                        field260 = field260.Replace(":$b", ":");
                    }
                    if (field260.Contains("$c"))
                    {
                        field260 = field260.Replace("$c", "");
                    }
                }
                if (fieldCode.Equals("300"))
                {
                    field300 = item.Content;
                    if (field300.Contains("$a"))
                    {
                        field300 = field300.Replace("$a", ".-");
                    }
                    if (field300.Contains(":$b"))
                    {
                        field300 = field300.Replace(":$b", ":");
                    }
                    if (field300.Contains("$c"))
                    {
                        field300 = field300.Replace("$c", "");
                    }
                    if (field300.Contains("$e"))
                    {
                        field300 = field300.Replace("$e", "");
                    }
                }
                if (fieldCode.Equals("490"))
                {
                    field490 = ".-" + getcontent(item.Content);
                }
                if (fieldCode.Equals("520"))
                {
                    field520 = getcontent(item.Content);
                }
                contentOutput = field020 + field022 + field100 + field110 + field245 + field250 + field260 + field300 + field490 + "\n\t" + field520;
            }
            return contentOutput;
        }

       

        public string getcontent(string copynumber)
        {
            string validate = copynumber.Replace("$a", "");
            validate = validate.Replace("$b", "");
            validate = validate.Replace("$c", "");
            validate = validate.Replace(",$c ", "");
            validate = validate.Replace("=$b", "");
            validate = validate.Replace(":$b", "");
            validate = validate.Replace("/$c", "");
            validate = validate.Replace(".$n", "");
            validate = validate.Replace(":$p", "");
            validate = validate.Replace(";$c", "");
            validate = validate.Replace("+$e", "");
            validate = validate.Replace("$e", "");

            return validate;
        }

    }
}
