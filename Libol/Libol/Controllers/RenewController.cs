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
        private static Byte Type = 0;
        private static string CodeVal = "";

        // GET: Renew
        public ActionResult Renew()
        {
            return View();
        }

        [HttpPost]
        public PartialViewResult SearchToRenew(Byte intType, string strCodeVal)
        {
            getcontentrenew((int)Session["UserID"], intType, strCodeVal);
            Type = intType;
            CodeVal = strCodeVal;
            return PartialView("_searchToRenew");
        }

        [HttpPost]
        public PartialViewResult Renew(int[] intLoanID, Byte intAddTime, Byte intTimeUnit, string strFixedDueDate,string[] duedates, int [] inttimes, int[] intrange)
        {
            ViewBag.codeErrorCount = 0;
            for (int i = 0; i < intLoanID.Length; i++)
            {
                DateTime expiredDate = db.CIR_LOAN.Where(a => a.ID == intLoanID[i]).First().CIR_PATRON.ExpiredDate;
                if(inttimes[i] >= intrange[i])
                {
                    ViewBag.codeErrorCount = ViewBag.codeErrorCount + 1;
                    ViewBag.codeError = 1;
                    ViewBag.message = "số lượt gia hạn đã đạt mức tối đa";
                }
                else if (Equals(strFixedDueDate,""))
                {
                    ViewBag.codeErrorCount = ViewBag.codeErrorCount + 1;
                    ViewBag.codeError = 1;
                    ViewBag.message = "vui lòng chọn ngày ra hạn";
                }
                else if (DateTime.Compare(Convert.ToDateTime(strFixedDueDate), Convert.ToDateTime(duedates[i])) < 0) {
                    ViewBag.codeErrorCount = ViewBag.codeErrorCount + 1;
                    ViewBag.codeError = 1;
                    ViewBag.message = "ngày ra hạn sớm hơn hạn trả hiện tại";
                }
                else if (DateTime.Compare(expiredDate, Convert.ToDateTime(strFixedDueDate)) < 0)
                {
                    ViewBag.codeErrorCount = ViewBag.codeErrorCount + 1;
                    ViewBag.codeError = 1;
                    ViewBag.message = "ngày ra hạn muộn hơn ngày hết hạn thẻ";
                }
                else{
                    ViewBag.codeError = 0;
                    ViewBag.message = "gia hạn thành công";
                    db.SP_RENEW_ITEM(intLoanID[i], intAddTime, intTimeUnit, strFixedDueDate);
                }
            }
            getcontentrenew((int)Session["UserID"], Type,CodeVal);
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