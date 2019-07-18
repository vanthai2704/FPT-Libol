using Libol.EntityResult;
using Libol.Models;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Web;
using System.Web.Mvc;

namespace Libol.Controllers
{
    public class RenewController : BaseController
    {
        private LibolEntities db = new LibolEntities();
        RenewBusiness renewBusiness = new RenewBusiness();
        private static int UserID = 0;
        private static Byte Type = 0;
        private static string CodeVal = "";

        // GET: Renew
        public ActionResult Renew()
        {
            return View();
        }

        [HttpPost]
        public PartialViewResult SearchToRenew(int intUserID, Byte intType, string strCodeVal)
        {
            getcontentrenew(intUserID, intType, strCodeVal);
            UserID = intUserID;
            Type = intType;
            CodeVal = strCodeVal;
            return PartialView("_searchToRenew");
        }

        [HttpPost]
        public PartialViewResult Renew(int[] intLoanID, Byte intAddTime, Byte intTimeUnit, string strFixedDueDate,string[] duedates, int [] inttimes, int[] intrange)
        {
            for(int i = 0; i < intLoanID.Length; i++)
            {
                if(inttimes[i] >= intrange[i])
                {
                    int a = 1;
                }
                else if (Equals(strFixedDueDate,""))
                {

                }
                else if (DateTime.Compare(Convert.ToDateTime(strFixedDueDate), Convert.ToDateTime(duedates[i])) < 0) {
                    int b = 2;
                }
                else{
                    db.SP_RENEW_ITEM(intLoanID[i], intAddTime, intTimeUnit, strFixedDueDate);
                }
            }
            getcontentrenew(UserID,Type,CodeVal);
            return PartialView("_searchToRenew");
        }

        public void getcontentrenew(int intUserID, Byte intType, string strCodeVal)
        {
            List<SP_CIR_GET_RENEW_Result> results = renewBusiness.FPT_SP_CIR_GET_RENEW(intUserID, intType, strCodeVal);
            List<CustomRenew> customRenews = new List<CustomRenew>();
            foreach (SP_CIR_GET_RENEW_Result a in results)
            {
                customRenews.Add(new CustomRenew
                {
                    ID = a.ID,
                    DueDate = a.DueDate.ToString("yyyy-MM-dd"),
                    Content = gettitle(a.Content),
                    DateRange = a.CheckOutDate.ToString("dd/MM/yyyy") + "-" + a.DueDate.ToString("dd/MM/yyyy"),
                    FullName = a.FullName + "(" + a.Code + ")",
                    RenewCount = a.RenewCount.ToString(),
                    Renewals = a.Renewals.ToString(),
                    Note = (DateTime.Now - a.DueDate).Days > 0 ? (DateTime.Now - a.DueDate).Days.ToString() : ""
                });
            }
            ViewBag.ContentRenew = customRenews;
        }

        public string gettitle(string title)
        {
            string validate = title.Replace("$a", "");
            validate = validate.Replace("$b", "");
            validate = validate.Replace("$c", "");
            validate = validate.Replace("=$b", "");
            validate = validate.Replace(":$b", "");
            validate = validate.Replace("/$c", "");
            validate = validate.Replace(".$n", "");
            validate = validate.Replace(":$p", "");
            validate = validate.Replace(";$c", "");
            validate = validate.Replace("+$e", "");
            return validate;
        }


    }

    public class CustomRenew
    {
        public int ID { get; set; }
        public string DueDate { get; set; }
        public string Content { get; set; }
        public string DateRange { get; set; }
        public string FullName { get; set; }
        public string RenewCount { get; set; }
        public string Renewals { get; set; }
        public string Note { get; set; }
    }

}